# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY TWO COUCHBASE CLUSTERS IN AWS WITH REPLICATION
# This is an example of how to deploy two Couchbase clusters in AWS with replication between them.
# ---------------------------------------------------------------------------------------------------------------------

# ----------------------------------------------------------------------------------------------------------------------
# REQUIRE A SPECIFIC TERRAFORM VERSION OR HIGHER
# This module has been updated with 0.12 syntax, which means it is no longer compatible with any versions below 0.12.
# ----------------------------------------------------------------------------------------------------------------------

terraform {
  required_version = ">= 0.12"
}

provider "aws" {
  alias  = "primary"
  region = var.primary_region
}

provider "aws" {
  alias  = "replica"
  region = var.replica_region
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY THE PRIMARY COUCHBASE CLUSTER
# ---------------------------------------------------------------------------------------------------------------------

module "couchbase_primary" {
  # When using these modules in your own code, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-couchbase.git//modules/couchbase-cluster?ref=v0.0.1"
  source = "../../modules/couchbase-cluster"

  cluster_name  = var.cluster_name_primary
  min_size      = 3
  max_size      = 3
  instance_type = "t2.micro"

  ami_id    = data.template_file.ami_id_primary.rendered
  user_data = data.template_file.user_data_primary.rendered

  vpc_id     = data.aws_vpc.default_primary.id
  subnet_ids = data.aws_subnet_ids.default_primary.ids

  # To make testing easier, we allow SSH requests from any IP address here. In a production deployment, we strongly
  # recommend you limit this to the IP address ranges of known, trusted servers inside your VPC.
  allowed_ssh_cidr_blocks = ["0.0.0.0/0"]

  ssh_key_name = var.ssh_key_name_primary

  # To make it easy to test this example from your computer, we allow the Couchbase servers to have public IPs. In a
  # production deployment, you'll probably want to keep all the servers in private subnets with only private IPs.
  associate_public_ip_address = true

  # We are using a load balancer for health checks so if a Couchbase node stops responding, it will automatically be
  # replaced with a new one.
  health_check_type = "ELB"

  providers = {
    aws = aws.primary
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY THE REPLICA COUCHBASE CLUSTER
# ---------------------------------------------------------------------------------------------------------------------

module "couchbase_replica" {
  # When using these modules in your own code, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-couchbase.git//modules/couchbase-cluster?ref=v0.0.1"
  source = "../../modules/couchbase-cluster"

  cluster_name  = var.cluster_name_replica
  min_size      = 3
  max_size      = 3
  instance_type = "t2.micro"

  ami_id    = data.template_file.ami_id_replica.rendered
  user_data = data.template_file.user_data_replica.rendered

  vpc_id     = data.aws_vpc.default_replica.id
  subnet_ids = data.aws_subnet_ids.default_replica.ids

  # To make testing easier, we allow SSH requests from any IP address here. In a production deployment, we strongly
  # recommend you limit this to the IP address ranges of known, trusted servers inside your VPC.
  allowed_ssh_cidr_blocks = ["0.0.0.0/0"]

  ssh_key_name = var.ssh_key_name_replica

  # To make it easy to test this example from your computer, we allow the Couchbase servers to have public IPs. In a
  # production deployment, you'll probably want to keep all the servers in private subnets with only private IPs.
  associate_public_ip_address = true

  # We are using a load balancer for health checks so if a Couchbase node stops responding, it will automatically be
  # replaced with a new one.
  health_check_type = "ELB"

  providers = {
    aws = aws.replica
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# THE USER DATA SCRIPT THAT WILL RUN ON EACH EC2 INSTANCE IN THE PRIMARY COUCHBASE CLUSTER WHEN IT'S BOOTING
# This script will configure and start Couchbase and replication
# ---------------------------------------------------------------------------------------------------------------------

data "template_file" "user_data_primary" {
  template = file("${path.module}/user-data/user-data-primary.sh")

  vars = {
    cluster_asg_name                    = var.cluster_name_primary
    cluster_port                        = module.couchbase_security_group_rules_primary.rest_port
    replication_dest_cluster_name       = var.cluster_name_replica
    replication_dest_cluster_aws_region = data.aws_region.replica.name
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# THE USER DATA SCRIPT THAT WILL RUN ON EACH EC2 INSTANCE IN THE REPLICA COUCHBASE CLUSTER WHEN IT'S BOOTING
# This script will configure and start Couchbase
# ---------------------------------------------------------------------------------------------------------------------

data "template_file" "user_data_replica" {
  template = file("${path.module}/user-data/user-data-replica.sh")

  vars = {
    cluster_asg_name = var.cluster_name_replica
    cluster_port     = module.couchbase_security_group_rules_replica.rest_port
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY A LOAD BALANCER FOR THE PRIMARY COUCHBASE CLUSTER
# We use this load balancer to (1) perform health checks and (2) route traffic to the Couchbase Web Console. Note that
# we do NOT route any traffic to other Couchbase APIs/ports: https://blog.couchbase.com/couchbase-101-q-and-a/
# ---------------------------------------------------------------------------------------------------------------------

module "load_balancer_primary" {
  # When using these modules in your own code, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-couchbase.git//modules/load-balancer?ref=v0.0.1"
  source = "../../modules/load-balancer"

  name       = var.cluster_name_primary
  vpc_id     = data.aws_vpc.default_primary.id
  subnet_ids = data.aws_subnet_ids.default_primary.ids

  http_listener_ports            = [var.couchbase_load_balancer_port]
  https_listener_ports_and_certs = []

  # To make testing easier, we allow inbound connections from any IP. In production usage, you may want to only allow
  # connectsion from certain trusted servers, or even use an internal load balancer, so it's only accessible from
  # within the VPC

  allow_inbound_from_cidr_blocks = ["0.0.0.0/0"]
  internal                       = false
  providers = {
    aws = aws.primary
  }
}

module "couchbase_target_group_primary" {
  # When using these modules in your own code, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-couchbase.git//modules/load-balancer-target-group?ref=v0.0.1"
  source = "../../modules/load-balancer-target-group"

  target_group_name = "${var.cluster_name_primary}-cb"
  asg_name          = module.couchbase_primary.asg_name
  port              = module.couchbase_security_group_rules_primary.rest_port
  health_check_path = "/ui/index.html"
  vpc_id            = data.aws_vpc.default_primary.id

  listener_arns                   = [module.load_balancer_primary.http_listener_arns[var.couchbase_load_balancer_port]]
  num_listener_arns               = 1
  listener_rule_starting_priority = 100

  # The Couchbase Web Console uses web sockets, so it's best to enable stickiness so each user is routed to the same
  # server
  enable_stickiness = true

  providers = {
    aws = aws.primary
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY A LOAD BALANCER FOR THE REPLICA COUCHBASE CLUSTER
# We use this load balancer to (1) perform health checks and (2) route traffic to the Couchbase Web Console. Note that
# we do NOT route any traffic to other Couchbase APIs/ports: https://blog.couchbase.com/couchbase-101-q-and-a/
# ---------------------------------------------------------------------------------------------------------------------

module "load_balancer_replica" {
  # When using these modules in your own code, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-couchbase.git//modules/load-balancer?ref=v0.0.1"
  source = "../../modules/load-balancer"

  name       = var.cluster_name_replica
  vpc_id     = data.aws_vpc.default_replica.id
  subnet_ids = data.aws_subnet_ids.default_replica.ids

  http_listener_ports            = [var.couchbase_load_balancer_port]
  https_listener_ports_and_certs = []

  # To make testing easier, we allow inbound connections from any IP. In production usage, you may want to only allow
  # connectsion from certain trusted servers, or even use an internal load balancer, so it's only accessible from
  # within the VPC

  allow_inbound_from_cidr_blocks = ["0.0.0.0/0"]
  internal                       = false
  providers = {
    aws = aws.replica
  }
}

module "couchbase_target_group_replica" {
  # When using these modules in your own code, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-couchbase.git//modules/load-balancer-target-group?ref=v0.0.1"
  source = "../../modules/load-balancer-target-group"

  target_group_name = "${var.cluster_name_replica}-cb"
  asg_name          = module.couchbase_replica.asg_name
  port              = module.couchbase_security_group_rules_replica.rest_port
  health_check_path = "/ui/index.html"
  vpc_id            = data.aws_vpc.default_replica.id

  listener_arns                   = [module.load_balancer_replica.http_listener_arns[var.couchbase_load_balancer_port]]
  num_listener_arns               = 1
  listener_rule_starting_priority = 100

  # The Couchbase Web Console uses web sockets, so it's best to enable stickiness so each user is routed to the same
  # server
  enable_stickiness = true

  providers = {
    aws = aws.replica
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CONFIGURE THE SECURITY GROUP RULES FOR THE PRIMARY COUCHBASE CLUSTER
# This controls which ports are exposed and who can connect to them
# ---------------------------------------------------------------------------------------------------------------------

module "couchbase_security_group_rules_primary" {
  # When using these modules in your own code, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-couchbase.git//modules/couchbase-server-security-group-rules?ref=v0.0.1"
  source = "../../modules/couchbase-server-security-group-rules"

  security_group_id = module.couchbase_primary.security_group_id

  # To keep this example simple, we allow these client-facing ports to be accessed from any IP. In a production
  # deployment, you may want to lock these down just to trusted servers.

  rest_port_cidr_blocks      = ["0.0.0.0/0"]
  capi_port_cidr_blocks      = ["0.0.0.0/0"]
  query_port_cidr_blocks     = ["0.0.0.0/0"]
  fts_port_cidr_blocks       = ["0.0.0.0/0"]
  memcached_port_cidr_blocks = ["0.0.0.0/0"]
  moxi_port_cidr_blocks      = ["0.0.0.0/0"]
  providers = {
    aws = aws.primary
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CONFIGURE THE SECURITY GROUP RULES FOR THE REPLICA COUCHBASE CLUSTER
# This controls which ports are exposed and who can connect to them
# ---------------------------------------------------------------------------------------------------------------------

module "couchbase_security_group_rules_replica" {
  # When using these modules in your own code, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-couchbase.git//modules/couchbase-server-security-group-rules?ref=v0.0.1"
  source = "../../modules/couchbase-server-security-group-rules"

  security_group_id = module.couchbase_replica.security_group_id

  # To keep this example simple, we allow these client-facing ports to be accessed from any IP. In a production
  # deployment, you may want to lock these down just to trusted servers.

  rest_port_cidr_blocks      = ["0.0.0.0/0"]
  capi_port_cidr_blocks      = ["0.0.0.0/0"]
  query_port_cidr_blocks     = ["0.0.0.0/0"]
  fts_port_cidr_blocks       = ["0.0.0.0/0"]
  memcached_port_cidr_blocks = ["0.0.0.0/0"]
  moxi_port_cidr_blocks      = ["0.0.0.0/0"]
  providers = {
    aws = aws.replica
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ATTACH IAM POLICIES TO THE PRIMARY CLUSTER
# These policies allow the cluster to automatically bootstrap itself
# ---------------------------------------------------------------------------------------------------------------------

module "iam_policies_primary" {
  # When using these modules in your own code, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-couchbase.git//modules/couchbase-server-security-group-rules?ref=v0.0.1"
  source = "../../modules/couchbase-iam-policies"

  iam_role_id = module.couchbase_primary.iam_role_id

  providers = {
    aws = aws.primary
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ATTACH IAM POLICIES TO THE REPLICA CLUSTER
# These policies allow the cluster to automatically bootstrap itself
# ---------------------------------------------------------------------------------------------------------------------

module "iam_policies_replica" {
  # When using these modules in your own code, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-aws-couchbase.git//modules/couchbase-server-security-group-rules?ref=v0.0.1"
  source = "../../modules/couchbase-iam-policies"

  iam_role_id = module.couchbase_replica.iam_role_id

  providers = {
    aws = aws.replica
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# USE THE PUBLIC EXAMPLE AMIS IF VAR.AMI_ID_XXX IS NOT SPECIFIED
# We have published some example AMIs publicly that will be used if var.ami_id_primary or var.ami_id_replica is not
# specified. This makes it easier to try these examples out, but we recommend you build your own AMIs for production use.
# ---------------------------------------------------------------------------------------------------------------------

data "aws_ami" "coubase_ubuntu_example_primary" {
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

  provider = aws.primary
}

data "aws_ami" "coubase_ubuntu_example_replica" {
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

  provider = aws.replica
}

data "template_file" "ami_id_primary" {
  template = var.ami_id_primary == null ? data.aws_ami.coubase_ubuntu_example_primary.id : var.ami_id_primary
}

data "template_file" "ami_id_replica" {
  template = var.ami_id_replica == null ? data.aws_ami.coubase_ubuntu_example_replica.id : var.ami_id_replica
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY PRIMARY COUCHBASE IN THE DEFAULT VPC AND SUBNETS
# Using the default VPC and subnets makes this example easy to run and test, but it means Couchbase is accessible from
# the public Internet. For a production deployment, we strongly recommend deploying into a custom VPC with private
# subnets.
# ---------------------------------------------------------------------------------------------------------------------

data "aws_vpc" "default_primary" {
  default = true

  provider = aws.primary
}

data "aws_subnet_ids" "default_primary" {
  vpc_id = data.aws_vpc.default_primary.id

  provider = aws.primary
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY REPLICA COUCHBASE IN THE DEFAULT VPC AND SUBNETS
# Using the default VPC and subnets makes this example easy to run and test, but it means Couchbase is accessible from
# the public Internet. For a production deployment, we strongly recommend deploying into a custom VPC with private
# subnets.
# ---------------------------------------------------------------------------------------------------------------------

data "aws_vpc" "default_replica" {
  default = true

  provider = aws.replica
}

data "aws_subnet_ids" "default_replica" {
  vpc_id = data.aws_vpc.default_replica.id

  provider = aws.replica
}

data "aws_region" "replica" {
  provider = aws.replica
}

