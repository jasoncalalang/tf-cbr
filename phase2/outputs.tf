# Outputs for Phase 2: CBR and Test VSI
# Additional infrastructure built on top of Phase 1

# Phase 1 Reference Information
output "phase1_vpc_id" {
  description = "VPC ID from Phase 1"
  value       = local.vpc_id
}

output "phase1_vpc_name" {
  description = "VPC name from Phase 1"
  value       = local.vpc_name
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
    "ssh-access"       = ibm_cbr_rule.ssh_access_rule.id
    "web-access"       = ibm_cbr_rule.web_access_rule.id
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
output "phase2_summary" {
  description = "Summary of Phase 2 infrastructure"
  value = {
    vpc_name             = local.vpc_name
    region               = local.region
    resource_group       = local.resource_group_name
    total_cbr_zones      = 3
    total_cbr_rules      = 3
    test_vsi_created     = true
    cbr_enforcement_mode = var.cbr_enforcement_mode
    test_vsi_floating_ip = ibm_is_floating_ip.cbr_test_fip.address
    phase                = "Phase 2: CBR and Test VSI"
  }
}

# Combined Infrastructure Summary
output "complete_infrastructure_summary" {
  description = "Summary of complete infrastructure (Phase 1 + Phase 2)"
  value = {
    vpc_name               = local.vpc_name
    region                 = local.region
    resource_group         = local.resource_group_name
    phase1_subnets         = length(local.subnet_ids)
    phase1_security_groups = 5
    phase2_cbr_zones       = 3
    phase2_cbr_rules       = 3
    phase2_test_vsi        = true
    cbr_enforcement_mode   = var.cbr_enforcement_mode
    deployment_phases      = 2
    test_vsi_access_url    = "http://${ibm_is_floating_ip.cbr_test_fip.address}"
  }
}