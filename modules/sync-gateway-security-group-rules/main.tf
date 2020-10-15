# ----------------------------------------------------------------------------------------------------------------------
# REQUIRE A SPECIFIC TERRAFORM VERSION OR HIGHER
# This module has been updated with 0.12 syntax, which means it is no longer compatible with any versions below 0.12.
# ----------------------------------------------------------------------------------------------------------------------

terraform {
  # This module is now only being tested with Terraform 0.13.x. However, to make upgrading easier, we are setting
  # 0.12.26 as the minimum version, as that version added support for required_providers with source URLs, making it
  # forwards compatible with 0.13.x code.
  required_version = ">= 0.12.26"
}

# ---------------------------------------------------------------------------------------------------------------------
# INTERFACE
# Main REST interface for Sync Gateway
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_security_group_rule" "interface_port_cidr_blocks" {
  count             = signum(length(var.interface_port_cidr_blocks))
  type              = "ingress"
  from_port         = var.interface_port
  to_port           = var.interface_port
  protocol          = "tcp"
  security_group_id = var.security_group_id
  cidr_blocks       = var.interface_port_cidr_blocks
}

resource "aws_security_group_rule" "interface_port_security_groups" {
  count                    = var.num_interface_port_security_groups
  type                     = "ingress"
  from_port                = var.interface_port
  to_port                  = var.interface_port
  protocol                 = "tcp"
  security_group_id        = var.security_group_id
  source_security_group_id = element(var.interface_port_security_groups, count.index)
}

resource "aws_security_group_rule" "interface_port_self" {
  type              = "ingress"
  from_port         = var.interface_port
  to_port           = var.interface_port
  protocol          = "tcp"
  security_group_id = var.security_group_id
  self              = true
}

# ---------------------------------------------------------------------------------------------------------------------
# ADMIN INTERFACE
# Admin interface for Sync Gateway
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_security_group_rule" "admin_interface_port_cidr_blocks" {
  count             = signum(length(var.admin_interface_port_cidr_blocks))
  type              = "ingress"
  from_port         = var.admin_interface_port
  to_port           = var.admin_interface_port
  protocol          = "tcp"
  security_group_id = var.security_group_id
  cidr_blocks       = var.admin_interface_port_cidr_blocks
}

resource "aws_security_group_rule" "admin_interface_port_security_groups" {
  count                    = var.num_admin_interface_port_security_groups
  type                     = "ingress"
  from_port                = var.admin_interface_port
  to_port                  = var.admin_interface_port
  protocol                 = "tcp"
  security_group_id        = var.security_group_id
  source_security_group_id = element(var.admin_interface_port_security_groups, count.index)
}

