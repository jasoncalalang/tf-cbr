# Company VPC Replica with Context-Based Restrictions (CBR)

This Terraform project recreates the `company-vpc` VPC infrastructure in IBM Cloud with enhanced security through Context-Based Restrictions (CBR). The project uses a two-phase deployment architecture for better risk management and modular deployments.

## 📋 Two-Phase Architecture Overview

This project deploys infrastructure in two distinct phases for better risk management and modularity:

### Phase 1: VPC Infrastructure Foundation
- **1 VPC** (`company-vpc`) in the `jp-tok` region
- **3 Address Prefixes** across three availability zones
- **3 Subnets** with appropriate CIDR blocks and zone distribution
- **2 Public Gateways** in zones jp-tok-2 and jp-tok-3
- **5 Security Groups** with exact rule replicas from original environment
- **Network ACL** and **Routing Table** (uses defaults with allow-all rules)

### Phase 2: Security and Testing Layer
- **3 Context-Based Restriction (CBR) Network Zones** for access control
- **3 CBR Rules** for SSH, web access, and admin operations
- **1 Ubuntu 24.04 Test VSI** with nginx for connectivity validation
- **Floating IP** for external access to test VSI
- **CBR Test Security Group** for test VSI isolation

### Original vs Replica Mapping

| Component | Original | Replica |
|-----------|----------|---------|
| VPC Name | `company-vpc` | `company-vpc` |
| Region | `jp-tok` | `jp-tok` (same) |
| Subnets | `sn-20250218-01/02/03` | `sn-20250218-01/02/03` (same names) |
| Public Gateways | `test-gw`, `gw3` | `test-gw`, `gw3` (same names) |
| Security Groups | 5 groups with exact rules | 5 groups with exact rules |

## 🗂️ Project Structure

```
tf-cbr/
├── README.md                          # This main documentation file
├── README-TWO-PHASE-DEPLOYMENT.md    # Detailed two-phase deployment guide
├── DEPLOYMENT-SUMMARY.md              # Quick deployment reference
├── deploy.sh                          # Automated deployment script
├── phase1/                            # Phase 1: VPC Infrastructure
│   ├── terraform.tf                   # Provider configuration
│   ├── variables.tf                   # Input variables
│   ├── main.tf                       # VPC infrastructure resources
│   ├── outputs.tf                    # Phase 1 outputs
│   └── terraform.tfvars              # Phase 1 configuration values
├── phase2/                           # Phase 2: CBR and Test VSI
│   ├── terraform.tf                   # Provider configuration
│   ├── variables.tf                   # Input variables
│   ├── data.tf                       # Phase 1 state reference
│   ├── cbr.tf                        # Context-Based Restriction resources
│   ├── compute.tf                    # Test VSI resources
│   ├── outputs.tf                    # Phase 2 outputs
│   ├── user_data.sh                  # VSI initialization script
│   └── terraform.tfvars              # Phase 2 configuration values
├── terraform.tf                      # Legacy single-phase provider config
├── main.tf                           # Legacy single-phase resources
├── outputs.tf                        # Legacy single-phase outputs
├── variables.tf                      # Legacy single-phase variables
└── terraform.tfvars.example          # Example configuration values
```

## 🚀 Quick Start

### Prerequisites

1. **IBM Cloud CLI** installed and configured
2. **Terraform** >= 1.0 installed
3. **IBM Cloud API Key** with appropriate permissions
4. **SSH Key** created in IBM Cloud for VSI access (Phase 2)
5. **Resource Group** access (Default resource group is used by default)

### Required IBM Cloud Permissions

Your API key needs the following IAM permissions:
- **VPC Infrastructure Services**: Administrator
- **Context-Based Restrictions**: Administrator
- **Resource Group**: Viewer (minimum)

### Benefits of Two-Phase Deployment

1. **Risk Reduction**: Deploy and verify networking before adding security restrictions
2. **Independent Testing**: Test VPC connectivity before CBR rules are applied
3. **Easier Rollback**: Remove CBR/test components without affecting VPC infrastructure
4. **Clear Dependencies**: Phase 2 explicitly depends on Phase 1 via terraform_remote_state
5. **Modular Deployment**: Deploy phases separately or together as needed

### Deployment Options

#### Option 1: Automated Deployment (Recommended)
```bash
# Deploy both phases automatically
./deploy.sh both

# Deploy phases separately
./deploy.sh phase1      # Deploy VPC infrastructure first
./deploy.sh phase2      # Deploy CBR and test VSI

# Check deployment status
./deploy.sh status

# Validate configurations without deploying
./deploy.sh validate
```

