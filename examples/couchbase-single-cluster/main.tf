# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY A COUCHBASE CLUSTER IN AWS
# This is an example of how to deploy Couchbase in AWS with all of the Couchbase services and Sync Gateway in a single
# cluster. The cluster runs on top of an Auto Scaling Group (ASG), with EBS Volumes attached, and a load balancer
# used for health checks and to distribute traffic across Sync Gateway.
# ---------------------------------------------------------------------------------------------------------------------

provider "aws" {
  region = "${var.aws_region}"
}

terraform {
  required_version = ">= 0.10.3"
}

locals {
  data_volume_device_name  = "/dev/xvdf"
  data_volume_mount_point  = "/couchbase-data"
  index_volume_device_name = "/dev/xvdg"
  index_volume_mount_point = "/couchbase-index"
  volume_owner             = "couchbase"
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY THE COUCHBASE CLUSTER
# ---------------------------------------------------------------------------------------------------------------------

module "couchbase" {
  # When using these modules in your own code, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-couchbase.git//modules/couchbase-cluster?ref=v0.0.1"
  source = "../../modules/couchbase-cluster"

  cluster_name  = "${var.cluster_name}"
  min_size      = 3
  max_size      = 3
  instance_type = "t2.micro"

  ami_id    = "${var.ami_id}"
  user_data = "${data.template_file.user_data_server.rendered}"

  vpc_id     = "${data.aws_vpc.default.id}"
  subnet_ids = "${data.aws_subnet_ids.default.ids}"

  # We recommend using two EBS Volumes with your Couchbase servers: one for the data directory and one for the index
  # directory.
  ebs_block_devices = [
    {
      device_name = "${local.data_volume_device_name}"
      volume_type = "gp2"
      volume_size = 50
      encrypted   = true
    },
    {
      device_name = "${local.index_volume_device_name}"
      volume_type = "gp2"
      volume_size = 50
      encrypted   = true
    },
  ]

  # To make testing easier, we allow SSH requests from any IP address here. In a production deployment, we strongly
  # recommend you limit this to the IP address ranges of known, trusted servers inside your VPC.
  allowed_ssh_cidr_blocks = ["0.0.0.0/0"]

  ssh_key_name = "${var.ssh_key_name}"

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
# THE USER DATA SCRIPT THAT WILL RUN ON EACH EC2 INSTANCE WHEN IT'S BOOTING
# This script will configure and start Couchbase and Sync Gateway
# ---------------------------------------------------------------------------------------------------------------------

data "template_file" "user_data_server" {
  template = "${file("${path.module}/examples/root-example/user-data-server.sh")}"

  vars {
    aws_region       = "${var.aws_region}"
    cluster_asg_name = "${var.cluster_name}"
    cluster_port     = "${module.couchbase_security_group_rules.rest_port}"

    # We expose the Sync Gateway on all IPs but the Sync Gateway Admin should ONLY be accessible from localhost, as it
    # provides admin access to ALL Sync Gateway data.

    sync_gateway_interface       = ":${module.sync_gateway_security_group_rules.interface_port}"
    sync_gateway_admin_interface = "127.0.0.1:${module.sync_gateway_security_group_rules.admin_interface_port}"

    # Pass in the data about the EBS volumes so they can be mounted

    data_volume_device_name  = "${local.data_volume_device_name}"
    data_volume_mount_point  = "${local.data_volume_mount_point}"
    index_volume_device_name = "${local.index_volume_device_name}"
    index_volume_mount_point = "${local.index_volume_mount_point}"
    volume_owner             = "${local.volume_owner}"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY A LOAD BALANCER
# We use this load balancer to (1) perform health checks and (2) route traffic across the Sync Gateway nodes.
# ---------------------------------------------------------------------------------------------------------------------

module "load_balancer" {
  # When using these modules in your own code, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-couchbase.git//modules/load-balancer?ref=v0.0.1"
  source = "../../modules/load-balancer"

  name = "${var.cluster_name}"

  vpc_id     = "${data.aws_vpc.default.id}"
  subnet_ids = "${data.aws_subnet_ids.default.ids}"

  # To make testing easier, we allow inbound connections from any IP. In production usage, you may want to only allow
  # connectsion from certain trusted servers, or even use an internal load balancer, so it's only accessible from
  # within the VPC
  allow_http_inbound_from_cidr_blocks = ["0.0.0.0/0"]

  internal = false

  # Configure the ports used by Couchbase and Sync Gateway
  couchbase_server_port = "${module.couchbase_security_group_rules.rest_port}"
  sync_gateway_port     = "${module.sync_gateway_security_group_rules.interface_port}"

  # An example of custom tags
  tags = {
    Name = "${var.cluster_name}"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ATTACH THE LOAD BALANCER'S TARGET GROUPS TO OUR AUTO SCALING GROUP
# This way, when new servers are deployed in the ASG, they will automatically register in the appropriate Target Group
# and begin performing health checks.
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_autoscaling_attachment" "couchbase_server" {
  autoscaling_group_name = "${module.couchbase.asg_name}"
  alb_target_group_arn   = "${module.load_balancer.couchbase_server_target_group_arn}"
}

resource "aws_autoscaling_attachment" "sync_gateway" {
  autoscaling_group_name = "${module.couchbase.asg_name}"
  alb_target_group_arn   = "${module.load_balancer.sync_gateway_target_group_arn}"
}

# ---------------------------------------------------------------------------------------------------------------------
# CONFIGURE THE SECURITY GROUP RULES FOR COUCHBASE AND SYNC GATEWAY
# This controls which ports are exposed and who can connect to them
# ---------------------------------------------------------------------------------------------------------------------

module "couchbase_security_group_rules" {
  # When using these modules in your own code, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-couchbase.git//modules/couchbase-server-security-group-rules?ref=v0.0.1"
  source = "../../modules/couchbase-server-security-group-rules"

  security_group_id = "${module.couchbase.security_group_id}"

  # To keep this example simple, we allow these client-facing ports to be accessed from any IP. In a production
  # deployment, you may want to lock these down just to trusted servers.

  rest_port_cidr_blocks      = ["0.0.0.0/0"]
  capi_port_cidr_blocks      = ["0.0.0.0/0"]
  query_port_cidr_blocks     = ["0.0.0.0/0"]
  fts_port_cidr_blocks       = ["0.0.0.0/0"]
  memcached_port_cidr_blocks = ["0.0.0.0/0"]
  moxi_port_cidr_blocks      = ["0.0.0.0/0"]
}

module "sync_gateway_security_group_rules" {
  # When using these modules in your own code, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-couchbase.git//modules/sync-gateway-security-group-rules?ref=v0.0.1"
  source = "../../modules/sync-gateway-security-group-rules"

  security_group_id = "${module.couchbase.security_group_id}"

  # To keep this example simple, we allow these interface port to be accessed from any IP. In a production
  # deployment, you may want to lock this down just to trusted servers.
  interface_port_cidr_blocks = ["0.0.0.0/0"]
}

# ---------------------------------------------------------------------------------------------------------------------
# ATTACH IAM POLICIES TO THE CLUSTER
# These policies allow the cluster to automatically bootstrap itself
# ---------------------------------------------------------------------------------------------------------------------

module "iam_policies" {
  # When using these modules in your own code, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-couchbase.git//modules/couchbase-server-security-group-rules?ref=v0.0.1"
  source = "../../modules/couchbase-iam-policies"

  iam_role_id = "${module.couchbase.iam_role_id}"
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
  vpc_id = "${data.aws_vpc.default.id}"
}
