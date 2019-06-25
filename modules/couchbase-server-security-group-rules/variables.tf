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

variable "enable_non_ssl_ports" {
  description = "If set to true, enable the non SSL ports. Only applies to ports that have bot SSL and non SSL versions."
  type        = bool
  default     = true
}

variable "enable_ssl_ports" {
  description = "If set to true, enable the SSL ports. Only applies to ports that have bot SSL and non SSL versions."
  type        = bool
  default     = false
}

variable "rest_port" {
  description = "The port to use for REST/HTTP requests, including the Couchbase Web Console."
  type        = number
  default     = 8091
}

variable "ssl_rest_port" {
  description = "The port to use for REST/HTTP requests over SSL, including the Couchbase Web Console."
  type        = number
  default     = 18091
}

variable "rest_port_cidr_blocks" {
  description = "The list of IP address ranges in CIDR notation from which to allow connections to the rest_port."
  type        = list(string)
  default     = []
}

variable "rest_port_security_groups" {
  description = "The list of Security Group IDs from which to allow connections to the rest_port. If you update this variable, make sure to update var.num_rest_port_security_groups too!"
  type        = list(string)
  default     = []
}

variable "num_rest_port_security_groups" {
  description = "The number of security group IDs in var.rest_port_security_groups. We should be able to compute this automatically, but due to a Terraform limitation, if there are any dynamic resources in var.allow_inbound_from_cidr_blocks, then we won't be able to: https://github.com/hashicorp/terraform/pull/11482"
  type        = number
  default     = 0
}

variable "capi_port" {
  description = "The port to use for Views and XDCR access."
  type        = number
  default     = 8092
}

variable "ssl_capi_port" {
  description = "The port to use for Views and XDCR access over SSL."
  type        = number
  default     = 18092
}

variable "capi_port_cidr_blocks" {
  description = "The list of IP address ranges in CIDR notation from which to allow connections to the capi_port."
  type        = list(string)
  default     = []
}

variable "capi_port_security_groups" {
  description = "The list of Security Group IDs from which to allow connections to the capi_port. If you update this variable, make sure to update var.num_capi_port_security_groups too!"
  type        = list(string)
  default     = []
}

variable "num_capi_port_security_groups" {
  description = "The number of security group IDs in var.capi_port_security_groups. We should be able to compute this automatically, but due to a Terraform limitation, if there are any dynamic resources in var.allow_inbound_from_cidr_blocks, then we won't be able to: https://github.com/hashicorp/terraform/pull/11482"
  type        = number
  default     = 0
}

variable "query_port" {
  description = "The port to use for Query service REST/HTTP traffic."
  type        = number
  default     = 8093
}

variable "ssl_query_port" {
  description = "The port to use for Query service REST/HTTP traffic over SSL."
  type        = number
  default     = 18093
}

variable "query_port_cidr_blocks" {
  description = "The list of IP address ranges in CIDR notation from which to allow connections to the query_port."
  type        = list(string)
  default     = []
}

variable "query_port_security_groups" {
  description = "The list of Security Group IDs from which to allow connections to the query_port. If you update this variable, make sure to update var.num_query_port_security_groups too!"
  type        = list(string)
  default     = []
}

variable "num_query_port_security_groups" {
  description = "The number of security group IDs in var.query_port_security_groups. We should be able to compute this automatically, but due to a Terraform limitation, if there are any dynamic resources in var.allow_inbound_from_cidr_blocks, then we won't be able to: https://github.com/hashicorp/terraform/pull/11482"
  type        = number
  default     = 0
}

variable "fts_port" {
  description = "The port to use for Search service REST/HTTP traffic."
  type        = number
  default     = 8094
}

variable "ssl_fts_port" {
  description = "The port to use for Search service REST/HTTP traffic."
  type        = number
  default     = 18094
}

variable "fts_port_cidr_blocks" {
  description = "The list of IP address ranges in CIDR notation from which to allow connections to the fts_port."
  type        = list(string)
  default     = []
}

variable "fts_port_security_groups" {
  description = "The list of Security Group IDs from which to allow connections to the fts_port. If you update this variable, make sure to update var.num_fts_port_security_groups too!"
  type        = list(string)
  default     = []
}

variable "num_fts_port_security_groups" {
  description = "The number of security group IDs in var.fts_port_security_groups. We should be able to compute this automatically, but due to a Terraform limitation, if there are any dynamic resources in var.allow_inbound_from_cidr_blocks, then we won't be able to: https://github.com/hashicorp/terraform/pull/11482"
  type        = number
  default     = 0
}

