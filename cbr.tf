# Context-Based Restrictions (CBR) Configuration
# Implements network-based access control for the VPC infrastructure

# Data source to get account information
data "ibm_iam_account_settings" "iam_account_settings" {}

# CBR Network Zone 1: Corporate Network Zone
# Includes IBM corporate IP ranges for authorized access
resource "ibm_cbr_zone" "corporate_network_zone" {
  name       = "corporate-network-zone"
  account_id = data.ibm_iam_account_settings.iam_account_settings.account_id
  
  addresses {
    type  = "ipAddress"
    value = var.corporate_network_ranges[0]  # 136.158.43.0/24
  }
  addresses {
    type  = "ipAddress"
    value = var.corporate_network_ranges[1]  # 120.29.79.0/24
  }
  description = "Corporate network zone for authorized IBM network access"
}

# CBR Network Zone 2: VPC Internal Zone  
# Includes the VPC CIDR ranges for internal communication
resource "ibm_cbr_zone" "vpc_internal_zone" {
  name       = "vpc-internal-zone"
  account_id = data.ibm_iam_account_settings.iam_account_settings.account_id
  
  addresses {
    type  = "ipAddress"
    value = "10.10.10.0/24"  # jp-tok-1
  }
  addresses {
    type  = "ipAddress"
    value = "10.20.20.0/24"  # jp-tok-2
  }
  addresses {
    type  = "ipAddress"
    value = "10.30.30.0/24"  # jp-tok-3
  }
  description = "VPC internal network zone for intra-VPC communication"
}

# CBR Network Zone 3: Admin Access Zone
# Configurable admin IP ranges for administrative operations
resource "ibm_cbr_zone" "admin_access_zone" {
  name       = "admin-access-zone"
  account_id = data.ibm_iam_account_settings.iam_account_settings.account_id
  
  dynamic "addresses" {
    for_each = var.admin_ip_ranges
    content {
      type  = "ipAddress"
      value = addresses.value
    }
  }
  
  description = "Admin access zone for privileged administrative operations"
}

# CBR Rule 1: SSH Access Restriction (Port 22)
# Restricts SSH access to corporate network and VPC internal only
resource "ibm_cbr_rule" "ssh_access_rule" {
  description      = "Restrict SSH access (port 22) to corporate network and VPC internal"
  enforcement_mode = var.cbr_enforcement_mode
  
  contexts {
    attributes {
      name  = "networkZoneId"
      value = ibm_cbr_zone.corporate_network_zone.id
    }
  }
  
  contexts {
    attributes {
      name  = "networkZoneId"
      value = ibm_cbr_zone.vpc_internal_zone.id
    }
  }
  
  resources {
    attributes {
      name  = "resource"
      value = ibm_is_vpc.vpc.crn
    }
  }
  
  operations {
    api_types {
      api_type_id = "crn:v1:bluemix:public:context-based-restrictions::::api-type:platform"
    }
  }
}

# CBR Rule 2: Web Access Restriction (Ports 80/443)
# Restricts web access to corporate network and VPC internal
resource "ibm_cbr_rule" "web_access_rule" {
  description      = "Restrict web access (ports 80/443) to corporate network and VPC internal"
  enforcement_mode = var.cbr_enforcement_mode
  
  contexts {
    attributes {
      name  = "networkZoneId"
      value = ibm_cbr_zone.corporate_network_zone.id
    }
  }
  
  contexts {
    attributes {
      name  = "networkZoneId"
      value = ibm_cbr_zone.vpc_internal_zone.id
    }
  }
  
  resources {
    attributes {
      name  = "resource"
      value = ibm_is_vpc.vpc.crn
    }
  }
  
  operations {
    api_types {
      api_type_id = "crn:v1:bluemix:public:context-based-restrictions::::api-type:platform"
    }
  }
}

# CBR Rule 3: Admin Operations Restriction
# Restricts administrative operations to admin access zone only
resource "ibm_cbr_rule" "admin_operations_rule" {
  description      = "Restrict admin operations to admin access zone"
  enforcement_mode = var.cbr_enforcement_mode
  
  contexts {
    attributes {
      name  = "networkZoneId"
      value = ibm_cbr_zone.admin_access_zone.id
    }
  }
  
  resources {
    attributes {
      name  = "resource"
      value = ibm_is_vpc.vpc.crn
    }
  }
  
  operations {
    api_types {
      api_type_id = "crn:v1:bluemix:public:context-based-restrictions::::api-type:platform"
    }
  }
}