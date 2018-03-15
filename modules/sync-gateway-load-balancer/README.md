# Sync Gateway Load Balancer

This folder contains a [Terraform](https://www.terraform.io/) module that can be used to deploy an [Application Load 
Balancer (ALB)](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/introduction.html) in front of Sync
Gateway. You can deploy Sync Gateway using the 
[install-sync-gateway](https://github.com/gruntwork/terraform-aws-couchbase/tree/master/modules/install-sync-gateway) and 
[couchbase-cluster](https://github.com/gruntwork/terraform-aws-couchbase/tree/master/modules/couchbase-cluster) modules. 



## How do you use this module?

This folder defines a [Terraform module](https://www.terraform.io/docs/modules/usage.html), which you can use in your
code by adding a `module` configuration and setting its `source` parameter to URL of this folder:

```hcl
module "sync_gateway_elb" {
  # TODO: replace <VERSION> with the latest version from the releases page: https://github.com/gruntwork-io/terraform-aws-couchbase/releases
  source = "github.com/gruntwork/terraform-aws-couchbase//modules/sync-gateway-load-balancer?ref=<VERSION>"
  
  # ... See vars.tf for the other parameters you must define for the vault-cluster module
}

# Configure Sync Gateway to use the load balancer
module "sync_gateway_cluster" {
  # TODO: replace <VERSION> with the latest version from the releases page: https://github.com/gruntwork-io/terraform-aws-couchbase/releases
  source = "github.com/gruntwork/terraform-aws-couchbase//modules/couchbase-cluster?ref=<VERSION>"

  load_balancers = ["${module.sync_gateway_elb.load_balancer_name}"]

  # ... (other params omitted) ...
}
```

Note the following parameters:

* `source`: Use this parameter to specify the URL of the sync-gateway-load-balancer module. The double slash (`//`) is 
  intentional and required. Terraform uses it to specify subfolders within a Git repo (see [module 
  sources](https://www.terraform.io/docs/modules/sources.html)). The `ref` parameter specifies a specific Git tag in 
  this repo. That way, instead of using the latest version of this module from the `master` branch, which 
  will change every time you run Terraform, you're using a fixed version of the repo.

* `load_balancers`: Setting this parameter in the [couchbase-cluster 
  module](https://github.com/gruntwork/terraform-aws-couchbase/tree/master/modules/couchbase-cluster) tells it to 
  register each server with the ALB when it is booting.

You can find the other parameters in [vars.tf](vars.tf).

Check out the [examples folder](https://github.com/gruntwork/terraform-aws-couchbase/tree/master/examples) for working 
sample code.




## How is the ALB configured?

The ALB in this module is configured as follows:

1. **Listeners**: The ALB listens on the default HTTP port (80) and HTTPS port (443).

1. **TLS certificates**: For the HTTPS port, the ALB uses the certificate you specify via the `certificate_arn`
   parameter.
   
1. **Health Check**: The ALB will perform health checks on Sync Gateway and only route traffic to nodes that are
   passing the health checks.
   
1. **DNS**: If you set the `create_dns_entry` variable to `true`, this module will create a DNS A Record in [Route 
   53](https://aws.amazon.com/route53/) that points your specified `domain_name` at the ALB. This allows you to use
   this domain name to access Sync Gateway. Note that the TLS certificate you use with the HTTPS listener should be 
   configured with this same domain name!