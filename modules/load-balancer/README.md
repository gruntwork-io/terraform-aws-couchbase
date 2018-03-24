# Load Balancer

This folder contains a [Terraform](https://www.terraform.io/) module that can be used to deploy an [Application Load 
Balancer (ALB)](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/introduction.html) in front of 
your Couchbase and/or Sync Gateway cluster to:

1. Perform health checks on the servers in the cluster and automatically replace them when they fail.
1. Distribute traffic across Couchbase Server nodes. Note that you should ONLY use the load balancer for the Couchbase
   Web Console and NOT any of the API paths (see [the Couchbase FAQ](https://blog.couchbase.com/couchbase-101-q-and-a/)
   for more info).  
1. Distribute traffic across multiple Sync Gateway nodes. 

Note that this module solely deploys the Load Balancer, as you may want to share one load balancer across multiple
applications. To deploy Target Groups, health checks, and routing rules, use the 
[load-balancer-target-group](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/modules/load-balancer-target-group)
module.

See the [examples folder](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/examples) for fully 
working sample code.




## How do you use this module?

This folder defines a [Terraform module](https://www.terraform.io/docs/modules/usage.html), which you can use in your
code by adding a `module` configuration and setting its `source` parameter to URL of this folder:

```hcl
module "couchbase_load_balancer" {
  # TODO: replace <VERSION> with the latest version from the releases page: https://github.com/gruntwork-io/terraform-aws-couchbase/releases
  source = "github.com/gruntwork/terraform-aws-couchbase//modules/load-balancer?ref=<VERSION>"
  
  name       = "couchbase-load-balancer"
  vpc_id     = "vpc-abcd1234"
  subnet_ids = ["subnet-abcd1234", "subnet-efgh5678"]

  allow_http_inbound_from_cidr_blocks = ["0.0.0.0/0"]

  # ... See vars.tf for the other parameters you must define for this module
}
```

The above code will create a Load Balancer.

Note the following:

* `source`: Use this parameter in the `module` to specify the URL of the load-balancer module. The double slash (`//`) 
  is intentional and required. Terraform uses it to specify subfolders within a Git repo (see [module 
  sources](https://www.terraform.io/docs/modules/sources.html)). The `ref` parameter specifies a specific Git tag in 
  this repo. That way, instead of using the latest version of this module from the `master` branch, which 
  will change every time you run Terraform, you're using a fixed version of the repo.

* `allow_http_inbound_from_cidr_blocks`: Use this variable to specify which IP address ranges can connect to the Load
  Balancer. You can also use `allow_http_inbound_from_security_groups` to allow specific security groups to connect.




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
   
1. **DNS**: You can use the `route53_records` variable to create one more more DNS A Records in [Route 
   53](https://aws.amazon.com/route53/) that point to the Load Balancer. This allows you to use custom domain names to
   access the Load Balancer. Note that the TLS certificate you use with the HTTPS listener must be issued for the 
   same domain name(s)!