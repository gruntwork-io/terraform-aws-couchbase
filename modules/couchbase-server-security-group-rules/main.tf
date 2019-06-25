# ----------------------------------------------------------------------------------------------------------------------
# REQUIRE A SPECIFIC TERRAFORM VERSION OR HIGHER
# This module has been updated with 0.12 syntax, which means it is no longer compatible with any versions below 0.12.
# ----------------------------------------------------------------------------------------------------------------------

terraform {
  required_version = ">= 0.12"
}

# ---------------------------------------------------------------------------------------------------------------------
# REST PORT
# REST/HTTP including Web UI
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_security_group_rule" "rest_port_cidr_blocks" {
  count             = length(var.rest_port_cidr_blocks) > 0 && var.enable_non_ssl_ports ? 1 : 0
  type              = "ingress"
  from_port         = var.rest_port
  to_port           = var.rest_port
  protocol          = "tcp"
  security_group_id = var.security_group_id
  cidr_blocks       = var.rest_port_cidr_blocks
}

resource "aws_security_group_rule" "rest_port_security_groups" {
  count                    = var.enable_non_ssl_ports ? var.num_rest_port_security_groups : 0
  type                     = "ingress"
  from_port                = var.rest_port
  to_port                  = var.rest_port
  protocol                 = "tcp"
  security_group_id        = var.security_group_id
  source_security_group_id = element(var.rest_port_security_groups, count.index)
}

resource "aws_security_group_rule" "rest_port_self" {
  count             = var.enable_non_ssl_ports ? 1 : 0
  type              = "ingress"
  from_port         = var.rest_port
  to_port           = var.rest_port
  protocol          = "tcp"
  security_group_id = var.security_group_id
  self              = true
}

resource "aws_security_group_rule" "ssl_rest_port_cidr_blocks" {
  count             = length(var.rest_port_cidr_blocks) > 0 && var.enable_ssl_ports ? 1 : 0
  type              = "ingress"
  from_port         = var.ssl_rest_port
  to_port           = var.ssl_rest_port
  protocol          = "tcp"
  security_group_id = var.security_group_id
  cidr_blocks       = var.rest_port_cidr_blocks
}

resource "aws_security_group_rule" "ssl_rest_port_security_groups" {
  count                    = var.enable_ssl_ports ? var.num_rest_port_security_groups : 0
  type                     = "ingress"
  from_port                = var.ssl_rest_port
  to_port                  = var.ssl_rest_port
  protocol                 = "tcp"
  security_group_id        = var.security_group_id
  source_security_group_id = element(var.rest_port_security_groups, count.index)
}

resource "aws_security_group_rule" "ssl_rest_port_self" {
  count             = var.enable_ssl_ports ? 1 : 0
  type              = "ingress"
  from_port         = var.ssl_rest_port
  to_port           = var.ssl_rest_port
  protocol          = "tcp"
  security_group_id = var.security_group_id
  self              = true
}

# ---------------------------------------------------------------------------------------------------------------------
# CAPI PORT
# Views and XDCR access
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_security_group_rule" "capi_port_cidr_blocks" {
  count             = length(var.capi_port_cidr_blocks) > 0 && var.enable_non_ssl_ports ? 1 : 0
  type              = "ingress"
  from_port         = var.capi_port
  to_port           = var.capi_port
  protocol          = "tcp"
  security_group_id = var.security_group_id
  cidr_blocks       = var.capi_port_cidr_blocks
}

resource "aws_security_group_rule" "capi_port_security_groups" {
  count                    = var.enable_non_ssl_ports ? var.num_capi_port_security_groups : 0
  type                     = "ingress"
  from_port                = var.capi_port
  to_port                  = var.capi_port
  protocol                 = "tcp"
  security_group_id        = var.security_group_id
  source_security_group_id = element(var.capi_port_security_groups, count.index)
}