#### Option 2: Manual Two-Phase Deployment
```bash
# Phase 1: VPC Infrastructure
cd phase1/
cp terraform.tfvars.example terraform.tfvars  # Configure your values
terraform init
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars

# Phase 2: CBR and Test VSI (after Phase 1 completes)
cd ../phase2/
cp terraform.tfvars.example terraform.tfvars  # Configure your values
terraform init
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

#### Option 3: Legacy Single-Phase Deployment
```bash
# For backward compatibility (root directory)
terraform init
terraform plan
terraform apply
```

### Quick Validation

After deployment, verify your infrastructure:

```bash
# Check Phase 1 deployment
cd phase1/ && terraform output phase1_summary

# Check Phase 2 deployment
cd phase2/ && terraform output test_vsi_details

# Test VSI connectivity
TEST_IP=$(cd phase2/ && terraform output -raw test_vsi_details | jq -r '.floating_ip')
curl http://$TEST_IP  # Should show nginx test page
```

## 🔧 Configuration Details

### VPC Configuration
- **Name**: `company-vpc` (configurable via `vpc_name` variable)
- **Region**: `jp-tok` (Tokyo)
- **Classic Access**: Disabled (matches original)
- **DNS**: System resolver with private DNS servers

### Network Layout

#### Address Prefixes
| Zone | CIDR Block | Purpose |
|------|------------|---------|
| jp-tok-1 | 10.244.0.0/18 | Subnet pool for zone 1 |
| jp-tok-2 | 10.244.64.0/18 | Subnet pool for zone 2 |
| jp-tok-3 | 10.244.128.0/18 | Subnet pool for zone 3 |

#### Subnets
| Name | Zone | CIDR | Public Gateway |
|------|------|------|----------------|
| sn-20250218-01 | jp-tok-1 | 10.244.0.0/24 | ❌ None |
| sn-20250218-02 | jp-tok-2 | 10.244.64.0/24 | ✅ test-gw |
| sn-20250218-03 | jp-tok-3 | 10.244.128.0/24 | ✅ gw3 |

#### Public Gateways
| Name | Zone | Purpose |
|------|------|---------|
| test-gw | jp-tok-2 | Internet access for subnet-2 |
| gw3 | jp-tok-3 | Internet access for subnet-3 |

### Security Groups

#### 1. Default Security Group (Auto-created)
- **Outbound**: Allow all traffic to 0.0.0.0/0
- **Inbound**: Allow all traffic from same security group

#### 2. hlf-sg
- **Inbound**: Allow all protocols from `136.158.43.87`
- **Outbound**: Allow TCP ports 1-65535 to 0.0.0.0/0

#### 3. jason-cs-sg  
- **Inbound**: Allow all protocols from multiple IPs:
  - 136.158.43.48
  - 120.29.79.239
  - 136.158.43.207
  - 112.200.9.106
  - 112.200.7.97

#### 4. jason-ws
- **Inbound**: Allow all protocols from `136.158.43.48`

#### 5. kube-vpegw-[vpc-id]
- **Rules**: None (empty by design, managed by IBM Cloud Kubernetes Service)

### Network ACL & Routing
- Uses **default Network ACL** with allow-all rules (inbound and outbound)
- Uses **default Routing Table** with automatic route management

### Context-Based Restrictions (CBR) - Phase 2

#### CBR Network Zones
| Zone Name | Purpose | IP Ranges |
|-----------|---------|-----------|
| corporate-network | Corporate office access | Configurable in terraform.tfvars |
| vpc-internal-zone | VPC internal subnet access | VPC subnet CIDR blocks |
| admin-zone | Administrative access | Configurable admin IP ranges |

#### CBR Rules
| Rule Name | Enforcement | Context | Resources |
|-----------|-------------|---------|-----------|
| ssh-access-rule | Configurable | Corporate + Admin zones | VPC CRN |
| web-access-rule | Configurable | All defined zones | VPC CRN |
| admin-operations-rule | Configurable | Admin zone only | VPC CRN |

**Important**: CBR rules start in **"report"** mode by default. Switch to **"enabled"** mode after testing to enforce restrictions.

### Test VSI - Phase 2
- **OS**: Ubuntu 24.04 LTS
- **Instance Profile**: cx2-2x4 (2 vCPU, 4 GB RAM)
- **Services**: nginx web server for connectivity testing
- **Access**: Via floating IP and SSH key
- **Security Group**: Custom CBR test security group with HTTP/SSH access

## 🔄 Configuration

### Phase 1 Variables (phase1/terraform.tfvars)

Key variables for VPC infrastructure:

```hcl
# Basic Configuration
ibmcloud_api_key = "your-api-key-here"
region          = "jp-tok"
vpc_name        = "company-vpc"
resource_group_id = "default"

