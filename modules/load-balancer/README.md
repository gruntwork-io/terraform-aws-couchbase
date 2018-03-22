# Load Balancer

This folder contains a [Terraform](https://www.terraform.io/) module that can be used to deploy an [Application Load 
Balancer (ALB)](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/introduction.html) in front of 
your Couchbase and/or Sync Gateway cluster to:

1. Perform health checks on the servers in the cluster and automatically replace them when they fail.
1. Distribute traffic across multiple Sync Gateway nodes. Note that you should NOT use a load balancer to distribute 
   traffic across Couchbase nodes (see [the Couchbase FAQ](https://blog.couchbase.com/couchbase-101-q-and-a/)
   for more info).  




## How do you use this module?

This folder defines a [Terraform module](https://www.terraform.io/docs/modules/usage.html), which you can use in your
code by adding a `module` configuration and setting its `source` parameter to URL of this folder:

```hcl
module "load_balancer" {
  # TODO: replace <VERSION> with the latest version from the releases page: https://github.com/gruntwork-io/terraform-aws-couchbase/releases
  source = "github.com/gruntwork/terraform-aws-couchbase//modules/load-balancer?ref=<VERSION>"
  
    name = "example-load-balancer"
  
    allow_http_inbound_from_cidr_blocks = ["0.0.0.0/0"]

  # ... See vars.tf for the other parameters you must define for the vault-cluster module
}

# Create a Couchbase cluster
module "couchbase" {
  # TODO: replace <VERSION> with the latest version from the releases page: https://github.com/gruntwork-io/terraform-aws-couchbase/releases
  source = "github.com/gruntwork/terraform-aws-couchbase//modules/couchbase-cluster?ref=<VERSION>"

  health_check_type = "ELB"
  # ... (other params omitted) ...
}

resource "aws_autoscaling_attachment" "couchbase_server" {
  autoscaling_group_name = "${module.couchbase.asg_name}"
  alb_target_group_arn   = "${module.load_balancer.couchbase_server_target_group_arn}"
}

resource "aws_autoscaling_attachment" "sync_gateway" {
  autoscaling_group_name = "${module.couchbase.asg_name}"
  alb_target_group_arn   = "${module.load_balancer.sync_gateway_target_group_arn}"
}
```

Note the following:

* `source`: Use this parameter in the `module` to specify the URL of the load-balancer module. The double slash (`//`) 
  is intentional and required. Terraform uses it to specify subfolders within a Git repo (see [module 
  sources](https://www.terraform.io/docs/modules/sources.html)). The `ref` parameter specifies a specific Git tag in 
  this repo. That way, instead of using the latest version of this module from the `master` branch, which 
  will change every time you run Terraform, you're using a fixed version of the repo.

* `allow_http_inbound_from_cidr_blocks`: Use this variable to specify which IP address ranges can connect to the Load
  Balancer. You can also use `allow_http_inbound_from_security_groups` to allow specific security groups to connect.

* `health_check_type`: This parameter tells the Couchbase cluster to use the load balancer for health checks, rather 
  than the simpler EC2 health checks. This way, a server will be replaced as soon as it stops responding properly to
  requests, rather than only if the EC2 Instance dies completely. 

* `aws_autoscaling_attachment`: Use this resource to attach the Auto Scaling Group used in your Couchbase cluster to
  the Target Groups in the Load Balancer. This way, every time a new server boots in the cluster, it will automatically 
  register with the appropriate Target Group and begin doing health checks. Note that there are two Target Groups, 
  one for Couchbase Servers (`couchbase_server_target_group_arn`) and one for Sync Gateway 
  (`sync_gateway_target_group_arn`).

You can find the other parameters in [vars.tf](vars.tf).

Check out the [examples folder](https://github.com/gruntwork/terraform-aws-couchbase/tree/master/examples) for working 
sample code.




## How is the ALB configured?

The ALB in this module is configured as follows:

1. **Listeners**: If the `include_http_listener` parameter is true (default: `true`), the Load Balancer will listen on 
   the default HTTP port 80 (configurable via the `http_port` parameter). If the `include_https_listener` parameter is 
   true (default: `false`) the Load Balancer will listen on the default HTTPS port 443 (configurable via the `https_port` 
   parameter).

1. **TLS certificates**: If the `include_https_listener` parameter is true, you must specify a TLS certificate to use
   via the `certificate_arn` parameter. This must be the ARN of a certificate in 
   [ACM](https://aws.amazon.com/certificate-manager/) or 
   [IAM](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_server-certs.html).
   
1. **Target Groups**: If the `include_couchbase_server_target_group` parameter is true (default: `true`), this module
   will create a Target Group and health checks for your Couchbase Servers. Note that we do not create any Listener
   Rules (routes) for Couchbase, as we do NOT recommend talking to Couchbase Servers via a load balancer (see [the 
   Couchbase FAQ](https://blog.couchbase.com/couchbase-101-q-and-a/) for more info). If the 
   `include_sync_gateway_target_group` parameter is true (default: `true`), this module will create a Target Group,
   health checks, and Listener Rules for your Sync Gateway.
 
1. **Health Checks**: The Target Groups will perform health checks on Couchbase and/or Sync Gateway and only route
   traffic to healthy servers. If you configure your Auto Scaling Group to use ELB health checks by setting
   `health_check_type = "ELB"` in the [couchbase-cluster 
   module](https://github.com/gruntwork/terraform-aws-couchbase/tree/master/modules/couchbase-cluster), then
   servers that fail health checks will be replaced automatically.
   
1. **DNS**: If you set the `create_dns_entry` variable to `true`, this module will create a DNS A Record in [Route 
   53](https://aws.amazon.com/route53/) that points your specified `domain_name` at the ALB. This allows you to use
   this domain name to access Sync Gateway. Note that the TLS certificate you use with the HTTPS listener should be 
   configured with this same domain name!