resource "aws_security_group_rule" "capi_port_self" {
  count             = var.enable_non_ssl_ports ? 1 : 0
  type              = "ingress"
  from_port         = var.capi_port
  to_port           = var.capi_port
  protocol          = "tcp"
  security_group_id = var.security_group_id
  self              = true
}

resource "aws_security_group_rule" "ssl_capi_port_cidr_blocks" {
  count             = length(var.capi_port_cidr_blocks) > 0 && var.enable_ssl_ports ? 1 : 0
  type              = "ingress"
  from_port         = var.ssl_capi_port
  to_port           = var.ssl_capi_port
  protocol          = "tcp"
  security_group_id = var.security_group_id
  cidr_blocks       = var.capi_port_cidr_blocks
}

resource "aws_security_group_rule" "ssl_capi_port_security_groups" {
  count                    = var.enable_ssl_ports ? var.num_capi_port_security_groups : 0
  type                     = "ingress"
  from_port                = var.ssl_capi_port
  to_port                  = var.ssl_capi_port
  protocol                 = "tcp"
  security_group_id        = var.security_group_id
  source_security_group_id = element(var.capi_port_security_groups, count.index)
}

resource "aws_security_group_rule" "ssl_capi_self" {
  count             = var.enable_ssl_ports ? 1 : 0
  type              = "ingress"
  from_port         = var.ssl_capi_port
  to_port           = var.ssl_capi_port
  protocol          = "tcp"
  security_group_id = var.security_group_id
  self              = true
}

# ---------------------------------------------------------------------------------------------------------------------
# QUERY PORT
# Query service REST/HTTP traffic
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_security_group_rule" "query_port_cidr_blocks" {
  count             = length(var.query_port_cidr_blocks) > 0 && var.enable_non_ssl_ports ? 1 : 0
  type              = "ingress"
  from_port         = var.query_port
  to_port           = var.query_port
  protocol          = "tcp"
  security_group_id = var.security_group_id
  cidr_blocks       = var.query_port_cidr_blocks
}

resource "aws_security_group_rule" "query_port_security_groups" {
  count                    = var.enable_non_ssl_ports ? var.num_query_port_security_groups : 0
  type                     = "ingress"
  from_port                = var.query_port
  to_port                  = var.query_port
  protocol                 = "tcp"
  security_group_id        = var.security_group_id
  source_security_group_id = element(var.query_port_security_groups, count.index)
}

resource "aws_security_group_rule" "query_port_self" {
  count             = var.enable_non_ssl_ports ? 1 : 0
  type              = "ingress"
  from_port         = var.query_port
  to_port           = var.query_port
  protocol          = "tcp"
  security_group_id = var.security_group_id
  self              = true
}

resource "aws_security_group_rule" "ssl_query_port_cidr_blocks" {
  count             = length(var.query_port_cidr_blocks) > 0 && var.enable_ssl_ports ? 1 : 0
  type              = "ingress"
  from_port         = var.ssl_query_port
  to_port           = var.ssl_query_port
  protocol          = "tcp"
  security_group_id = var.security_group_id
  cidr_blocks       = var.query_port_cidr_blocks
}

resource "aws_security_group_rule" "ssl_query_port_security_groups" {
  count                    = var.enable_ssl_ports ? var.num_query_port_security_groups : 0
  type                     = "ingress"
  from_port                = var.ssl_query_port
  to_port                  = var.ssl_query_port
  protocol                 = "tcp"
  security_group_id        = var.security_group_id
  source_security_group_id = element(var.query_port_security_groups, count.index)
}

resource "aws_security_group_rule" "ssl_query_port_self" {
  count             = var.enable_ssl_ports ? 1 : 0
  type              = "ingress"
  from_port         = var.ssl_query_port
  to_port           = var.ssl_query_port
  protocol          = "tcp"
  security_group_id = var.security_group_id
  self              = true
}

