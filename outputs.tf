# Outputs for company VPC replica infrastructure
# Important resource information for use by other configurations

# VPC Information
output "vpc_id" {
  description = "ID of the created VPC"
  value       = ibm_is_vpc.vpc.id
}

output "vpc_name" {
  description = "Name of the created VPC"
  value       = ibm_is_vpc.vpc.name
}

output "vpc_crn" {
  description = "CRN of the created VPC"
  value       = ibm_is_vpc.vpc.crn
}

output "vpc_status" {
  description = "Status of the created VPC"
  value       = ibm_is_vpc.vpc.status
}

output "vpc_default_security_group_id" {
  description = "ID of the default security group"
  value       = ibm_is_vpc.vpc.default_security_group
}

output "vpc_default_network_acl_id" {
  description = "ID of the default network ACL"
  value       = ibm_is_vpc.vpc.default_network_acl
}

output "vpc_default_routing_table_id" {
  description = "ID of the default routing table"
  value       = ibm_is_vpc.vpc.default_routing_table
}

# Resource Group Information
output "resource_group_id" {
  description = "ID of the resource group used"
  value       = data.ibm_resource_group.group.id
}

# Subnet Information
output "subnet_ids" {
  description = "Map of subnet names to their IDs"
  value = {
    for k, subnet in ibm_is_subnet.subnet : k => subnet.id
  }
}

output "subnet_cidrs" {
  description = "Map of subnet names to their CIDR blocks"
  value = {
    for k, subnet in ibm_is_subnet.subnet : k => subnet.ipv4_cidr_block
  }
}

output "subnet_zones" {
  description = "Map of subnet names to their availability zones"
  value = {
    for k, subnet in ibm_is_subnet.subnet : k => subnet.zone
  }
}

output "subnet_details" {
  description = "Complete subnet information"
  value = {
    for k, subnet in ibm_is_subnet.subnet : k => {
      id             = subnet.id
      name           = subnet.name
      zone           = subnet.zone
      cidr           = subnet.ipv4_cidr_block
      available_ipv4 = subnet.available_ipv4_address_count
      total_ipv4     = subnet.total_ipv4_address_count
      public_gateway = subnet.public_gateway
      network_acl    = subnet.network_acl
      routing_table  = subnet.routing_table
      status         = subnet.status
    }
  }
}

# Public Gateway Information
output "public_gateway_ids" {
  description = "Map of public gateway zones to their IDs"
  value = {
    for k, gw in ibm_is_public_gateway.gateway : k => gw.id
  }
}

output "public_gateway_floating_ips" {
  description = "Map of public gateway zones to their floating IPs"
  value = {
    for k, gw in ibm_is_public_gateway.gateway : k => gw.floating_ip.address
  }
}

output "public_gateway_details" {
  description = "Complete public gateway information"
  value = {
    for k, gw in ibm_is_public_gateway.gateway : k => {
      id             = gw.id
      name           = gw.name
      zone           = gw.zone
      floating_ip    = gw.floating_ip.address
      floating_ip_id = gw.floating_ip.id
      status         = gw.status
    }
  }
}

# Security Group Information
output "security_group_ids" {
  description = "Map of security group names to their IDs"
  value = {
    "default"     = ibm_is_vpc.vpc.default_security_group
    "hlf-sg"      = ibm_is_security_group.hlf_sg.id
    "jason-cs-sg" = ibm_is_security_group.jason_cs_sg.id
    "jason-ws"    = ibm_is_security_group.jason_ws_sg.id
    "kube-vpegw"  = ibm_is_security_group.kube_vpegw_sg.id
  }
}

output "security_group_details" {
  description = "Complete security group information"
  value = {
    "hlf-sg" = {
      id   = ibm_is_security_group.hlf_sg.id
      name = ibm_is_security_group.hlf_sg.name
      crn  = ibm_is_security_group.hlf_sg.crn
    }
    "jason-cs-sg" = {
      id   = ibm_is_security_group.jason_cs_sg.id
      name = ibm_is_security_group.jason_cs_sg.name
      crn  = ibm_is_security_group.jason_cs_sg.crn
    }
    "jason-ws" = {
      id   = ibm_is_security_group.jason_ws_sg.id
      name = ibm_is_security_group.jason_ws_sg.name
      crn  = ibm_is_security_group.jason_ws_sg.crn
    }
    "kube-vpegw" = {
      id   = ibm_is_security_group.kube_vpegw_sg.id
      name = ibm_is_security_group.kube_vpegw_sg.name
      crn  = ibm_is_security_group.kube_vpegw_sg.crn
    }
  }
}

# Address Prefix Information
output "address_prefix_ids" {
  description = "Map of zone names to their address prefix IDs"
  value = {
    for k, prefix in ibm_is_vpc_address_prefix.prefix : k => prefix.id
  }
}

