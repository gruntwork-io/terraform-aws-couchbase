<!--
:type: service
:name: Couchbase
:description: Deploy a Couchbase cluster. Supports automatic bootstrapping, Sync Gateway, Web Console UI, cross-region replication, and auto healing.
:icon: /_docs/couchbase-icon.png
:category: other-data-stores
:cloud: aws
:tags: nosql
:license: open-source
:built-with: terraform, bash
-->

# Couchbase AWS Module

[![Maintained by Gruntwork.io](https://img.shields.io/badge/maintained%20by-gruntwork.io-%235849a6.svg)](https://gruntwork.io/?ref=repo_aws_couchbase)
![Terraform Version](https://img.shields.io/badge/tf-%3E%3D0.15.0-blue.svg)

This repo contains a set of modules for deploying [Couchbase](https://www.couchbase.com/) on 
[AWS](https://aws.amazon.com/) using [Terraform](https://www.terraform.io/) and [Packer](https://www.packer.io/). 
Couchbase is a distributed NoSQL document database. This module supports running Couchbase as a single cluster:

![Couchbase single-cluster architecture](https://github.com/gruntwork-io/terraform-aws-couchbase/blob/master/_docs/couchbase-single-cluster-architecture.png?raw=true)

Or as multiple clusters for the various Couchbase services (data, management, search, index, query) and Sync Gateway:

![Couchbase multi-cluster architecture](https://github.com/gruntwork-io/terraform-aws-couchbase/blob/master/_docs/couchbase-multi-cluster-architecture.png?raw=true)




## Features

* Deploy Couchbase and Sync Gateway.
* Automatic bootstrapping.
* Cross-region replication
* Multi-dimensional scaling, allowing you to separately scale data, management, search, index, query, and Sync 
  Gateway nodes.
* Auto healing.
* Web console UI.




## Learn

This repo is maintained by [Gruntwork](https://www.gruntwork.io), and follows the same patterns as [the Gruntwork
Infrastructure as Code Library](https://gruntwork.io/infrastructure-as-code-library/), a collection of reusable,
battle-tested, production ready infrastructure code. You can read [How to use the Gruntwork Infrastructure as Code
Library](https://gruntwork.io/guides/foundations/how-to-use-gruntwork-infrastructure-as-code-library/) for an overview
of how to use modules maintained by Gruntwork!

### Core concepts

* [Couchbase documentation](https://docs.couchbase.com/home/index.html): The core documentation for Couchbase, inculding
  guides for administrators, developers, SQL developers, and mobile developers.
* [Couchbase tutorials](https://docs.couchbase.com/tutorials/index.html): hands-on guides for getting started with
  Couchbase.
* [Couchbase Security](https://docs.couchbase.com/server/6.0/learn/security/security-overview.html): overview of how to 
  secure your Couchbase clusters.


### Repo organization

Check out [How to use this repo](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/core-concepts.md#how-to-use-this-repo): 
for an overview.

* [modules](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/modules): the main implementation code for this repo, broken down into multiple standalone, orthogonal submodules.
* [examples](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/examples): This folder contains working examples of how to use the submodules.
* [test](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/test): Automated tests for the modules and examples.
* [root](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master): The root folder is *an example* of how to use the submodules to deploy a Couchbase cluster. The Terraform Registry requires the root of every repo to contain Terraform code, so we've put one of the examples there. This example is great for learning and experimenting, but for production use, please use the underlying modules in the [modules folder](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/modules) directly.




## Deploy

### Non-production deployment (quick start for learning)

If you just want to try this repo out for experimenting and learning, check out the following resources:

* [examples folder](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/examples): The `examples` folder contains sample code optimized for learning, experimenting, and testing (but not production usage).
* [quick start](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/core-concepts.md#quick-start): A quick
  start guide for this repo.

### Production deployment

If you want to deploy this repo in production, check out the following resources:

* [Couchbase deployment guidelines](https://docs.couchbase.com/server/6.0/install/install-production-deployment.html):
  A guide on how to configure Couchbase for production. All of these settings are exposed by the modules in the
  `modules` folder. 
* [Security options](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/modules/couchbase-cluster/README.md#security):
  The security options you can configure using these modules.
* [Credentials](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/modules/run-couchbase-server/README.md#passing-credentials-securely):
  How to pass credentials securely to your Couchbase server.
* [Memory settings](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/modules/run-couchbase-server/README.md#memory-settings):
  How to configure memory settings in your Couchbase server.
  



## Manage

### Day-to-day operations

* [How to connect to Sync Gateway](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/modules/couchbase-cluster/README.md#connecting-to-sync-gateway)
* [How to connect to the Couchbase Web Console](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/modules/couchbase-cluster/README.md#connecting-to-the-couchbase-server-web-console)
* [How to connect to the Couchbase Server via SDK](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/modules/couchbase-cluster/README.md#connecting-to-couchbase-server-via-the-sdk)

### Major changes

* [How to upgrade a Couchbase cluster](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/modules/couchbase-cluster/README.md#how-do-you-roll-out-updates)




## Support

If you need help with this repo or anything else related to infrastructure or DevOps, Gruntwork offers [Commercial Support](https://gruntwork.io/support/) via Slack, email, and phone/video. If you're already a Gruntwork customer, hop on Slack and ask away! If not, [subscribe now](https://www.gruntwork.io/pricing/). If you're not sure, feel free to email us at [support@gruntwork.io](mailto:support@gruntwork.io).




## Contributions

Contributions to this repo are very welcome and appreciated! If you find a bug or want to add a new feature or even contribute an entirely new module, we are very happy to accept pull requests, provide feedback, and run your changes through our automated test suite.

Please see [CONTRIBUTING.md](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/CONTRIBUTING.md) for instructions.




## License

Please see [LICENSE](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/LICENSE) for details on how the code in this repo is licensed.


Copyright &copy; 2019 Gruntwork, Inc.