# ---------------------------------------------------------------------------------------------------------------------
# SEARCH PORT
# Search service REST/HTTP traffic
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_security_group_rule" "fts_port_cidr_blocks" {
  count             = length(var.fts_port_cidr_blocks) > 0 && var.enable_non_ssl_ports ? 1 : 0
  type              = "ingress"
  from_port         = var.fts_port
  to_port           = var.fts_port
  protocol          = "tcp"
  security_group_id = var.security_group_id
  cidr_blocks       = var.fts_port_cidr_blocks
}

resource "aws_security_group_rule" "fts_port_security_groups" {
  count                    = var.enable_non_ssl_ports ? var.num_fts_port_security_groups : 0
  type                     = "ingress"
  from_port                = var.fts_port
  to_port                  = var.fts_port
  protocol                 = "tcp"
  security_group_id        = var.security_group_id
  source_security_group_id = element(var.fts_port_security_groups, count.index)
}

resource "aws_security_group_rule" "fts_port_self" {
  count             = var.enable_non_ssl_ports ? 1 : 0
  type              = "ingress"
  from_port         = var.fts_port
  to_port           = var.fts_port
  protocol          = "tcp"
  security_group_id = var.security_group_id
  self              = true
}

resource "aws_security_group_rule" "ssl_fts_port_cidr_blocks" {
  count             = length(var.fts_port_cidr_blocks) > 0 && var.enable_ssl_ports ? 1 : 0
  type              = "ingress"
  from_port         = var.ssl_fts_port
  to_port           = var.ssl_fts_port
  protocol          = "tcp"
  security_group_id = var.security_group_id
  cidr_blocks       = var.fts_port_cidr_blocks
}

resource "aws_security_group_rule" "ssl_fts_port_security_groups" {
  count                    = var.enable_ssl_ports ? var.num_fts_port_security_groups : 0
  type                     = "ingress"
  from_port                = var.ssl_fts_port
  to_port                  = var.ssl_fts_port
  protocol                 = "tcp"
  security_group_id        = var.security_group_id
  source_security_group_id = element(var.fts_port_security_groups, count.index)
}

resource "aws_security_group_rule" "ssl_fts_port_self" {
  count             = var.enable_ssl_ports ? 1 : 0
  type              = "ingress"
  from_port         = var.ssl_fts_port
  to_port           = var.ssl_fts_port
  protocol          = "tcp"
  security_group_id = var.security_group_id
  self              = true
}

# ---------------------------------------------------------------------------------------------------------------------
# MEMCACHED PORT
# Data Service
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_security_group_rule" "memcached_port_cidr_blocks" {
  count             = length(var.memcached_port_cidr_blocks) > 0 && var.enable_non_ssl_ports ? 1 : 0
  type              = "ingress"
  from_port         = var.memcached_port
  to_port           = var.memcached_port
  protocol          = "tcp"
  security_group_id = var.security_group_id
  cidr_blocks       = var.memcached_port_cidr_blocks
}

resource "aws_security_group_rule" "memcached_port_security_groups" {
  count                    = var.enable_non_ssl_ports ? var.num_memcached_port_security_groups : 0
  type                     = "ingress"
  from_port                = var.memcached_port
  to_port                  = var.memcached_port
  protocol                 = "tcp"
  security_group_id        = var.security_group_id
  source_security_group_id = element(var.memcached_port_security_groups, count.index)
}

resource "aws_security_group_rule" "memcached_port_self" {
  count             = var.enable_non_ssl_ports ? 1 : 0
  type              = "ingress"
  from_port         = var.memcached_port
  to_port           = var.memcached_port
  protocol          = "tcp"
  security_group_id = var.security_group_id
  self              = true
}

resource "aws_security_group_rule" "ssl_memcached_port_cidr_blocks" {
  count             = length(var.memcached_port_cidr_blocks) > 0 && var.enable_ssl_ports ? 1 : 0
  type              = "ingress"
  from_port         = var.ssl_memcached_port
  to_port           = var.ssl_memcached_port
  protocol          = "tcp"
  security_group_id = var.security_group_id
  cidr_blocks       = var.memcached_port_cidr_blocks
}

