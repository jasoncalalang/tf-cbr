# Phase 1: VPC Infrastructure Only
# Creates VPC, subnets, security groups, public gateways, and basic networking

# Data source for resource group
data "ibm_resource_group" "group" {
  name = var.resource_group_id == "default" ? "Default" : var.resource_group_id
}

# VPC Creation
resource "ibm_is_vpc" "vpc" {
  name                      = var.vpc_name
  resource_group            = data.ibm_resource_group.group.id
  classic_access            = var.classic_access
  address_prefix_management = "manual"
  tags                      = var.tags

  # DNS configuration matching the original
  dns {
    enable_hub = false
    resolver {
      type = "system"
    }
  }
}

# Address Prefixes (explicitly defined for manual mode)
# Custom address prefixes for each zone:
# jp-tok-1: 10.10.10.0/24
# jp-tok-2: 10.20.20.0/24  
# jp-tok-3: 10.30.30.0/24
resource "ibm_is_vpc_address_prefix" "prefix" {
  for_each = var.address_prefixes

  name = each.key
  zone = each.key
  vpc  = ibm_is_vpc.vpc.id
  cidr = each.value
}

# Public Gateways - Only created for zones jp-tok-2 and jp-tok-3
resource "ibm_is_public_gateway" "gateway" {
  for_each = toset(var.public_gateways)

  name           = each.key == "jp-tok-2" ? "test-gw" : "gw3"
  vpc            = ibm_is_vpc.vpc.id
  zone           = each.value
  resource_group = data.ibm_resource_group.group.id
  tags           = var.tags
}

# Subnets - Three subnets across three zones
resource "ibm_is_subnet" "subnet" {
  for_each = var.subnet_configs

  name            = each.key == "subnet-1" ? "sn-20250218-01" : each.key == "subnet-2" ? "sn-20250218-02" : "sn-20250218-03"
  vpc             = ibm_is_vpc.vpc.id
  zone            = each.value.zone
  ipv4_cidr_block = each.value.cidr
  resource_group  = data.ibm_resource_group.group.id
  public_gateway  = each.value.has_public_gateway ? ibm_is_public_gateway.gateway[each.value.zone].id : null
  tags            = var.tags

  depends_on = [ibm_is_vpc_address_prefix.prefix]
}

# Security Groups

# 1. Default Security Group (will be created automatically, but we configure its rules)
resource "ibm_is_security_group_rule" "default_outbound_all" {
  group     = ibm_is_vpc.vpc.default_security_group
  direction = "outbound"
  remote    = "0.0.0.0/0"
}

resource "ibm_is_security_group_rule" "default_inbound_self" {
  group     = ibm_is_vpc.vpc.default_security_group
  direction = "inbound"
  remote    = ibm_is_vpc.vpc.default_security_group
}

# 2. HLF Security Group
resource "ibm_is_security_group" "hlf_sg" {
  name           = "hlf-sg"
  vpc            = ibm_is_vpc.vpc.id
  resource_group = data.ibm_resource_group.group.id
  tags           = var.tags
}

# HLF Security Group Rules
resource "ibm_is_security_group_rule" "hlf_inbound_all" {
  group     = ibm_is_security_group.hlf_sg.id
  direction = "inbound"
  remote    = var.hlf_sg_allowed_ip
}

resource "ibm_is_security_group_rule" "hlf_outbound_tcp" {
  group     = ibm_is_security_group.hlf_sg.id
  direction = "outbound"
  remote    = "0.0.0.0/0"
  tcp {
    port_min = 1
    port_max = 65535
  }
}

# 3. Jason CS Security Group
resource "ibm_is_security_group" "jason_cs_sg" {
  name           = "jason-cs-sg"
  vpc            = ibm_is_vpc.vpc.id
  resource_group = data.ibm_resource_group.group.id
  tags           = var.tags
}

# Jason CS Security Group Rules - Multiple inbound rules for different IPs
resource "ibm_is_security_group_rule" "jason_cs_inbound" {
  count     = length(var.jason_cs_sg_allowed_ips)
  group     = ibm_is_security_group.jason_cs_sg.id
  direction = "inbound"
  remote    = var.jason_cs_sg_allowed_ips[count.index]
}

# 4. Jason WS Security Group
resource "ibm_is_security_group" "jason_ws_sg" {
  name           = "jason-ws"
  vpc            = ibm_is_vpc.vpc.id
  resource_group = data.ibm_resource_group.group.id
  tags           = var.tags
}

# Jason WS Security Group Rule
resource "ibm_is_security_group_rule" "jason_ws_inbound" {
  group     = ibm_is_security_group.jason_ws_sg.id
  direction = "inbound"
  remote    = var.jason_ws_allowed_ip
}

# 5. Kubernetes VPE Gateway Security Group (empty rules by design)
resource "ibm_is_security_group" "kube_vpegw_sg" {
  name           = "kube-vpegw-${ibm_is_vpc.vpc.id}"
  vpc            = ibm_is_vpc.vpc.id
  resource_group = data.ibm_resource_group.group.id
  tags           = var.tags
}

# Network ACL - Default ACL will be used with allow-all rules
# The default ACL is automatically created with the VPC and includes:
# - allow-inbound: inbound, allow, all protocols, 0.0.0.0/0 -> 0.0.0.0/0
# - allow-outbound: outbound, allow, all protocols, 0.0.0.0/0 -> 0.0.0.0/0

# All subnets will use the default ACL and default routing table (created automatically)