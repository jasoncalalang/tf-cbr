# Two-Phase Deployment Guide

This guide explains how to deploy the IBM Cloud VPC infrastructure with Context-Based Restrictions (CBR) using a two-phase approach.

## Overview

The infrastructure has been reorganized into two distinct phases:

- **Phase 1**: VPC Infrastructure (Networking Foundation)
- **Phase 2**: CBR and Test VSI (Security and Testing Layer)

## Phase Separation Benefits

1. **Risk Reduction**: Deploy and verify networking before adding security restrictions
2. **Independent Testing**: Test VPC connectivity before CBR rules are applied
3. **Easier Rollback**: Remove CBR/test components without affecting VPC infrastructure
4. **Clear Dependencies**: Phase 2 explicitly depends on Phase 1 via terraform_remote_state
5. **Modular Deployment**: Deploy phases separately or together as needed

## Directory Structure

```
tf-cbr/
├── phase1/                    # VPC Infrastructure Only
│   ├── terraform.tf
│   ├── variables.tf
│   ├── main.tf
│   ├── outputs.tf
│   └── terraform.tfvars
├── phase2/                    # CBR and Test VSI
│   ├── terraform.tf
│   ├── variables.tf
│   ├── data.tf               # Phase 1 state reference
│   ├── cbr.tf
│   ├── compute.tf
│   ├── outputs.tf
│   ├── user_data.sh
│   └── terraform.tfvars
└── README-TWO-PHASE-DEPLOYMENT.md
```

## Prerequisites

1. **IBM Cloud API Key**: Valid API key with VPC and CBR permissions
2. **SSH Key**: Pre-existing SSH key in IBM Cloud for VSI access
3. **Terraform**: Version >= 1.0 installed
4. **IBM Cloud Provider**: Version ~> 1.60.0 (automatically installed)

## Phase 1: VPC Infrastructure

### Phase 1 Components

- VPC with manual address prefix management
- 3 subnets across 3 availability zones (jp-tok-1, jp-tok-2, jp-tok-3)
- 2 public gateways (jp-tok-2, jp-tok-3)
- 5 security groups (default + 4 custom)
- Address prefixes for each zone
- Security group rules

### Phase 1 Deployment

1. **Navigate to Phase 1 directory:**
   ```bash
   cd phase1/
   ```

2. **Review and update terraform.tfvars:**
   ```bash
   # Update with your values
   ibmcloud_api_key = "your-api-key-here"
   vpc_name = "your-vpc-name"
   region = "jp-tok"
   # ... other variables
   ```

3. **Initialize Terraform:**
   ```bash
   terraform init
   ```

4. **Validate configuration:**
   ```bash
   terraform validate
   terraform fmt
   ```

5. **Review the deployment plan:**
   ```bash
   terraform plan -var-file=terraform.tfvars
   ```

6. **Deploy Phase 1:**
   ```bash
   terraform apply -var-file=terraform.tfvars
   ```

7. **Verify Phase 1 outputs:**
   ```bash
   terraform output
   ```

### Phase 1 Validation

After Phase 1 deployment, verify:
- VPC is created and active
- All 3 subnets are provisioned
- Public gateways are attached to correct subnets
- Security groups are created with proper rules
- Address prefixes are configured correctly

## Phase 2: CBR and Test VSI

### Phase 2 Components

- 3 CBR network zones (corporate, VPC internal, admin)
- 3 CBR rules (SSH, web access, admin operations)
- Ubuntu 24.04 test VSI with nginx
- CBR test security group
- Floating IP for test VSI

### Phase 2 Deployment

1. **Ensure Phase 1 is deployed successfully**

2. **Navigate to Phase 2 directory:**
   ```bash
   cd ../phase2/
   ```

3. **Review and update terraform.tfvars:**
   ```bash
   # Must match Phase 1 values
   ibmcloud_api_key = "same-api-key-as-phase1"
   region = "jp-tok"  # Must match Phase 1
   
   # Phase 1 state reference
   phase1_local_state_path = "../phase1/terraform.tfstate"
   
   # CBR configuration
   cbr_enforcement_mode = "report"  # Start with report mode
   admin_ip_ranges = ["your.admin.ip.range/24"]
   corporate_network_ranges = ["your.corp.ip.range/24"]
   
   # Test VSI configuration
   ssh_key_name = "your-ssh-key-name"
   ```

4. **Initialize Terraform:**
   ```bash
   terraform init
   ```

5. **Validate configuration:**
   ```bash
   terraform validate
   terraform fmt
   ```

6. **Review the deployment plan:**
   ```bash
   terraform plan -var-file=terraform.tfvars
   ```
   
   Verify that Phase 1 resources are referenced correctly via remote state.

7. **Deploy Phase 2:**
   ```bash
   terraform apply -var-file=terraform.tfvars
   ```

8. **Verify Phase 2 outputs:**
   ```bash
   terraform output
   ```

### Phase 2 Validation

After Phase 2 deployment, verify:
- CBR zones are created with correct IP ranges
- CBR rules are active (check enforcement mode)
- Test VSI is running and accessible
- Floating IP is assigned to test VSI
- Nginx is serving test page