resource "aws_security_group_rule" "ssl_memcached_port_security_groups" {
  count                    = var.enable_ssl_ports ? var.num_memcached_port_security_groups : 0
  type                     = "ingress"
  from_port                = var.ssl_memcached_port
  to_port                  = var.ssl_memcached_port
  protocol                 = "tcp"
  security_group_id        = var.security_group_id
  source_security_group_id = element(var.memcached_port_security_groups, count.index)
}

resource "aws_security_group_rule" "ssl_memcached_port_self" {
  count             = var.enable_ssl_ports ? 1 : 0
  type              = "ingress"
  from_port         = var.ssl_memcached_port
  to_port           = var.ssl_memcached_port
  protocol          = "tcp"
  security_group_id = var.security_group_id
  self              = true
}

# ---------------------------------------------------------------------------------------------------------------------
# MEMCACHED DEDICATED PORT
# Data Service
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_security_group_rule" "memcached_dedicated_port_cidr_blocks" {
  count             = signum(length(var.memcached_dedicated_port_cidr_blocks))
  type              = "ingress"
  from_port         = var.memcached_dedicated_port
  to_port           = var.memcached_dedicated_port
  protocol          = "tcp"
  security_group_id = var.security_group_id
  cidr_blocks       = var.memcached_dedicated_port_cidr_blocks
}

resource "aws_security_group_rule" "memcached_dedicated_port_security_groups" {
  count                    = var.num_memcached_dedicated_port_security_groups
  type                     = "ingress"
  from_port                = var.memcached_dedicated_port
  to_port                  = var.memcached_dedicated_port
  protocol                 = "tcp"
  security_group_id        = var.security_group_id
  source_security_group_id = element(var.memcached_dedicated_port_security_groups, count.index)
}

resource "aws_security_group_rule" "memcached_dedicated_port_self" {
  type              = "ingress"
  from_port         = var.memcached_dedicated_port
  to_port           = var.memcached_dedicated_port
  protocol          = "tcp"
  security_group_id = var.security_group_id
  self              = true
}

# ---------------------------------------------------------------------------------------------------------------------
# MOXI PORT
# Moxi port
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_security_group_rule" "moxi_port_cidr_blocks" {
  count             = signum(length(var.moxi_port_cidr_blocks))
  type              = "ingress"
  from_port         = var.moxi_port
  to_port           = var.moxi_port
  protocol          = "tcp"
  security_group_id = var.security_group_id
  cidr_blocks       = var.moxi_port_cidr_blocks
}

resource "aws_security_group_rule" "moxi_port_security_groups" {
  count                    = var.num_moxi_port_security_groups
  type                     = "ingress"
  from_port                = var.moxi_port
  to_port                  = var.moxi_port
  protocol                 = "tcp"
  security_group_id        = var.security_group_id
  source_security_group_id = element(var.moxi_port_security_groups, count.index)
}

resource "aws_security_group_rule" "moxi_port_self" {
  type              = "ingress"
  from_port         = var.moxi_port
  to_port           = var.moxi_port
  protocol          = "tcp"
  security_group_id = var.security_group_id
  self              = true
}

# ---------------------------------------------------------------------------------------------------------------------
# EPMD PORT
# Erlang Port Mapper Daemon
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_security_group_rule" "epmd_port_cidr_blocks" {
  count             = signum(length(var.internal_ports_cidr_blocks))
  type              = "ingress"
  from_port         = var.epmd_port
  to_port           = var.epmd_port
  protocol          = "tcp"
  security_group_id = var.security_group_id
  cidr_blocks       = var.internal_ports_cidr_blocks
}

