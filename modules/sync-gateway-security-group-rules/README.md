# Sync Gateway Security Group Rules Module

This folder contains a [Terraform](https://www.terraform.io/) module that defines the Security Group rules used by 
[Couchbase Sync Gateway](https://developer.couchbase.com/documentation/mobile/current/guides/sync-gateway/index.html) 
to control the traffic that is allowed to go in and out of the Gateway. These rules are defined in a separate module so 
that you can add them to any existing Security Group. 



## Quick start

Let's say you want to deploy Sync Gateway using the [couchbase-cluster 
module](https://github.com/gruntwork-io/terraform-aws-couchbase/blob/master/modules/couchbase-cluster): 

```hcl
module "sync_gateway" {
  # TODO: replace <VERSION> with the latest version from the releases page: https://github.com/gruntwork-io/terraform-aws-couchbase/releases
  source = "github.com/gruntwork-io/terraform-aws-couchbase//modules/couchbase-cluster?ref=<VERSION>"

  # ... (other params omitted) ...
}
```

You can attach the Security Group rules to this cluster as follows:

```hcl
module "security_group_rules" {
  # TODO: replace <VERSION> with the latest version from the releases page: https://github.com/gruntwork-io/terraform-aws-couchbase/releases
  source = "github.com/gruntwork-io/terraform-aws-couchbase//modules/sync-gateway-security-group-rules?ref=<VERSION>"

  security_group_id = module.sync_gateway.security_group_id
  
  interface_port                 = 4984
  interface_port_cidr_blocks     = ["0.0.0.0/0"]
  interface_port_security_groups = ["sg-abcd1234"]
  
  # ... (other params omitted) ...
}
```

Note the following parameters:

* `source`: Use this parameter to specify the URL of this module. The double slash (`//`) is intentional 
  and required. Terraform uses it to specify subfolders within a Git repo (see [module 
  sources](https://www.terraform.io/docs/modules/sources.html)). The `ref` parameter specifies a specific Git tag in 
  this repo. That way, instead of using the latest version of this module from the `master` branch, which 
  will change every time you run Terraform, you're using a fixed version of the repo.

* `security_group_id`: Use this parameter to specify the ID of the security group to which the rules in this module
  should be added.

* `interface_port`, `interface_port_cidr_blocks`, `interface_port_security_groups`: This shows an example of how to 
  configure which ports you're using for various Sync Gateway functionality, such as the interface port, and which IP 
  address ranges and Security Groups are allowed to connect to that port. 
  
You can find the other parameters in [variables.tf](variables.tf).

Check out the [examples folder](https://github.com/gruntwork-io/terraform-aws-couchbase/blob/master/examples) for 
working sample code.