# Network Configuration  
address_prefixes = {
  "jp-tok-1" = "10.244.0.0/18"
  "jp-tok-2" = "10.244.64.0/18"
  "jp-tok-3" = "10.244.128.0/18"
}

# Security Group Configuration
hlf_sg_allowed_ip = "136.158.43.87"
jason_cs_sg_allowed_ips = ["136.158.43.48", "120.29.79.239"]
jason_ws_allowed_ip = "136.158.43.48"
```

### Phase 2 Variables (phase2/terraform.tfvars)

Key variables for CBR and test VSI:

```hcl
# Basic Configuration (must match Phase 1)
ibmcloud_api_key = "same-api-key-as-phase1"
region = "jp-tok"

# Phase 1 State Reference
phase1_local_state_path = "../phase1/terraform.tfstate"

# CBR Configuration
cbr_enforcement_mode = "report"  # Start with report mode
admin_ip_ranges = ["203.0.113.0/24", "198.51.100.0/24"]
corporate_network_ranges = ["192.0.2.0/24", "10.0.0.0/8"]

# Test VSI Configuration
ssh_key_name = "your-ssh-key-name"
test_vsi_name = "cbr-test-vsi"
test_vsi_profile = "cx2-2x4"
```

### Adding Resources

#### Phase 1 Extensions (VPC Infrastructure)
1. Add new VPC resources to `phase1/main.tf`
2. Add corresponding variables to `phase1/variables.tf`  
3. Add outputs to `phase1/outputs.tf`
4. Update `phase1/terraform.tfvars` with new values

#### Phase 2 Extensions (Security and Testing)
1. Add new CBR resources to `phase2/cbr.tf`
2. Add new compute resources to `phase2/compute.tf`
3. Add corresponding variables to `phase2/variables.tf`
4. Add outputs to `phase2/outputs.tf`
5. Update `phase2/terraform.tfvars` with new values

#### Key Design Principles
- **Separation of Concerns**: Keep VPC infrastructure (Phase 1) separate from security policies (Phase 2)
- **State Dependencies**: Phase 2 references Phase 1 outputs via terraform_remote_state
- **Idempotency**: Both phases can be redeployed independently
- **Rollback Safety**: Phase 2 can be destroyed without affecting Phase 1 infrastructure

## 📊 Outputs and Monitoring

### Phase 1 Outputs (VPC Infrastructure)
```bash
cd phase1/

# Get Phase 1 summary
terraform output phase1_summary

# Get specific resource IDs
terraform output vpc_id
terraform output subnet_ids
terraform output security_group_ids

# Get detailed information
terraform output subnet_details
terraform output public_gateway_details
```

### Phase 2 Outputs (CBR and Test VSI)
```bash
cd phase2/

# Get complete infrastructure summary
terraform output complete_infrastructure_summary

# Get test VSI information
terraform output test_vsi_details

# Get CBR configuration
terraform output cbr_network_zone_ids
terraform output cbr_rule_details
```

### Combined Infrastructure Status
```bash
# Use the deployment script to get overall status
./deploy.sh status

# Get complete deployment summary
cat DEPLOYMENT-SUMMARY.md
```

### CBR Monitoring and Testing

```bash
# Test VSI accessibility
TEST_IP=$(cd phase2/ && terraform output -raw test_vsi_details | jq -r '.floating_ip')
curl http://$TEST_IP  # Test web connectivity
ssh ubuntu@$TEST_IP   # Test SSH access (from allowed IPs)

