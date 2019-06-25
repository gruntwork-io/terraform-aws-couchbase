# Couchbase Server Security Group Rules Module

This folder contains a [Terraform](https://www.terraform.io/) module that defines the Security Group rules used by a 
[Couchbase](https://www.couchbase.com/) cluster to control the traffic that is allowed to go in and out of the cluster. 
These rules are defined in a separate module so that you can add them to any existing Security Group. 

Couchbase uses a large number of ports, and this module allows you to configure all of them, so make to check out the
[Network Configuration documentation](https://developer.couchbase.com/documentation/server/current/install/install-ports.html).



## Quick start

Let's say you want to deploy Couchbase using the [couchbase-cluster 
module](https://github.com/gruntwork-io/terraform-aws-couchbase/blob/master/modules/couchbase-cluster): 

```hcl
module "couchbase_cluster" {
  # TODO: replace <VERSION> with the latest version from the releases page: https://github.com/gruntwork-io/terraform-aws-couchbase/releases
  source = "github.com/gruntwork-io/terraform-aws-couchbase//modules/couchbase-cluster?ref=<VERSION>"

  # ... (other params omitted) ...
}
```

You can attach the Security Group rules to this cluster as follows:

```hcl
module "security_group_rules" {
  # TODO: replace <VERSION> with the latest version from the releases page: https://github.com/gruntwork-io/terraform-aws-couchbase/releases
  source = "github.com/gruntwork-io/terraform-aws-couchbase//modules/couchbase-server-security-group-rules?ref=<VERSION>"

  security_group_id = module.couchbase_cluster.security_group_id
  
  rest_port                 = 8091
  rest_port_cidr_blocks     = ["0.0.0.0/0"]
  rest_port_security_groups = ["sg-abcd1234"]
  
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

* `rest_port`, `rest_port_cidr_blocks`, `rest_port_security_groups`: This shows an example of how to configure which 
  ports you're using for various Couchbase functionality, such as the REST port, and which IP address ranges and 
  Security Groups are allowed to connect to that port. Check out the [Network Configuration 
  documentation](https://developer.couchbase.com/documentation/server/current/install/install-ports.html) to understand
  what ports Couchbase uses.
  
You can find the other parameters in [variables.tf](variables.tf).

Check out the [examples folder](https://github.com/gruntwork-io/terraform-aws-couchbase/blob/master/examples) for 
working sample code.
