# Load Balancer Target Group Module

This module can be used to create a [Target 
Group](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html) and
[Listener Rules](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/listener-update-rules.html) for
a Load Balancer created with the [load-balancer 
module](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/modules/load-balancer). You can use this 
module to configure health checks and routing for Couchbase and Sync Gateway. 

The reason the `load-balancer` and `load-balancer-target-group` modules are separate is that you have two ways to 
deploy use a Load Balancer with Couchbase and Sync Gateway:

1. [Run Separate Load Balancers for Couchbase and Sync Gateway](#run-separate-load-balancers-for-couchbase-and-sync-gateway)
1. [Run a Single Load Balancer for both Couchbase and Sync Gateway](#run-a-single-load-balancer-for-both-couchbase-and-sync-gateway)

See the [examples folder](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/examples) for fully 
working sample code.




## Run Separate Load Balancers for Couchbase and Sync Gateway

Using two Load Balancers, one for Couchbase and one for Sync Gateway is the easiest way to get started.

Let's go through an example. Imagine you've deployed Couchbase and Sync Gateway using the [couchbase-cluster
module](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/modules/load-balancer):    

```hcl
module "couchbase" {
  # TODO: replace <VERSION> with the latest version from the releases page: https://github.com/gruntwork-io/terraform-aws-couchbase/releases
  source = "github.com/gruntwork/terraform-aws-couchbase//modules/couchbase-cluster?ref=<VERSION>"
  
  cluster_name = "${var.cluster_name}"
  
  health_check_type = "ELB"
  
  # ... (other params omitted) ...
}
``` 

Note the following:

* `health_check_type`: This parameter tells the Couchbase cluster to use the load balancer for health checks, rather 
  than the simpler EC2 health checks. This way, a server will be replaced as soon as it stops responding properly to
  requests, rather than only if the EC2 Instance dies completely. 

You can create Load Balancers for Couchbase and Sync Gateway using [load-balancer 
module](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/modules/load-balancer):

```hcl
module "couchbase_load_balancer" {
  # TODO: replace <VERSION> with the latest version from the releases page: https://github.com/gruntwork-io/terraform-aws-couchbase/releases
  source = "github.com/gruntwork/terraform-aws-couchbase//modules/load-balancer?ref=<VERSION>"
  
  name = "couchbase-lb"

  # ... (other params omitted) ...
}

module "sync_gateway_load_balancer" {
  # TODO: replace <VERSION> with the latest version from the releases page: https://github.com/gruntwork-io/terraform-aws-couchbase/releases
  source = "github.com/gruntwork/terraform-aws-couchbase//modules/load-balancer?ref=<VERSION>"
  
  name = "sync-gateway-lb"

  # ... (other params omitted) ...
}
```

Finally, you can create Target Groups and Listener Rules for each of these Load Balancers as follows:

```hcl
module "couchbase_target_group" {
  # TODO: replace <VERSION> with the latest version from the releases page: https://github.com/gruntwork-io/terraform-aws-couchbase/releases
  source = "github.com/gruntwork/terraform-aws-couchbase//modules/load-balancer-target-group?ref=<VERSION>"

  target_group_name = "${var.cluster_name}-cb"
  asg_name          = "${module.couchbase.asg_name}"
  port              = 8091
  health_check_path = "/ui/index.html"
  http_listener_arn = "${module.couchbase_load_balancer.http_listener_arn}"
  
  # ... See vars.tf for the other parameters you must define for this module
}

module "sync_gateway_target_group" {
  # TODO: replace <VERSION> with the latest version from the releases page: https://github.com/gruntwork-io/terraform-aws-couchbase/releases
  source = "github.com/gruntwork/terraform-aws-couchbase//modules/load-balancer-target-group?ref=<VERSION>"
  
  target_group_name = "${var.cluster_name}-sg"
  asg_name          = "${module.couchbase.asg_name}"
  port              = 4985
  health_check_path = "/"
  http_listener_arn = "${module.sync_gateway_load_balancer.http_listener_arn}"

  # ... See vars.tf for the other parameters you must define for this module
}
```

Note the following:

* `asg_name`: Use this param to attach the Target Group to the Auto Scaling Group (ASG) used under the hood in the
  Couchbase and Sync Gateway cluster so that each EC2 Instance automatically registers with the Target Group, goes 
  through health checks, and gets replaced if it is failing health checks. 

* `http_listener_arn`: Specify the ARN of the HTTP listener from the Load Balancer module. If you are using an HTTPS
  listener with the Load Balancer module too, you should provide its ARN using the `https_listener_arn` parameter and
  set the `create_https_listener_rule` parameter to `true`.   
  

## Run a Single Load Balancer for both Couchbase and Sync Gateway

Using a single Load Balancer with both Couchbase and Sync Gateway allows you to save some money and have less 
infrastructure to manage. However, both Couchbase and Sync Gateway expect requests across a variety of paths, including
the root (`/`) path, in order to use them with the same Load Balancer, you must:

1. Configure two domain names for that Load Balancer using the `route53_records` parameter of the `load-balancer`
   module.
1. Configure the Listener Rules to route one domain name to the Couchbase Target Group and the other to the Sync 
   Gateway Target Group using the `routing_condition` parameter of this module.
   
Let's go through an example. Imagine you've deployed Couchbase and Sync Gateway using the [couchbase-cluster
module](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/modules/load-balancer) and a Load Balancer
using the [load-balancer module](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/modules/load-balancer):    

```hcl
module "couchbase" {
  # TODO: replace <VERSION> with the latest version from the releases page: https://github.com/gruntwork-io/terraform-aws-couchbase/releases
  source = "github.com/gruntwork/terraform-aws-couchbase//modules/couchbase-cluster?ref=<VERSION>"
  
  cluster_name = "${var.cluster_name}"
  
  health_check_type = "ELB"
  
  # ... (other params omitted) ...
}

module "load_balancer" {
  # TODO: replace <VERSION> with the latest version from the releases page: https://github.com/gruntwork-io/terraform-aws-couchbase/releases
  source = "github.com/gruntwork/terraform-aws-couchbase//modules/load-balancer?ref=<VERSION>"
  
  name = "${var.cluster_name}"

  route53_records = [
    {
      domain  = "couchbase.acme.com"
      zone_id = "Z1234ABCDEFG"
    },
    {
      domain  = "sync-gateway.acme.com"
      zone_id = "Z1234ABCDEFG"
    },
  ]

  # ... (other params omitted) ...
}
``` 

Note the following:

* `health_check_type`: This parameter tells the Couchbase cluster to use the load balancer for health checks, rather 
  than the simpler EC2 health checks. This way, a server will be replaced as soon as it stops responding properly to
  requests, rather than only if the EC2 Instance dies completely. 

* `route53_records`: This creates two DNS A Records in Route 53, one for Couchbase and one for Sync Gateway.  
  
To create Target Groups and Listener Rules for Couchbase and Sync Gateway, you need to use this module as follows:

```hcl
module "couchbase_target_group" {
  # TODO: replace <VERSION> with the latest version from the releases page: https://github.com/gruntwork-io/terraform-aws-couchbase/releases
  source = "github.com/gruntwork/terraform-aws-couchbase//modules/load-balancer-target-group?ref=<VERSION>"

  target_group_name = "${var.cluster_name}-cb"
  asg_name          = "${module.couchbase.asg_name}"
  port              = 8091
  health_check_path = "/ui/index.html"
  http_listener_arn = "${module.load_balancer.http_listener_arn}"
  
  # ... See vars.tf for the other parameters you must define for this module
}

module "sync_gateway_target_group" {
  # TODO: replace <VERSION> with the latest version from the releases page: https://github.com/gruntwork-io/terraform-aws-couchbase/releases
  source = "github.com/gruntwork/terraform-aws-couchbase//modules/load-balancer-target-group?ref=<VERSION>"
  
  target_group_name = "${var.cluster_name}-sg"
  asg_name          = "${module.couchbase.asg_name}"
  port              = 4985
  health_check_path = "/"
  http_listener_arn = "${module.load_balancer.http_listener_arn}"

  # ... See vars.tf for the other parameters you must define for this module
}
```

Note the following:

* `asg_name`: Use this param to attach the Target Group to the Auto Scaling Group (ASG) used under the hood in the
  Couchbase and Sync Gateway cluster so that each EC2 Instance automatically registers with the Target Group, goes 
  through health checks, and gets replaced if it is failing health checks. 

* `http_listener_arn`: Specify the ARN of the HTTP listener from the Load Balancer module. If you are using an HTTPS
  listener with the Load Balancer module too, you should provide its ARN using the `https_listener_arn` parameter and
  set the `create_https_listener_rule` parameter to `true`.   
  
   