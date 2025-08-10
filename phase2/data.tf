# Data sources for Phase 2: CBR and Test VSI
# References Phase 1 infrastructure outputs

# Data source to get Phase 1 state outputs
# This references the Phase 1 infrastructure created in the previous phase
data "terraform_remote_state" "phase1" {
  backend = "local"
  config = {
    path = var.phase1_local_state_path
  }
}

# Alternative remote state configuration (uncomment if using remote state)
# data "terraform_remote_state" "phase1" {
#   backend = "s3"
#   config = {
#     bucket = var.phase1_state_bucket
#     key    = var.phase1_state_key
#     region = var.phase1_state_region
#   }
# }

# Data source to get account information for CBR
data "ibm_iam_account_settings" "iam_account_settings" {}

# Data source to get the latest Ubuntu 24.04 image
data "ibm_is_image" "ubuntu_24_04" {
  name = "ibm-ubuntu-24-04-minimal-amd64-1"
}

# Data source to get the SSH key
data "ibm_is_ssh_key" "ssh_key" {
  name = var.ssh_key_name
}

# Local values for easier reference to Phase 1 outputs
locals {
  # Phase 1 VPC information
  vpc_id              = data.terraform_remote_state.phase1.outputs.vpc_id
  vpc_name            = data.terraform_remote_state.phase1.outputs.vpc_name
  vpc_crn             = data.terraform_remote_state.phase1.outputs.vpc_crn
  resource_group_id   = data.terraform_remote_state.phase1.outputs.resource_group_id
  resource_group_name = data.terraform_remote_state.phase1.outputs.resource_group_name

  # Subnet information
  subnet_ids     = data.terraform_remote_state.phase1.outputs.subnet_ids
  subnet_details = data.terraform_remote_state.phase1.outputs.subnet_details

  # Address prefixes for CBR network zones
  address_prefixes = data.terraform_remote_state.phase1.outputs.address_prefixes

  # Security group information  
  security_group_ids = data.terraform_remote_state.phase1.outputs.security_group_ids

  # Configuration
  region = data.terraform_remote_state.phase1.outputs.region
}