resource "aws_security_group_rule" "epmd_port_security_groups" {
  count                    = var.num_internal_ports_security_groups
  type                     = "ingress"
  from_port                = var.epmd_port
  to_port                  = var.epmd_port
  protocol                 = "tcp"
  security_group_id        = var.security_group_id
  source_security_group_id = element(var.internal_ports_security_groups, count.index)
}

resource "aws_security_group_rule" "epmd_port_self" {
  type              = "ingress"
  from_port         = var.epmd_port
  to_port           = var.epmd_port
  protocol          = "tcp"
  security_group_id = var.security_group_id
  self              = true
}

# ---------------------------------------------------------------------------------------------------------------------
# INDEXER PORTS
# Indexer Service
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_security_group_rule" "indexer_port_cidr_blocks" {
  count             = signum(length(var.internal_ports_cidr_blocks))
  type              = "ingress"
  from_port         = var.indexer_start_port_range
  to_port           = var.indexer_end_port_range
  protocol          = "tcp"
  security_group_id = var.security_group_id
  cidr_blocks       = var.internal_ports_cidr_blocks
}

resource "aws_security_group_rule" "indexer_port_security_groups" {
  count                    = var.num_internal_ports_security_groups
  type                     = "ingress"
  from_port                = var.indexer_start_port_range
  to_port                  = var.indexer_end_port_range
  protocol                 = "tcp"
  security_group_id        = var.security_group_id
  source_security_group_id = element(var.internal_ports_security_groups, count.index)
}

resource "aws_security_group_rule" "indexer_port_self" {
  type              = "ingress"
  from_port         = var.indexer_start_port_range
  to_port           = var.indexer_end_port_range
  protocol          = "tcp"
  security_group_id = var.security_group_id
  self              = true
}

# ---------------------------------------------------------------------------------------------------------------------
# PROJECTOR PORT
# Indexer Service
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_security_group_rule" "projector_port_cidr_blocks" {
  count             = signum(length(var.internal_ports_cidr_blocks))
  type              = "ingress"
  from_port         = var.projector_port
  to_port           = var.projector_port
  protocol          = "tcp"
  security_group_id = var.security_group_id
  cidr_blocks       = var.internal_ports_cidr_blocks
}

resource "aws_security_group_rule" "projector_port_security_groups" {
  count                    = var.num_internal_ports_security_groups
  type                     = "ingress"
  from_port                = var.projector_port
  to_port                  = var.projector_port
  protocol                 = "tcp"
  security_group_id        = var.security_group_id
  source_security_group_id = element(var.internal_ports_security_groups, count.index)
}

resource "aws_security_group_rule" "projector_port_self" {
  type              = "ingress"
  from_port         = var.projector_port
  to_port           = var.projector_port
  protocol          = "tcp"
  security_group_id = var.security_group_id
  self              = true
}

# ---------------------------------------------------------------------------------------------------------------------
# INTERNAL DATA PORTS
# Data Service
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_security_group_rule" "internal_data_port_cidr_blocks" {
  count             = signum(length(var.internal_ports_cidr_blocks))
  type              = "ingress"
  from_port         = var.internal_data_start_port_range
  to_port           = var.internal_data_end_port_range
  protocol          = "tcp"
  security_group_id = var.security_group_id
  cidr_blocks       = var.internal_ports_cidr_blocks
}

resource "aws_security_group_rule" "internal_data_port_security_groups" {
  count                    = var.num_internal_ports_security_groups
  type                     = "ingress"
  from_port                = var.internal_data_start_port_range
  to_port                  = var.internal_data_end_port_range
  protocol                 = "tcp"
  security_group_id        = var.security_group_id
  source_security_group_id = element(var.internal_ports_security_groups, count.index)
}

resource "aws_security_group_rule" "internal_data_port_self" {
  type              = "ingress"
  from_port         = var.internal_data_start_port_range
  to_port           = var.internal_data_end_port_range
  protocol          = "tcp"
  security_group_id = var.security_group_id
  self              = true
}

