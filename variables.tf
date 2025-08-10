# Variables for company VPC replica infrastructure

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

variable "resource_group_id" {
  description = "ID of the resource group where resources will be created"
  type        = string
  default     = "default"
}

# VPC Configuration
variable "vpc_name" {
  description = "Name of the VPC to be created"
  type        = string
  default     = "company-vpc"
}

variable "classic_access" {
  description = "Enable classic infrastructure access for the VPC"
  type        = bool
  default     = false
}

# Address Prefixes Configuration
variable "address_prefixes" {
  description = "Address prefixes for each zone"
  type        = map(string)
  default = {
    "jp-tok-1" = "10.10.10.0/24"
    "jp-tok-2" = "10.20.20.0/24"
    "jp-tok-3" = "10.30.30.0/24"
  }
}

# Subnet Configuration
variable "subnet_configs" {
  description = "Configuration for subnets in each zone"
  type = map(object({
    zone               = string
    cidr               = string
    has_public_gateway = bool
  }))
  default = {
    "subnet-1" = {
      zone               = "jp-tok-1"
      cidr               = "10.10.10.0/26"
      has_public_gateway = false
    }
    "subnet-2" = {
      zone               = "jp-tok-2"
      cidr               = "10.20.20.0/26"
      has_public_gateway = true
    }
    "subnet-3" = {
      zone               = "jp-tok-3"
      cidr               = "10.30.30.0/26"
      has_public_gateway = true
    }
  }
}

# Public Gateway Configuration
variable "public_gateways" {
  description = "Zones where public gateways should be created"
  type        = list(string)
  default     = ["jp-tok-2", "jp-tok-3"]
}

# Security Group Rules Configuration
variable "hlf_sg_allowed_ip" {
  description = "IP address allowed in hlf-sg security group"
  type        = string
  default     = "136.158.43.87"
}

variable "jason_cs_sg_allowed_ips" {
  description = "List of IP addresses allowed in jason-cs-sg security group"
  type        = list(string)
  default = [
    "136.158.43.48",
    "120.29.79.239",
    "136.158.43.207",
    "112.200.9.106",
    "112.200.7.97"
  ]
}

variable "jason_ws_allowed_ip" {
  description = "IP address allowed in jason-ws security group"
  type        = string
  default     = "136.158.43.48"
}

# Tagging
variable "tags" {
  description = "Tags to be applied to all resources"
  type        = list(string)
  default     = ["terraform", "company-vpc", "vpc-infrastructure"]
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