# Check CBR rule enforcement
# In IBM Cloud console, go to Manage > Context-based restrictions
# Or use IBM Cloud CLI:
ibmcloud cbr rules --output json
```

## 🔒 Security Best Practices

### API Key Security
- **Environment Variables**: Use `export TF_VAR_ibmcloud_api_key="your-key"` instead of hardcoding
- **Least Privilege**: Use IAM policies with minimal required permissions
- **Regular Rotation**: Rotate API keys every 90 days
- **Secrets Management**: Consider IBM Cloud Secrets Manager for production

### Context-Based Restrictions (CBR)
- **Start with Report Mode**: Always deploy CBR rules in "report" mode first
- **Monitor CBR Events**: Use IBM Cloud Activity Tracker to monitor access attempts
- **Test All Access Patterns**: Verify access from all required IP ranges before enforcement
- **Gradual Enforcement**: Switch to "enabled" mode only after thorough testing

### Network Security
- **IP Allowlisting**: Review and update allowed IP ranges in both security groups and CBR zones
- **Minimal Access**: Use specific IP ranges instead of 0.0.0.0/0 where possible
- **Regular Audits**: Review network access patterns monthly
- **Logging**: Enable VPC flow logs for traffic analysis

### Infrastructure Security
- **State File Protection**: Use encrypted remote state storage for production
- **Resource Tagging**: Implement consistent tagging for resource tracking
- **Backup Strategy**: Regular backups of state files and configurations
- **Access Control**: Restrict access to Terraform state and configuration files

### Production Deployment Security
- **Remote State**: Use IBM Cloud Object Storage for Terraform state
- **State Locking**: Implement state locking to prevent concurrent modifications
- **CI/CD Pipeline**: Use automated deployments with proper approvals
- **Environment Separation**: Separate dev/test/prod environments completely

## 🧹 Cleanup and Rollback

### Automated Cleanup (Recommended)
```bash
# Destroy both phases (Phase 2 first, then Phase 1)
./deploy.sh destroy-both

# Destroy only Phase 2 (keep VPC infrastructure)
./deploy.sh destroy-phase2
```

### Manual Cleanup
```bash
# Phase 2: Remove CBR and Test VSI (destroy first due to dependencies)
cd phase2/
terraform destroy -var-file=terraform.tfvars

# Phase 1: Remove VPC Infrastructure (only after Phase 2 is destroyed)
cd ../phase1/
terraform destroy -var-file=terraform.tfvars
```

### Partial Rollback Scenarios

#### Rollback CBR to Report Mode
```bash
cd phase2/
# Edit terraform.tfvars: set cbr_enforcement_mode = "report"
terraform apply -var-file=terraform.tfvars
```

#### Remove Only Test VSI (Keep CBR Rules)
```bash
cd phase2/
# Comment out VSI resources in compute.tf
terraform apply -var-file=terraform.tfvars
```

### Cleanup Verification
```bash
# Verify all resources are destroyed
./deploy.sh status

# Check IBM Cloud console to confirm resource deletion
# Verify no remaining charges in billing dashboard
```

**Warning**: Destruction is permanent and cannot be undone. Ensure you have backups of any important data and configurations.

## 🚨 Troubleshooting

### Common Issues

#### Authentication and Permissions
1. **Authentication Errors**
   ```
   Error: Unable to authenticate to IBM Cloud
   ```
   **Solutions:**
   - Verify API key is correct and has required permissions
   - Check API key hasn't expired
   - Use `ibmcloud iam api-keys` to verify key exists

2. **Permission Issues**
   ```
   Error: Insufficient permissions
   ```
   **Solutions:**
   - Verify IAM permissions for VPC Infrastructure Services (Administrator)
   - Verify IAM permissions for Context-Based Restrictions (Administrator)
   - Check resource group access (Viewer minimum)
   - Use `ibmcloud iam user-policies <user-email>` to verify permissions

#### Phase-Specific Issues
3. **Phase 2 Can't Find Phase 1 State**
   ```
   Error: Error reading terraform_remote_state
   ```
   **Solutions:**
   - Verify Phase 1 was successfully deployed: `cd phase1/ && terraform show`
   - Check `phase1_local_state_path` in Phase 2 terraform.tfvars
   - Ensure Phase 1 state file exists: `ls -la phase1/terraform.tfstate`

4. **CBR Rule Failures**
   ```
   Error: Failed to create CBR rule
   ```
   **Solutions:**
   - Verify VPC CRN is available from Phase 1 outputs
   - Check IP ranges in CBR network zones are valid CIDR blocks
   - Ensure enforcement mode is set to "report" or "enabled"
   - Verify CBR service is available in your region

#### Infrastructure Issues
5. **Resource Naming Conflicts**
   ```
   Error: Resource already exists
   ```
   **Solutions:**
   - Change `vpc_name` variable to a unique value
   - Check for existing resources in the target region
   - Use `ibmcloud is vpcs` to list existing VPCs

6. **IP Address Range Conflicts**
   ```
   Error: CIDR block overlaps
   ```
   **Solutions:**
   - Ensure CIDR blocks don't overlap with existing VPCs
   - Modify `address_prefixes` in Phase 1 terraform.tfvars
   - Use `ibmcloud is subnets` to check existing subnets

7. **SSH Key Not Found**
   ```
   Error: SSH key not found
   ```
   **Solutions:**
   - Create SSH key in IBM Cloud: `ibmcloud is key-create`
   - Verify key name in Phase 2 terraform.tfvars matches exactly
   - Use `ibmcloud is keys` to list available keys

8. **Test VSI Deployment Issues**
   ```
   Error: VSI creation failed
   ```
   **Solutions:**
   - Check subnet availability and capacity
   - Verify instance profile is available: `ibmcloud is instance-profiles`
   - Ensure floating IP quota is not exceeded
   - Check security group rules allow necessary traffic

### Debug Commands

```bash
# Validate Terraform configurations
cd phase1/ && terraform validate
cd phase2/ && terraform validate

