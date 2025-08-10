# Outputs for Phase 1: VPC Infrastructure
# These outputs will be consumed by Phase 2 for CBR and test VSI deployment

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

output "resource_group_name" {
  description = "Name of the resource group used"
  value       = data.ibm_resource_group.group.name
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

# Configuration Information for Phase 2
output "region" {
  description = "IBM Cloud region"
  value       = var.region
}

output "address_prefixes" {
  description = "Address prefixes configuration"
  value       = var.address_prefixes
}

# Summary Information
output "phase1_summary" {
  description = "Summary of Phase 1 infrastructure"
  value = {
    vpc_name              = ibm_is_vpc.vpc.name
    region                = var.region
    resource_group        = data.ibm_resource_group.group.name
    total_subnets         = length(ibm_is_subnet.subnet)
    total_public_gateways = length(ibm_is_public_gateway.gateway)
    total_security_groups = 5 # including default
    classic_access        = ibm_is_vpc.vpc.classic_access
    phase                 = "Phase 1: VPC Infrastructure"
  }
}