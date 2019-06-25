# Load Balancer Target Group Module

This module can be used to create a [Target 
Group](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html) and
[Listener Rules](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/listener-update-rules.html) for
a Load Balancer created with the [load-balancer 
module](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/modules/load-balancer). You can use this 
module to configure health checks and routing for Couchbase and Sync Gateway. 

The reason the `load-balancer` and `load-balancer-target-group` modules are separate is that you may wish to create
multiple target groups for a single load balancer.

See the [examples folder](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/examples) for fully
working sample code.




## How do you use this module?

Imagine you've deployed Couchbase and Sync Gateway using the [couchbase-cluster
module](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/modules/couchbase-cluster) and a Load Balancer
using the [load-balancer module](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/modules/load-balancer):    

```hcl
module "couchbase" {
  # TODO: replace <VERSION> with the latest version from the releases page: https://github.com/gruntwork-io/terraform-aws-couchbase/releases
  source = "github.com/gruntwork/terraform-aws-couchbase//modules/couchbase-cluster?ref=<VERSION>"
  
  cluster_name = var.cluster_name
  
  health_check_type = "ELB"
  
  # ... (other params omitted) ...
}

module "load_balancer" {
  # TODO: replace <VERSION> with the latest version from the releases page: https://github.com/gruntwork-io/terraform-aws-couchbase/releases
  source = "github.com/gruntwork/terraform-aws-couchbase//modules/load-balancer?ref=<VERSION>"
  
  name = var.cluster_name

  http_listener_ports = [8091, 4984]

  # ... (other params omitted) ...
}
``` 

Note the following:

* `health_check_type`: This parameter tells the Couchbase cluster to use the load balancer for health checks, rather 
  than the simpler EC2 health checks. This way, a server will be replaced as soon as it stops responding properly to
  requests, rather than only if the EC2 Instance dies completely. 

* `http_listener_ports`: This tells the Load Balancer to listen for HTTP requests on port 8091 and 4984.
  
To create Target Groups and Listener Rules for Couchbase and Sync Gateway, you need to use the
`load-balancer-target-group` module as follows:

```hcl
module "couchbase_target_group" {
  # TODO: replace <VERSION> with the latest version from the releases page: https://github.com/gruntwork-io/terraform-aws-couchbase/releases
  source = "github.com/gruntwork/terraform-aws-couchbase//modules/load-balancer-target-group?ref=<VERSION>"

  target_group_name = "${var.cluster_name}-cb"
  asg_name          = module.couchbase.asg_name
  port              = 8091
  health_check_path = "/ui/index.html"

  listener_arns                   = [module.load_balancer.http_listener_arns[8091]]
  num_listener_arns               = 1
  listener_rule_starting_priority = 100

  # The Couchbase Web Console uses web sockets, so it's best to enable stickiness so each user is routed to the same
  # server
  enable_stickiness = true
    
  # ... See variables.tf for the other parameters you must define for this module
}

module "sync_gateway_target_group" {
  # TODO: replace <VERSION> with the latest version from the releases page: https://github.com/gruntwork-io/terraform-aws-couchbase/releases
  source = "github.com/gruntwork/terraform-aws-couchbase//modules/load-balancer-target-group?ref=<VERSION>"
  
  target_group_name = "${var.cluster_name}-sg"
  asg_name          = module.couchbase.asg_name
  port              = 4985
  health_check_path = "/"

  listener_arns                   = [module.load_balancer.http_listener_arns[4984]]
  num_listener_arns               = 1
  listener_rule_starting_priority = 100

  # ... See variables.tf for the other parameters you must define for this module
}
```

Note the following:

* `asg_name`: Use this param to attach the Target Group to the Auto Scaling Group (ASG) used under the hood in the
  Couchbase and Sync Gateway cluster so that each EC2 Instance automatically registers with the Target Group, goes 
  through health checks, and gets replaced if it is failing health checks. 

* `listener_arns`: Specify the ARN of the HTTP listener from the Load Balancer module. The Couchbase Target Group uses
  Couchbase's port (8091) and the Sync Gateway Target Group uses Sync Gateway's port (4984).
  
   