# Check Terraform and provider versions
terraform version

# Show current state
terraform show

# Refresh state and check for drift
terraform refresh -var-file=terraform.tfvars

# Debug Phase 2 state reference
cd phase2/
terraform console  # Then type: data.terraform_remote_state.phase1.outputs

# Test CBR enforcement
ibmcloud cbr rules
ibmcloud cbr zones
```

### Getting Help

- **IBM Cloud Terraform Provider**: [Registry Documentation](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs)
- **IBM Cloud VPC**: [Service Documentation](https://cloud.ibm.com/docs/vpc)
- **Context-Based Restrictions**: [CBR Documentation](https://cloud.ibm.com/docs/account?topic=account-context-restrictions-whatis)
- **Deployment Guides**: See `README-TWO-PHASE-DEPLOYMENT.md` for detailed instructions
- **Quick Reference**: See `DEPLOYMENT-SUMMARY.md` for quick commands
- **Terraform Best Practices**: [HashiCorp Documentation](https://developer.hashicorp.com/terraform/language)

## 📝 Version Information and Documentation

### Software Requirements
- **Terraform**: >= 1.0
- **IBM Cloud Provider**: ~> 1.60.0
- **IBM Cloud CLI**: Latest version (for manual operations)
- **jq**: For JSON output processing (optional but recommended)

### Project Information
- **Original VPC Created**: 2025-02-18
- **Configuration Version**: 2.0 (Two-Phase Architecture)
- **Last Updated**: 2025-08-10
- **Architecture**: Two-phase deployment with CBR integration

### Additional Documentation
- **`README-TWO-PHASE-DEPLOYMENT.md`**: Comprehensive deployment guide with detailed steps
- **`DEPLOYMENT-SUMMARY.md`**: Quick reference and deployment commands
- **`deploy.sh`**: Automated deployment script with validation and error handling

## 🤝 Contributing Guidelines

### Before Making Changes
1. **Understand the Architecture**: Review both phases and their dependencies
2. **Test Changes**: Always test in a development environment first
3. **State Management**: Be cautious when modifying resources that affect Terraform state
4. **Security Impact**: Consider security implications of any infrastructure changes

### Development Workflow
1. **Create Feature Branch**: `git checkout -b feature/your-feature`
2. **Make Changes**: Follow existing code patterns and naming conventions
3. **Validate**: Run `./deploy.sh validate` to check configurations
4. **Test Deploy**: Test deployment in development environment
5. **Update Documentation**: Update README files if needed
6. **Submit Changes**: Create pull request with detailed description

### Code Standards
- **Terraform Format**: Always run `terraform fmt` before committing
- **Variable Naming**: Use descriptive names with consistent patterns
- **Comments**: Add comments for complex resource configurations
- **Outputs**: Provide meaningful outputs for resource consumption

---

## ⚠️ Important Security Notice

**This configuration replicates the exact specifications of the original `company-vpc` VPC with added CBR security controls.**

### Pre-Production Checklist
- [ ] Review and update all IP allowlists in security groups
- [ ] Configure appropriate IP ranges for CBR network zones
- [ ] Start CBR enforcement in "report" mode
- [ ] Test all access patterns before switching to "enabled" mode
- [ ] Implement proper API key rotation and management
- [ ] Set up monitoring and alerting for security events
- [ ] Review and approve all resource configurations

### Production Deployment
- Use remote state storage (IBM Cloud Object Storage recommended)
- Implement proper backup and disaster recovery procedures
- Set up comprehensive monitoring and logging
- Follow security best practices and corporate policies
- Maintain detailed change logs and documentation

**For questions or issues with this deployment, please refer to the comprehensive documentation files or contact your infrastructure team.**