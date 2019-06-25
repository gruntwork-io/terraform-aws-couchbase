# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY COUCHBASE CLUSTERS IN AWS
# This is an example of how to deploy Couchbase services (data, index, fts) and Sync Gateway across multiple separate
# clsuters in AWS.
# ---------------------------------------------------------------------------------------------------------------------

# ----------------------------------------------------------------------------------------------------------------------
# REQUIRE A SPECIFIC TERRAFORM VERSION OR HIGHER
# This module has been updated with 0.12 syntax, which means it is no longer compatible with any versions below 0.12.
# ----------------------------------------------------------------------------------------------------------------------

terraform {
  required_version = ">= 0.12"
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY THE COUCHBASE DATA NODES CLUSTER
# ---------------------------------------------------------------------------------------------------------------------

module "couchbase_data_nodes" {
  # When using these modules in your own code, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-couchbase.git//modules/couchbase-cluster?ref=v0.0.1"
  source = "../../modules/couchbase-cluster"

  cluster_name = var.couchbase_data_node_cluster_name
  min_size     = 3
  max_size     = 3

  # We use small instance types to keep these examples cheap to run. In a production setting, you'll probably want
  # R4 or M4 instances.
  instance_type = "t2.micro"

  ami_id    = data.template_file.ami_id.rendered
  user_data = data.template_file.user_data_couchbase_data_nodes.rendered

  vpc_id     = data.aws_vpc.default.id
  subnet_ids = data.aws_subnet_ids.default.ids

  # We recommend using a separate EBS Volumes for the Couchbase data dir
  ebs_block_devices = [
    {
      device_name = var.data_volume_device_name
      volume_type = "gp2"
      volume_size = 50
    },
  ]

  # To make testing easier, we allow SSH requests from any IP address here. In a production deployment, we strongly
  # recommend you limit this to the IP address ranges of known, trusted servers inside your VPC.
  allowed_ssh_cidr_blocks = ["0.0.0.0/0"]

  ssh_key_name = var.ssh_key_name

  # To make it easy to test this example from your computer, we allow the Couchbase servers to have public IPs. In a
  # production deployment, you'll probably want to keep all the servers in private subnets with only private IPs.
  associate_public_ip_address = true

  # We are using a load balancer for health checks so if a Couchbase node stops responding, it will automatically be
  # replaced with a new one.
  health_check_type = "ELB"

  # An example of custom tags
  tags = [
    {
      key                 = "Environment"
      value               = "development"
      propagate_at_launch = true
    },
  ]
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY THE COUCHBASE INDEX, QUERY, AND SEARCH NODES CLUSTER
# ---------------------------------------------------------------------------------------------------------------------

module "couchbase_index_query_search_nodes" {
  # When using these modules in your own code, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-couchbase.git//modules/couchbase-cluster?ref=v0.0.1"
  source = "../../modules/couchbase-cluster"

  cluster_name = var.couchbase_index_query_search_node_cluster_name
  min_size     = 2
  max_size     = 2

  # We use small instance types to keep these examples cheap to run. In a production setting, you'll probably want
  # R4 or M4 instances.
  instance_type = "t2.micro"

  ami_id    = data.template_file.ami_id.rendered
  user_data = data.template_file.user_data_couchbase_index_query_search_nodes.rendered

  vpc_id     = data.aws_vpc.default.id
  subnet_ids = data.aws_subnet_ids.default.ids

  # We recommend using a separate EBS Volumes for the Couchbase index dir
  ebs_block_devices = [
    {
      device_name = var.index_volume_device_name
      volume_type = "gp2"
      volume_size = 50
    },
  ]

  # To make testing easier, we allow SSH requests from any IP address here. In a production deployment, we strongly
  # recommend you limit this to the IP address ranges of known, trusted servers inside your VPC.
  allowed_ssh_cidr_blocks = ["0.0.0.0/0"]

  ssh_key_name = var.ssh_key_name

  # To make it easy to test this example from your computer, we allow the Couchbase servers to have public IPs. In a
  # production deployment, you'll probably want to keep all the servers in private subnets with only private IPs.
  associate_public_ip_address = true

  # We are using a load balancer for health checks so if a Couchbase node stops responding, it will automatically be
  # replaced with a new one.
  health_check_type = "ELB"

  # An example of custom tags
  tags = [
    {
      key                 = "Environment"
      value               = "development"
      propagate_at_launch = true
    },
  ]
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY THE SYNC GATEWAY CLUSTER
# ---------------------------------------------------------------------------------------------------------------------

module "sync_gateway" {
  # When using these modules in your own code, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-couchbase.git//modules/couchbase-cluster?ref=v0.0.1"
  source = "../../modules/couchbase-cluster"

  cluster_name = var.sync_gateway_cluster_name
  min_size     = 2
  max_size     = 2

  # We use small instance types to keep these examples cheap to run. In a production setting, you'll probably want
  # R4 or M4 instances.
  instance_type = "t2.micro"

  ami_id    = data.template_file.ami_id.rendered
  user_data = data.template_file.user_data_sync_gateway.rendered

  vpc_id     = data.aws_vpc.default.id
  subnet_ids = data.aws_subnet_ids.default.ids

  # To make testing easier, we allow SSH requests from any IP address here. In a production deployment, we strongly
  # recommend you limit this to the IP address ranges of known, trusted servers inside your VPC.
  allowed_ssh_cidr_blocks = ["0.0.0.0/0"]

  ssh_key_name = var.ssh_key_name

  # To make it easy to test this example from your computer, we allow the Couchbase servers to have public IPs. In a
  # production deployment, you'll probably want to keep all the servers in private subnets with only private IPs.
  associate_public_ip_address = true

  # We are using a load balancer for health checks so if a Couchbase node stops responding, it will automatically be
  # replaced with a new one.
  health_check_type = "ELB"

  # An example of custom tags
  tags = [
    {
      key                 = "Environment"
      value               = "development"
      propagate_at_launch = true
    },
  ]
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE USER DATA SCRIPTS THAT WILL RUN ON EACH INSTANCE IN THE VARIOUS CLUSTERS ON BOOT
# ---------------------------------------------------------------------------------------------------------------------

data "template_file" "user_data_couchbase_data_nodes" {
  template = file("${path.module}/user-data/user-data-couchbase-data-nodes.sh")

  vars = {
    cluster_asg_name = var.couchbase_data_node_cluster_name
    cluster_port     = module.couchbase_data_nodes_security_group_rules.rest_port

    # Pass in the data about the EBS volumes so they can be mounted
    data_volume_device_name = var.data_volume_device_name
    data_volume_mount_point = var.data_volume_mount_point
    volume_owner            = var.volume_owner

    # Use a small amount of memory so this example can fit on a t2.micro. In production settings, you'll want to run
    # on
    data_ramsize  = "512"
    index_ramsize = "256"
    fts_ramsize   = "256"
  }
}

data "template_file" "user_data_couchbase_index_query_search_nodes" {
  template = file("${path.module}/user-data/user-data-couchbase-index-query-search-nodes.sh")

  vars = {
    cluster_asg_name = var.couchbase_data_node_cluster_name
    cluster_port     = module.couchbase_data_nodes_security_group_rules.rest_port

    # Pass in the data about the EBS volumes so they can be mounted
    index_volume_device_name = var.index_volume_device_name
    index_volume_mount_point = var.index_volume_mount_point
    volume_owner             = var.volume_owner
  }
}

data "template_file" "user_data_sync_gateway" {
  template = file("${path.module}/user-data/user-data-sync-gateway.sh")

  vars = {
    cluster_asg_name = var.couchbase_data_node_cluster_name
    cluster_port     = module.couchbase_data_nodes_security_group_rules.rest_port

    # We expose the Sync Gateway on all IPs but the Sync Gateway Admin should ONLY be accessible from localhost, as it
    # provides admin access to ALL Sync Gateway data.
    sync_gateway_interface       = ":${module.sync_gateway_security_group_rules.interface_port}"
    sync_gateway_admin_interface = "127.0.0.1:${module.sync_gateway_security_group_rules.admin_interface_port}"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY A LOAD BALANCER FOR THE CLUSTERS
# We use this load balancer to (1) perform health checks, (2) route traffic to the Couchbase Web Console of all
# Couchbase nodes, (3) route traffic to the Sync Gateway nodes. Note that we do NOT route any traffic to other
# Couchbase APIs/ports: https://blog.couchbase.com/couchbase-101-q-and-a/
# ---------------------------------------------------------------------------------------------------------------------

module "load_balancer" {
  # When using these modules in your own code, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-couchbase.git//modules/load-balancer?ref=v0.0.1"
  source = "../../modules/load-balancer"

  name       = var.couchbase_data_node_cluster_name
  vpc_id     = data.aws_vpc.default.id
  subnet_ids = data.aws_subnet_ids.default.ids

  http_listener_ports            = [var.data_nodes_load_balancer_port, var.index_query_search_nodes_load_balancer_port, var.sync_gateway_load_balancer_port]
  https_listener_ports_and_certs = []

  # To make testing easier, we allow inbound connections from any IP. In production usage, you may want to only allow
  # connectsion from certain trusted servers, or even use an internal load balancer, so it's only accessible from
  # within the VPC

  allow_inbound_from_cidr_blocks = ["0.0.0.0/0"]
  internal                       = false

  # Since Sync Gateway and Couchbase Lite can have long running connections for changes feeds, we recommend setting the
  # idle timeout to the maximum value of 3,600 seconds (1 hour)
  # https://developer.couchbase.com/documentation/mobile/1.5/guides/sync-gateway/nginx/index.html#aws-elastic-load-balancer-elb
  idle_timeout = 3600
  tags = {
    Name = var.couchbase_data_node_cluster_name
  }
}

module "couchbase_data_nodes_target_group" {
  # When using these modules in your own code, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-couchbase.git//modules/load-balancer-target-group?ref=v0.0.1"
  source = "../../modules/load-balancer-target-group"

  target_group_name = var.couchbase_data_node_cluster_name
  asg_name          = module.couchbase_data_nodes.asg_name
  port              = module.couchbase_data_nodes_security_group_rules.rest_port
  health_check_path = "/ui/index.html"
  vpc_id            = data.aws_vpc.default.id

  listener_arns                   = [module.load_balancer.http_listener_arns[var.data_nodes_load_balancer_port]]
  num_listener_arns               = 1
  listener_rule_starting_priority = 100

  # The Couchbase Web Console uses web sockets, so it's best to enable stickiness so each user is routed to the same
  # server
  enable_stickiness = true
}

module "couchbase_index_query_search_nodes_target_group" {
  # When using these modules in your own code, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-couchbase.git//modules/load-balancer-target-group?ref=v0.0.1"
  source = "../../modules/load-balancer-target-group"

  target_group_name = var.couchbase_index_query_search_node_cluster_name
  asg_name          = module.couchbase_index_query_search_nodes.asg_name
  port              = module.couchbase_index_query_search_nodes_security_group_rules.rest_port
  health_check_path = "/ui/index.html"
  vpc_id            = data.aws_vpc.default.id

  listener_arns                   = [module.load_balancer.http_listener_arns[var.index_query_search_nodes_load_balancer_port]]
  num_listener_arns               = 1
  listener_rule_starting_priority = 100

  # The Couchbase Web Console uses web sockets, so it's best to enable stickiness so each user is routed to the same
  # server
  enable_stickiness = true
}

module "sync_gateway_target_group" {
  # When using these modules in your own code, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-couchbase.git//modules/load-balancer-target-group?ref=v0.0.1"
  source = "../../modules/load-balancer-target-group"

  target_group_name = var.sync_gateway_cluster_name
  asg_name          = module.sync_gateway.asg_name
  port              = module.sync_gateway_security_group_rules.interface_port
  health_check_path = "/"
  vpc_id            = data.aws_vpc.default.id

  listener_arns                   = [module.load_balancer.http_listener_arns[var.sync_gateway_load_balancer_port]]
  num_listener_arns               = 1
  listener_rule_starting_priority = 100
}

# ---------------------------------------------------------------------------------------------------------------------
# CONFIGURE THE SECURITY GROUP RULES FOR COUCHBASE AND SYNC GATEWAY
# This controls which ports are exposed and who can connect to them
# ---------------------------------------------------------------------------------------------------------------------

module "couchbase_data_nodes_security_group_rules" {
  # When using these modules in your own code, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-couchbase.git//modules/couchbase-server-security-group-rules?ref=v0.0.1"
  source = "../../modules/couchbase-server-security-group-rules"

  security_group_id = module.couchbase_data_nodes.security_group_id

  # To keep this example simple, we allow these client-facing ports to be accessed from any IP. In a production
  # deployment, you may want to lock these down just to trusted servers.

  rest_port_cidr_blocks      = ["0.0.0.0/0"]
  capi_port_cidr_blocks      = ["0.0.0.0/0"]
  query_port_cidr_blocks     = ["0.0.0.0/0"]
  fts_port_cidr_blocks       = ["0.0.0.0/0"]
  memcached_port_cidr_blocks = ["0.0.0.0/0"]
  moxi_port_cidr_blocks      = ["0.0.0.0/0"]

  # Make sure all the ports used for node-to-node communication are open to all the clusters

  rest_port_security_groups                    = [module.couchbase_index_query_search_nodes.security_group_id, module.sync_gateway.security_group_id]
  num_rest_port_security_groups                = 2
  capi_port_security_groups                    = [module.couchbase_index_query_search_nodes.security_group_id, module.sync_gateway.security_group_id]
  num_capi_port_security_groups                = 2
  query_port_security_groups                   = [module.couchbase_index_query_search_nodes.security_group_id, module.sync_gateway.security_group_id]
  num_query_port_security_groups               = 2
  fts_port_security_groups                     = [module.couchbase_index_query_search_nodes.security_group_id, module.sync_gateway.security_group_id]
  num_fts_port_security_groups                 = 2
  memcached_port_security_groups               = [module.couchbase_index_query_search_nodes.security_group_id, module.sync_gateway.security_group_id]
  num_memcached_port_security_groups           = 2
  memcached_dedicated_port_security_groups     = [module.couchbase_index_query_search_nodes.security_group_id, module.sync_gateway.security_group_id]
  num_memcached_dedicated_port_security_groups = 2
  internal_ports_security_groups               = [module.couchbase_index_query_search_nodes.security_group_id, module.sync_gateway.security_group_id]
  num_internal_ports_security_groups           = 2
}

module "couchbase_index_query_search_nodes_security_group_rules" {
  # When using these modules in your own code, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-couchbase.git//modules/couchbase-server-security-group-rules?ref=v0.0.1"
  source = "../../modules/couchbase-server-security-group-rules"

  security_group_id = module.couchbase_index_query_search_nodes.security_group_id

  # To keep this example simple, we allow these client-facing ports to be accessed from any IP. In a production
  # deployment, you may want to lock these down just to trusted servers.

  rest_port_cidr_blocks      = ["0.0.0.0/0"]
  capi_port_cidr_blocks      = ["0.0.0.0/0"]
  query_port_cidr_blocks     = ["0.0.0.0/0"]
  fts_port_cidr_blocks       = ["0.0.0.0/0"]
  memcached_port_cidr_blocks = ["0.0.0.0/0"]
  moxi_port_cidr_blocks      = ["0.0.0.0/0"]

  # Make sure all the ports used for node-to-node communication are open to all the clusters

  rest_port_security_groups                    = [module.couchbase_data_nodes.security_group_id, module.sync_gateway.security_group_id]
  num_rest_port_security_groups                = 2
  capi_port_security_groups                    = [module.couchbase_data_nodes.security_group_id, module.sync_gateway.security_group_id]
  num_capi_port_security_groups                = 2
  query_port_security_groups                   = [module.couchbase_data_nodes.security_group_id, module.sync_gateway.security_group_id]
  num_query_port_security_groups               = 2
  fts_port_security_groups                     = [module.couchbase_data_nodes.security_group_id, module.sync_gateway.security_group_id]
  num_fts_port_security_groups                 = 2
  memcached_port_security_groups               = [module.couchbase_data_nodes.security_group_id, module.sync_gateway.security_group_id]
  num_memcached_port_security_groups           = 2
  memcached_dedicated_port_security_groups     = [module.couchbase_data_nodes.security_group_id, module.sync_gateway.security_group_id]
  num_memcached_dedicated_port_security_groups = 2
  internal_ports_security_groups               = [module.couchbase_data_nodes.security_group_id, module.sync_gateway.security_group_id]
  num_internal_ports_security_groups           = 2
}

module "sync_gateway_security_group_rules" {
  # When using these modules in your own code, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-couchbase.git//modules/sync-gateway-security-group-rules?ref=v0.0.1"
  source = "../../modules/sync-gateway-security-group-rules"

  security_group_id = module.sync_gateway.security_group_id

  # To keep this example simple, we allow these interface port to be accessed from any IP. In a production
  # deployment, you may want to lock this down just to trusted servers.
  interface_port_cidr_blocks = ["0.0.0.0/0"]
}

# ---------------------------------------------------------------------------------------------------------------------
# ATTACH IAM POLICIES TO EACH CLUSTER
# These policies allow the clusters to automatically bootstrap themselves
# ---------------------------------------------------------------------------------------------------------------------

module "iam_policies_couchbase_data_nodes" {
  # When using these modules in your own code, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-couchbase.git//modules/couchbase-server-security-group-rules?ref=v0.0.1"
  source = "../../modules/couchbase-iam-policies"

  iam_role_id = module.couchbase_data_nodes.iam_role_id
}

module "iam_policies_couchbase_index_query_search_nodes" {
  # When using these modules in your own code, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-couchbase.git//modules/couchbase-server-security-group-rules?ref=v0.0.1"
  source = "../../modules/couchbase-iam-policies"

  iam_role_id = module.couchbase_index_query_search_nodes.iam_role_id
}

module "iam_policies_sync_gateway" {
  # When using these modules in your own code, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-couchbase.git//modules/couchbase-server-security-group-rules?ref=v0.0.1"
  source = "../../modules/couchbase-iam-policies"

  iam_role_id = module.sync_gateway.iam_role_id
}

# ---------------------------------------------------------------------------------------------------------------------
# USE THE PUBLIC EXAMPLE AMIS IF VAR.AMI_ID IS NOT SPECIFIED
# We have published some example AMIs publicly that will be used if var.ami_id is not specified. This makes it easier
# to try these examples out, but we recommend you build your own AMIs for production use.
# ---------------------------------------------------------------------------------------------------------------------

data "aws_ami" "coubase_ubuntu_example" {
  most_recent = true
  owners      = ["562637147889"] # Gruntwork

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "image-type"
    values = ["machine"]
  }

  filter {
    name   = "name"
    values = ["*couchbase-ubuntu-example*"]
  }
}

data "template_file" "ami_id" {
  template = var.ami_id == null ? data.aws_ami.coubase_ubuntu_example.id : var.ami_id
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY COUCHBASE IN THE DEFAULT VPC AND SUBNETS
# Using the default VPC and subnets makes this example easy to run and test, but it means Couchbase is accessible from
# the public Internet. For a production deployment, we strongly recommend deploying into a custom VPC with private
# subnets.
# ---------------------------------------------------------------------------------------------------------------------

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}

