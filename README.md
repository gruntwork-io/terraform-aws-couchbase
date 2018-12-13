[![Maintained by Gruntwork.io](https://img.shields.io/badge/maintained%20by-gruntwork.io-%235849a6.svg)](https://gruntwork.io)
# Couchbase AWS Module

This repo contains a Module for deploying [Couchbase](https://www.couchbase.com/) on [AWS](https://aws.amazon.com/) 
using [Terraform](https://www.terraform.io/) and [Packer](https://www.packer.io/). Couchbase is a distributed NoSQL 
document database. This module supports running Couchbase as a single cluster:

![Couchbase single-cluster architecture](https://github.com/gruntwork-io/terraform-aws-couchbase/blob/master/_docs/couchbase-single-cluster-architecture.png?raw=true)

Or as multiple clusters for the various Couchbase services (data, management, search, index, query) and Sync Gateway:

![Couchbase multi-cluster architecture](https://github.com/gruntwork-io/terraform-aws-couchbase/blob/master/_docs/couchbase-multi-cluster-architecture.png?raw=true)



## Quick start

If you want to quickly spin up a Couchbase cluster, you can run the simple example that is in the root of this repo.
Check out [couchbase-cluster-simple example
documentation](https://github.com/gruntwork-io/terraform-aws-couchbase/blob/master/examples/couchbase-cluster-simple)
for instructions.




## What's in this repo

This repo has the following folder structure:

* [root](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master): The root folder contains an example
  of how to deploy Couchbase as a single-cluster. See 
  [couchbase-cluster-simple](https://github.com/gruntwork-io/terraform-aws-couchbase/blob/master/examples/couchbase-cluster-simple)
  for the documentation.
* [modules](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/modules): This folder contains the 
  main implementation code for this Module, broken down into multiple standalone submodules.
* [examples](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/examples): This folder contains 
  examples of how to use the submodules.
* [test](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/test): Automated tests for the submodules 
  and examples.




## How to use this repo

The general idea is to: 

1. Use the scripts in the
   [install-couchbase-server](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/modules/install-couchbase-server) and
   [install-sync-gateway](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/modules/install-sync-gateway)
   modules to create an AMI with Couchbase and Sync Gateway installed.
   
1. Deploy the AMI across one or more Auto Scaling Groups (ASG) using the [couchbase-cluster
   module](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/modules/couchbase-cluster).   
   
1. Configure each server in the ASGs to execute the 
   [run-couchbase-server](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/modules/run-couchbase-server) and/or
   [run-sync-gateway](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/modules/run-sync-gateway)
   script during boot.

1. (Optional): Deploy a load balancer in front of the ASGs using the [load-balancer 
   module](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/modules/load-balancer).

See the [examples folder](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/examples) for working
sample code.




## What's a Module?

A Module is a canonical, reusable, best-practices definition for how to run a single piece of infrastructure, such 
as a database or server cluster. Each Module is written using a combination of [Terraform](https://www.terraform.io/) 
and scripts (mostly bash) and include automated tests, documentation, and examples. It is maintained both by the open 
source community and companies that provide commercial support. 

Instead of figuring out the details of how to run a piece of infrastructure from scratch, you can reuse 
existing code that has been proven in production. And instead of maintaining all that infrastructure code yourself, 
you can leverage the work of the Module community to pick up infrastructure improvements through
a version number bump.
 
 
 
## Who maintains this Module?

This Module is maintained by [Gruntwork](http://www.gruntwork.io/). If you're looking for help or commercial 
support, send an email to [modules@gruntwork.io](mailto:modules@gruntwork.io?Subject=Couchbase%20for%20AWS%20Module). 
Gruntwork can help with:

* Setup, customization, and support for this Module.
* Modules for other types of infrastructure, such as VPCs, Docker clusters, databases, and continuous integration.
* Modules that meet compliance requirements, such as HIPAA.
* Consulting & Training on AWS, Terraform, and DevOps.




## How do I contribute to this Module?

Contributions are very welcome! Check out the 
[Contribution Guidelines](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/CONTRIBUTING.md) for instructions.



## How is this Module versioned?

This Module follows the principles of [Semantic Versioning](http://semver.org/). You can find each new release, 
along with the changelog, in the [Releases Page](../../releases). 

During initial development, the major version will be 0 (e.g., `0.x.y`), which indicates the code does not yet have a 
stable API. Once we hit `1.0.0`, we will make every effort to maintain a backwards compatible API and use the MAJOR, 
MINOR, and PATCH versions on each release to indicate any incompatibilities. 



## License

This code is released under the Apache 2.0 License. Please see 
[LICENSE](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/LICENSE) and 
[NOTICE](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/NOTICE) for more details.

Copyright &copy; 2018 Gruntwork, Inc.