variable "memcached_port" {
  description = "The port to use for the Data Service."
  type        = number
  default     = 11210
}

variable "ssl_memcached_port" {
  description = "The port to use for the Data Service."
  type        = number
  default     = 11207
}

variable "memcached_port_cidr_blocks" {
  description = "The list of IP address ranges in CIDR notation from which to allow connections to the memcached_port."
  type        = list(string)
  default     = []
}

variable "memcached_port_security_groups" {
  description = "The list of Security Group IDs from which to allow connections to the memcached_port. If you update this variable, make sure to update var.num_memcached_port_security_groups too!"
  type        = list(string)
  default     = []
}

variable "num_memcached_port_security_groups" {
  description = "The number of security group IDs in var.memcached_port_security_groups. We should be able to compute this automatically, but due to a Terraform limitation, if there are any dynamic resources in var.allow_inbound_from_cidr_blocks, then we won't be able to: https://github.com/hashicorp/terraform/pull/11482"
  type        = number
  default     = 0
}

variable "memcached_dedicated_port" {
  description = "The port to use for the Data Service."
  type        = number
  default     = 11209
}

variable "memcached_dedicated_port_cidr_blocks" {
  description = "The list of IP address ranges in CIDR notation from which to allow connections to the memcached_dedicated_port."
  type        = list(string)
  default     = []
}

variable "memcached_dedicated_port_security_groups" {
  description = "The list of Security Group IDs from which to allow connections to the memcached_dedicated_port. If you update this variable, make sure to update var.num_memcached_dedicated_port_security_groups too!"
  type        = list(string)
  default     = []
}

variable "num_memcached_dedicated_port_security_groups" {
  description = "The number of security group IDs in var.memcached_dedicated_port_security_groups. We should be able to compute this automatically, but due to a Terraform limitation, if there are any dynamic resources in var.allow_inbound_from_cidr_blocks, then we won't be able to: https://github.com/hashicorp/terraform/pull/11482"
  type        = number
  default     = 0
}

variable "moxi_port" {
  description = "The port to use for the Data Service."
  type        = number
  default     = 11211
}

variable "moxi_port_cidr_blocks" {
  description = "The list of IP address ranges in CIDR notation from which to allow connections to the moxi_port."
  type        = list(string)
  default     = []
}

variable "moxi_port_security_groups" {
  description = "The list of Security Group IDs from which to allow connections to the moxi_port. If you update this variable, make sure to update var.num_moxi_port_security_groups too!"
  type        = list(string)
  default     = []
}

variable "num_moxi_port_security_groups" {
  description = "The number of security group IDs in var.moxi_port_security_groups. We should be able to compute this automatically, but due to a Terraform limitation, if there are any dynamic resources in var.allow_inbound_from_cidr_blocks, then we won't be able to: https://github.com/hashicorp/terraform/pull/11482"
  type        = number
  default     = 0
}

variable "epmd_port" {
  description = "The port to use for the Erlang Port Mapper Daemon."
  type        = number
  default     = 4369
}

variable "indexer_start_port_range" {
  description = "The starting port in the port range to use for the Indexer Service."
  type        = number
  default     = 9100
}

variable "indexer_end_port_range" {
  description = "The starting port in the port range to use for the Indexer Service."
  type        = number
  default     = 9105
}

variable "projector_port" {
  description = "The port to use for the Indexer Service."
  type        = number
  default     = 9999
}

variable "internal_data_start_port_range" {
  description = "The starting port in the port range to use for node data exchange."
  type        = number
  default     = 21100
}

variable "internal_data_end_port_range" {
  description = "The starting port in the port range to use for node data exchange."
  type        = number
  default     = 21299
}

variable "internal_ports_cidr_blocks" {
  description = "The list of IP address ranges in CIDR notation from which to allow connections to the internal ports: epmd, indexer, projector, internal data."
  type        = list(string)
  default     = []
}

variable "internal_ports_security_groups" {
  description = "The list of Security Group IDs from which to allow connections to the internal ports: epmd, indexer, projector, internal data. If you update this variable, make sure to update var.num_internal_ports_security_groups too!"
  type        = list(string)
  default     = []
}

variable "num_internal_ports_security_groups" {
  description = "The number of security group IDs in var.internal_ports_security_groups. We should be able to compute this automatically, but due to a Terraform limitation, if there are any dynamic resources in var.allow_inbound_from_cidr_blocks, then we won't be able to: https://github.com/hashicorp/terraform/pull/11482"
  type        = number
  default     = 0
}

