# Quick Deployment Summary

## Two-Phase Architecture

### Phase 1: VPC Infrastructure
- **Location**: `phase1/` directory
- **Components**: VPC, subnets, security groups, public gateways
- **Resources**: 23 resources (1 VPC, 3 subnets, 5 security groups, etc.)
- **Dependencies**: None (standalone)

### Phase 2: CBR and Test VSI  
- **Location**: `phase2/` directory
- **Components**: CBR zones/rules, test Ubuntu VSI, floating IP
- **Resources**: 10+ resources (3 CBR zones, 3 CBR rules, 1 VSI, etc.)
- **Dependencies**: Phase 1 (via terraform_remote_state)

## Quick Deployment

### Option 1: Use Deployment Script
```bash
# Deploy everything
./deploy.sh both

# Deploy phases separately
./deploy.sh phase1
./deploy.sh phase2

# Check status
./deploy.sh status
```

### Option 2: Manual Deployment
```bash
# Phase 1
cd phase1/
terraform init
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars

# Phase 2 (after Phase 1 completes)
cd ../phase2/
terraform init
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

## Key Files to Configure

1. **`phase1/terraform.tfvars`** - VPC configuration
2. **`phase2/terraform.tfvars`** - CBR and test VSI configuration

## Important Variables

### Phase 1 Required
- `ibmcloud_api_key` - IBM Cloud API key
- `vpc_name` - Name for the VPC
- `region` - IBM Cloud region (default: jp-tok)

### Phase 2 Required  
- `ibmcloud_api_key` - Same as Phase 1
- `ssh_key_name` - SSH key name in IBM Cloud
- `cbr_enforcement_mode` - Start with "report", switch to "enabled" later

## Validation

### Test Phase 1
```bash
cd phase1/
terraform output phase1_summary
terraform output vpc_id
```

### Test Phase 2
```bash
cd phase2/
terraform output test_vsi_details
curl http://$(terraform output -raw test_vsi_details | jq -r '.floating_ip')
```

## Cleanup

```bash
# Remove everything
./deploy.sh destroy-both

# Remove only Phase 2
./deploy.sh destroy-phase2
```

## Next Steps

1. Deploy Phase 1 and verify VPC connectivity
2. Deploy Phase 2 with CBR in "report" mode
3. Test access from allowed/blocked IPs
4. Switch CBR to "enabled" mode for enforcement
5. Monitor IBM Cloud Activity Tracker for CBR events