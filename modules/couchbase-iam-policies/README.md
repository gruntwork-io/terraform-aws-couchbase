# Couchbase IAM Policies

This folder contains a [Terraform](https://www.terraform.io/) module that defines the IAM Policies used by a 
[Couchbase](https://www.couchbase.com/) and/or 
[Sync Gateway](https://developer.couchbase.com/documentation/mobile/current/guides/sync-gateway/index.html) cluster. 
These policies are defined in a separate module so that you can add them to any existing IAM Role. 




## Quick start

Let's say you want to deploy Couchbase using the [couchbase-cluster 
module](https://github.com/gruntwork-io/terraform-aws-couchbase/blob/master/modules/couchbase-cluster): 

```hcl
module "couchbase" {
  # TODO: replace <VERSION> with the latest version from the releases page: https://github.com/gruntwork-io/terraform-aws-couchbase/releases
  source = "github.com/gruntwork-io/terraform-aws-couchbase//modules/couchbase-cluster?ref=<VERSION>"

  # ... (other params omitted) ...
}
```

You can attach the IAM policies to this cluster as follows:

```hcl
module "couchbase_iam_policies" {
  # TODO: replace <VERSION> with the latest version from the releases page: https://github.com/gruntwork-io/terraform-aws-couchbase/releases
  source = "github.com/gruntwork-io/terraform-aws-couchbase//modules/couchbase-iam-policies?ref=<VERSION>"

  iam_role_id = module.couchbase.iam_role_id
}
```

Note the following parameters:

* `source`: Use this parameter to specify the URL of this module. The double slash (`//`) is intentional 
  and required. Terraform uses it to specify subfolders within a Git repo (see [module 
  sources](https://www.terraform.io/docs/modules/sources.html)). The `ref` parameter specifies a specific Git tag in 
  this repo. That way, instead of using the latest version of this module from the `master` branch, which 
  will change every time you run Terraform, you're using a fixed version of the repo.

* `iam_role_id`: Use this parameter to specify the ID of the IAM Role to which the policies in this module
  should be added.

  
You can find the other parameters in [variables.tf](variables.tf).

Check out the [examples folder](https://github.com/gruntwork-io/terraform-aws-couchbase/blob/master/examples) for 
working sample code.