## Testing and Validation

### Phase 1 Testing

```bash
# From phase1/ directory
terraform output vpc_id
terraform output subnet_ids
terraform output security_group_ids
terraform output phase1_summary
```

### Phase 2 Testing

```bash
# From phase2/ directory
terraform output test_vsi_details
terraform output cbr_network_zone_ids
terraform output complete_infrastructure_summary

# Test VSI connectivity
TEST_IP=$(terraform output -raw test_vsi_details | jq -r '.floating_ip')
curl http://$TEST_IP  # Should show nginx test page
ssh ubuntu@$TEST_IP   # Should allow SSH (if from allowed IP ranges)
```

### CBR Validation

1. **Check CBR enforcement mode** (should start as "report"):
   ```bash
   terraform output cbr_rule_details
   ```

2. **Test access from allowed IPs** - should work
3. **Test access from blocked IPs** - should be logged but not blocked (report mode)
4. **Switch to enforcement mode** when ready:
   ```bash
   # Update terraform.tfvars
   cbr_enforcement_mode = "enabled"
   terraform apply -var-file=terraform.tfvars
   ```

## Rollback Procedures

### Rolling Back Phase 2

```bash
cd phase2/
terraform destroy -var-file=terraform.tfvars
```

This removes CBR rules, test VSI, and associated resources while preserving Phase 1 VPC infrastructure.

### Rolling Back Both Phases

```bash
# First destroy Phase 2
cd phase2/
terraform destroy -var-file=terraform.tfvars

# Then destroy Phase 1
cd ../phase1/
terraform destroy -var-file=terraform.tfvars
```

## State Management Options

### Local State (Default)

Phase 2 references Phase 1 local state file:
```hcl
data "terraform_remote_state" "phase1" {
  backend = "local"
  config = {
    path = "../phase1/terraform.tfstate"
  }
}
```

### Remote State (Recommended for Production)

For production deployments, use remote state storage:

1. **Configure S3 backend in Phase 1:**
   ```hcl
   terraform {
     backend "s3" {
       bucket = "your-terraform-state-bucket"
       key    = "phase1/terraform.tfstate"
       region = "us-south"
     }
   }
   ```

2. **Update Phase 2 to reference remote state:**
   ```hcl
   data "terraform_remote_state" "phase1" {
     backend = "s3"
     config = {
       bucket = "your-terraform-state-bucket"
       key    = "phase1/terraform.tfstate"
       region = "us-south"
     }
   }
   ```

3. **Update Phase 2 terraform.tfvars:**
   ```bash
   phase1_state_bucket = "your-terraform-state-bucket"
   phase1_state_key = "phase1/terraform.tfstate"
   phase1_state_region = "us-south"
   ```

## Troubleshooting

### Common Issues

1. **Phase 2 can't find Phase 1 state:**
   - Verify `phase1_local_state_path` in Phase 2 terraform.tfvars
   - Ensure Phase 1 was successfully applied

2. **CBR rules not working:**
   - Check enforcement mode (start with "report")
   - Verify IP ranges in CBR zones
   - Check IBM Cloud console for CBR rule status

3. **Test VSI not accessible:**
   - Verify floating IP assignment
   - Check security group rules
   - Ensure SSH key exists in IBM Cloud

4. **Resource dependencies:**
   - Phase 2 must be destroyed before Phase 1
   - CBR rules depend on VPC CRN from Phase 1

### Debug Commands

```bash
# Check Terraform version and providers
terraform version

# Validate configurations
terraform validate

# Show current state
terraform show

# Refresh state
terraform refresh

# View specific outputs
terraform output -json | jq '.'
```

## Security Considerations

1. **CBR Enforcement Mode:**
   - Always start with "report" mode
   - Monitor logs before switching to "enabled"
   - Test access from all required IP ranges

2. **API Key Security:**
   - Use environment variables: `export TF_VAR_ibmcloud_api_key="your-key"`
   - Never commit terraform.tfvars to version control
   - Use IBM Cloud Secrets Manager for production

3. **Network Security:**
   - Review security group rules regularly
   - Minimize open ports and IP ranges
   - Use corporate VPN for administrative access

4. **State File Security:**
   - Use encrypted remote state storage
   - Restrict access to state files
   - Enable state file versioning

## Next Steps

1. **Production Deployment:**
   - Use remote state storage
   - Implement state file backup
   - Set up monitoring and alerting

2. **Enhanced Security:**
   - Switch CBR rules to enforcement mode
   - Implement additional security groups
   - Add network monitoring

3. **Infrastructure Expansion:**
   - Add more VSIs using Phase 1 outputs
   - Implement load balancers
   - Add database services

## Support and Documentation

- [IBM Cloud Terraform Provider Documentation](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs)
- [IBM Cloud VPC Documentation](https://cloud.ibm.com/docs/vpc)
- [Context-Based Restrictions Documentation](https://cloud.ibm.com/docs/account?topic=account-context-restrictions-whatis)
- [Terraform Best Practices](https://developer.hashicorp.com/terraform/language)

---

For questions or issues with this deployment guide, please refer to the IBM Cloud documentation or contact your infrastructure team.