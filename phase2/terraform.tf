# Terraform configuration for Phase 2: CBR and Test VSI
# Terraform and provider version constraints

terraform {
  required_version = ">= 1.0"
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = "~> 1.60.0"
    }
  }
}

# Provider configuration
provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
  region           = var.region
}