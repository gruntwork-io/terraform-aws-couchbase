# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

variable "security_group_id" {
  description = "The ID of the Security Group to which all the rules should be attached."
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------

variable "interface_port" {
  description = "The port to use for the main Sync Gateway REST interface."
  default     = 4984
}

variable "interface_port_cidr_blocks" {
  description = "The list of IP address ranges in CIDR notation from which to allow connections to the interface_port."
  type        = "list"
  default     = []
}

variable "interface_port_security_groups" {
  description = "The list of Security Group IDs from which to allow connections to the interface_port."
  type        = "list"
  default     = []
}

variable "admin_interface_port" {
  description = "The port to use for the Sync Gateway Admin interface."
  default     = 4985
}

variable "admin_interface_port_cidr_blocks" {
  description = "The list of IP address ranges in CIDR notation from which to allow connections to the admin_interface_port. The admin interface exposes ALL Couchbase data, so you probably want to leave this list empty and only allow access from localhost!"
  type        = "list"
  default     = []
}

variable "admin_interface_port_security_groups" {
  description = "The list of Security Group IDs from which to allow connections to the admin_interface_port. The admin interface exposes ALL Couchbase data, so you probably want to leave this list empty and only allow access from localhost!"
  type        = "list"
  default     = []
}
