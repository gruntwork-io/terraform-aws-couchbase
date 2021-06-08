# Sync Gateway Install Script

This folder contains a script for installing Couchbase Sync Gateway and its dependencies. Use this script along with the
[run-sync-gateway script](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/modules/run-sync-gateway) 
to create a Sync Gateway [Amazon Machine Image 
(AMI)](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html) that can be deployed in 
[AWS](https://aws.amazon.com/) across an Auto Scaling Group using the [couchbase-cluster 
module](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/modules/couchbase-cluster).

This script has been tested on the following operating systems:

* Ubuntu 20.04
* Ubuntu 18.04
* Amazon Linux 2

There is a good chance it will work on other flavors of Debian, CentOS, and RHEL as well.



## Quick start

This module depends on [bash-commons](https://github.com/gruntwork-io/bash-commons), so you must install that project
first as documented in its README.

To install Sync Gateway, use `git` to clone this repository at a specific tag (see the [releases 
page](https://github.com/gruntwork-io/terraform-aws-couchbase/releases) for all available tags) and run the 
`install-sync-gateway` script:

```
git clone --branch <VERSION> https://github.com/gruntwork-io/terraform-aws-couchbase.git
terraform-aws-couchbase/modules/install-couchbase-server/install-sync-gateway --version <VERSION>
```

The `install-sync-gateway` script will install Sync Gateway, its dependencies, and the [run-sync-gateway 
script](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/modules/run-sync-gateway).
You can execute the `run-sync-gateway` script when the server is booting to start Sync Gateway and configure it to 
automatically join other nodes to form a cluster.

We recommend running the `install-sync-gateway` script as part of a [Packer](https://www.packer.io/) template to 
create a Sync Gateway [Amazon Machine Image (AMI)](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html) (see the 
[couchbase-ami example](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/examples/couchbase-ami) for 
fully-working sample code). You can then deploy the AMI across an Auto Scaling Group using the [couchbase-cluster 
module](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/modules/couchbase-cluster) (see the 
[examples folder](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/examples) for fully-working 
sample code).




## Command line Arguments

Run `install-sync-gateway --help` to see all available arguments.

```
Usage: install-sync-gateway [options]

This script can be used to install Couchbase Sync Gateway and its dependencies. This script has been tested with Ubuntu 20.04/18.04 and Amazon Linux 2.

Options:

  --edition		The edition of Sync Gateway to install. Must be one of: enterprise, community. Default: enterprise.
  --version		The version of Sync Gateway to install. Default: 2.0.0-beta2.
  --checksum		The checksum of the Sync Gateway package. Required if --version is specified. You can get it from the downloads page of the Couchbase website.
  --checksum-type	The type of checksum in --checksum. Required if --version is specified. Must be one of: sha256, md5.
  --config		Configure Sync Gateway to use the specified JSON config file.

Example:

  install-sync-gateway --edition enterprise --config my-custom-config.json
```



## How it works

The `install-sync-gateway` script does the following:

1. [Install Sync Gateway binaries and scripts](#install-sync-gateway-binaries-and-scripts)


### Install Sync Gateway binaries and scripts

Install the following:

* `Sync Gateway`: Install Sync Gateway using the appropriate [Linux 
  installer](https://developer.couchbase.com/documentation/mobile/1.5/installation/sync-gateway/index.html). 
* `run-sync-gateway`: Copy the [run-sync-gateway 
  script](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/modules/run-sync-gateway) into 
  `/opt/couchbase/bin`. 




## Why use Git to install this code?

We needed an easy way to install these scripts that satisfied a number of requirements, including working on a variety 
of operating systems and supported versioning. Our current solution is to use `git`, but this may change in the future.
See [Package Managers](https://github.com/hashicorp/terraform-aws-consul/blob/master/_docs/package-managers.md) 
for a full discussion of the requirements, trade-offs, and why we picked `git`.