output "address_prefix_cidrs" {
  description = "Map of zone names to their address prefix CIDR blocks"
  value = {
    for k, prefix in ibm_is_vpc_address_prefix.prefix : k => prefix.cidr
  }
}

# CBR Network Zone Information
output "cbr_network_zone_ids" {
  description = "Map of CBR network zone names to their IDs"
  value = {
    "corporate-network" = ibm_cbr_zone.corporate_network_zone.id
    "vpc-internal"      = ibm_cbr_zone.vpc_internal_zone.id
    "admin-access"      = ibm_cbr_zone.admin_access_zone.id
  }
}

output "cbr_network_zone_details" {
  description = "Complete CBR network zone information"
  value = {
    "corporate-network" = {
      id          = ibm_cbr_zone.corporate_network_zone.id
      name        = ibm_cbr_zone.corporate_network_zone.name
      description = ibm_cbr_zone.corporate_network_zone.description
    }
    "vpc-internal" = {
      id          = ibm_cbr_zone.vpc_internal_zone.id
      name        = ibm_cbr_zone.vpc_internal_zone.name
      description = ibm_cbr_zone.vpc_internal_zone.description
    }
    "admin-access" = {
      id          = ibm_cbr_zone.admin_access_zone.id
      name        = ibm_cbr_zone.admin_access_zone.name
      description = ibm_cbr_zone.admin_access_zone.description
    }
  }
}

# CBR Rule Information
output "cbr_rule_ids" {
  description = "Map of CBR rule names to their IDs"
  value = {
    "ssh-access"      = ibm_cbr_rule.ssh_access_rule.id
    "web-access"      = ibm_cbr_rule.web_access_rule.id
    "admin-operations" = ibm_cbr_rule.admin_operations_rule.id
  }
}

output "cbr_rule_details" {
  description = "Complete CBR rule information"
  value = {
    "ssh-access" = {
      id               = ibm_cbr_rule.ssh_access_rule.id
      description      = ibm_cbr_rule.ssh_access_rule.description
      enforcement_mode = ibm_cbr_rule.ssh_access_rule.enforcement_mode
    }
    "web-access" = {
      id               = ibm_cbr_rule.web_access_rule.id
      description      = ibm_cbr_rule.web_access_rule.description
      enforcement_mode = ibm_cbr_rule.web_access_rule.enforcement_mode
    }
    "admin-operations" = {
      id               = ibm_cbr_rule.admin_operations_rule.id
      description      = ibm_cbr_rule.admin_operations_rule.description
      enforcement_mode = ibm_cbr_rule.admin_operations_rule.enforcement_mode
    }
  }
}

# Test VSI Information
output "test_vsi_details" {
  description = "Complete test VSI information"
  value = {
    id                = ibm_is_instance.cbr_test_ubuntu.id
    name              = ibm_is_instance.cbr_test_ubuntu.name
    status            = ibm_is_instance.cbr_test_ubuntu.status
    profile           = ibm_is_instance.cbr_test_ubuntu.profile
    zone              = ibm_is_instance.cbr_test_ubuntu.zone
    private_ip        = ibm_is_instance.cbr_test_ubuntu.primary_network_interface[0].primary_ip[0].address
    floating_ip       = ibm_is_floating_ip.cbr_test_fip.address
    floating_ip_id    = ibm_is_floating_ip.cbr_test_fip.id
    subnet_id         = ibm_is_instance.cbr_test_ubuntu.primary_network_interface[0].subnet
    security_group_id = ibm_is_security_group.cbr_test_sg.id
  }
}

output "test_security_group_id" {
  description = "ID of the test VSI security group"
  value       = ibm_is_security_group.cbr_test_sg.id
}

output "test_security_group_details" {
  description = "Complete test security group information"
  value = {
    id   = ibm_is_security_group.cbr_test_sg.id
    name = ibm_is_security_group.cbr_test_sg.name
    crn  = ibm_is_security_group.cbr_test_sg.crn
  }
}

# Summary Information
output "infrastructure_summary" {
  description = "Summary of the created infrastructure"
  value = {
    vpc_name              = ibm_is_vpc.vpc.name
    region                = var.region
    resource_group        = data.ibm_resource_group.group.name
    total_subnets         = length(ibm_is_subnet.subnet)
    total_public_gateways = length(ibm_is_public_gateway.gateway)
    total_security_groups = 6 # including default and cbr-test-sg
    total_cbr_zones       = 3
    total_cbr_rules       = 3
    test_vsi_created      = true
    classic_access        = ibm_is_vpc.vpc.classic_access
    cbr_enforcement_mode  = var.cbr_enforcement_mode
  }
}