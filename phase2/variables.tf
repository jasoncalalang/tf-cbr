# Variables for Phase 2: CBR and Test VSI
# Context-Based Restrictions and test infrastructure

# IBM Cloud Configuration
variable "ibmcloud_api_key" {
  description = "IBM Cloud API key for authentication"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "IBM Cloud region where resources will be created"
  type        = string
  default     = "jp-tok"
}

# Phase 1 State Configuration
variable "phase1_state_bucket" {
  description = "S3 bucket name where Phase 1 state is stored (for remote state)"
  type        = string
  default     = null
}

variable "phase1_state_key" {
  description = "S3 key path to Phase 1 state file (for remote state)"
  type        = string
  default     = "phase1/terraform.tfstate"
}

variable "phase1_state_region" {
  description = "Region of the S3 bucket for Phase 1 state (for remote state)"
  type        = string
  default     = null
}

# Alternative: Local Phase 1 state path (when using local state)
variable "phase1_local_state_path" {
  description = "Path to Phase 1 local state file"
  type        = string
  default     = "../phase1/terraform.tfstate"
}

# CBR Configuration Variables
variable "admin_ip_ranges" {
  description = "IP ranges allowed for admin operations in CBR rules"
  type        = list(string)
  default     = ["192.168.1.0/24"]
}

variable "cbr_enforcement_mode" {
  description = "CBR enforcement mode: 'enabled' or 'report'"
  type        = string
  default     = "report"
  validation {
    condition     = contains(["enabled", "report"], var.cbr_enforcement_mode)
    error_message = "CBR enforcement mode must be either 'enabled' or 'report'."
  }
}

variable "corporate_network_ranges" {
  description = "Corporate network IP ranges for CBR network zones"
  type        = list(string)
  default     = ["136.158.43.0/24", "120.29.79.0/24"]
}

# Test VSI Configuration Variables
variable "ssh_key_name" {
  description = "Name of the SSH key for accessing the test VSI"
  type        = string
  default     = "default-ssh-key"
}

variable "test_vsi_profile" {
  description = "Instance profile for the test VSI"
  type        = string
  default     = "bx2-2x8"
}

variable "test_vsi_name" {
  description = "Name of the test VSI"
  type        = string
  default     = "cbr-test-ubuntu"
}

# Tagging
variable "tags" {
  description = "Tags to be applied to all resources"
  type        = list(string)
  default     = ["terraform", "company-vpc", "cbr-test", "phase-2"]
}