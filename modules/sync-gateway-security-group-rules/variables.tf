# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

variable "security_group_id" {
  description = "The ID of the Security Group to which all the rules should be attached."
  type        = string
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------

variable "interface_port" {
  description = "The port to use for the main Sync Gateway REST interface."
  type        = number
  default     = 4984
}

variable "interface_port_cidr_blocks" {
  description = "The list of IP address ranges in CIDR notation from which to allow connections to the interface_port."
  type        = list(string)
  default     = []
}

variable "interface_port_security_groups" {
  description = "The list of Security Group IDs from which to allow connections to the interface_port. If you update this variable, make sure to update var.num_interface_port_security_groups too!"
  type        = list(string)
  default     = []
}

variable "num_interface_port_security_groups" {
  description = "The number of security group IDs in var.interface_port_security_groups. We should be able to compute this automatically, but due to a Terraform limitation, if there are any dynamic resources in var.allow_inbound_from_cidr_blocks, then we won't be able to: https://github.com/hashicorp/terraform/pull/11482"
  type        = number
  default     = 0
}

variable "admin_interface_port" {
  description = "The port to use for the Sync Gateway Admin interface."
  type        = number
  default     = 4985
}

variable "admin_interface_port_cidr_blocks" {
  description = "The list of IP address ranges in CIDR notation from which to allow connections to the admin_interface_port. The admin interface exposes ALL Couchbase data, so you probably want to leave this list empty and only allow access from localhost!"
  type        = list(string)
  default     = []
}

variable "admin_interface_port_security_groups" {
  description = "The list of Security Group IDs from which to allow connections to the admin_interface_port. The admin interface exposes ALL Couchbase data, so you probably want to leave this list empty and only allow access from localhost! If you update this variable, make sure to update var.num_admin_interface_port_security_groups too!"
  type        = list(string)
  default     = []
}

variable "num_admin_interface_port_security_groups" {
  description = "The number of security group IDs in var.admin_interface_port_security_groups. We should be able to compute this automatically, but due to a Terraform limitation, if there are any dynamic resources in var.allow_inbound_from_cidr_blocks, then we won't be able to: https://github.com/hashicorp/terraform/pull/11482"
  type        = number
  default     = 0
}

