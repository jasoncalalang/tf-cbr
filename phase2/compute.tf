# Compute Resources for Phase 2 - Test VSI for CBR validation
# Creates a test Ubuntu 24.04 VSI with security group for CBR testing

# Security Group for Test VSI
resource "ibm_is_security_group" "cbr_test_sg" {
  name           = "cbr-test-sg"
  vpc            = local.vpc_id
  resource_group = local.resource_group_id
  tags           = concat(var.tags, ["cbr-test", "security-group"])
}

# Security Group Rules for Test VSI
# SSH access from corporate networks
resource "ibm_is_security_group_rule" "test_ssh_corporate" {
  count     = length(var.corporate_network_ranges)
  group     = ibm_is_security_group.cbr_test_sg.id
  direction = "inbound"
  remote    = var.corporate_network_ranges[count.index]
  tcp {
    port_min = 22
    port_max = 22
  }
}

# HTTP access for testing
resource "ibm_is_security_group_rule" "test_http" {
  count     = length(var.corporate_network_ranges)
  group     = ibm_is_security_group.cbr_test_sg.id
  direction = "inbound"
  remote    = var.corporate_network_ranges[count.index]
  tcp {
    port_min = 80
    port_max = 80
  }
}

# HTTPS access for testing
resource "ibm_is_security_group_rule" "test_https" {
  count     = length(var.corporate_network_ranges)
  group     = ibm_is_security_group.cbr_test_sg.id
  direction = "inbound"
  remote    = var.corporate_network_ranges[count.index]
  tcp {
    port_min = 443
    port_max = 443
  }
}

# ICMP from VPC CIDR for connectivity testing
resource "ibm_is_security_group_rule" "test_icmp_vpc" {
  for_each  = local.address_prefixes
  group     = ibm_is_security_group.cbr_test_sg.id
  direction = "inbound"
  remote    = each.value
  icmp {
    type = 8 # Echo Request
  }
}

# Outbound unrestricted
resource "ibm_is_security_group_rule" "test_outbound_all" {
  group     = ibm_is_security_group.cbr_test_sg.id
  direction = "outbound"
  remote    = "0.0.0.0/0"
}

# Test VSI Instance
resource "ibm_is_instance" "cbr_test_ubuntu" {
  name           = var.test_vsi_name
  image          = data.ibm_is_image.ubuntu_24_04.id
  profile        = var.test_vsi_profile
  vpc            = local.vpc_id
  zone           = "jp-tok-1"
  resource_group = local.resource_group_id
  tags           = concat(var.tags, ["cbr-test", "ubuntu-24-04", "test-vsi"])

  keys = [data.ibm_is_ssh_key.ssh_key.id]

  # Deploy in the first subnet (sn-20250218-01, jp-tok-1)
  primary_network_interface {
    name            = "eth0"
    subnet          = local.subnet_ids["subnet-1"]
    security_groups = [ibm_is_security_group.cbr_test_sg.id]
  }

  # User data to configure basic setup
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    hostname = var.test_vsi_name
  }))

  depends_on = [
    ibm_is_security_group.cbr_test_sg
  ]
}

# Floating IP for the test VSI
resource "ibm_is_floating_ip" "cbr_test_fip" {
  name           = "${var.test_vsi_name}-fip"
  target         = ibm_is_instance.cbr_test_ubuntu.primary_network_interface[0].id
  resource_group = local.resource_group_id
  tags           = concat(var.tags, ["cbr-test", "floating-ip"])
}