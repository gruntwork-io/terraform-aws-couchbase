# Couchbase Server Run Script

This folder contains a script for configuring and running Couchbase on an [AWS](https://aws.amazon.com/) server. This 
script has been tested on the following operating systems:

* Ubuntu 16.04
* Amazon Linux

There is a good chance it will work on other flavors of Debian, CentOS, and RHEL as well.




## Quick start

This script assumes you installed it, plus all of its dependencies (including Couchbase itself), using the 
[install-couchbase-server module](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/modules/install-couchbase-server). 
The default install path is `/opt/couchbase/bin`, so to configure and start Couchbase, you run:

```
/opt/couchbase/bin/run-couchbase-server --server
```

This will:

1. Configure the OS, including swap, pages, and memory settings. 

1. Use EC2 tags to find all the nodes in the cluster.

1. Configure Couchbase using 
   [couchbase-cli](https://developer.couchbase.com/documentation/server/current/cli/cbcli-intro.html), including
   running `cluster-init`, `server-add`, and `rebalance` as necessary.
   
We recommend using the `run-couchbase-server` command as part of [User 
Data](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html#user-data-shell-scripts), so that it executes
when the EC2 Instance is first booting. 

See the [examples folder](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/examples) for 
fully-working sample code.




## Command line Arguments

The `run-couchbase-server` script accepts the following arguments:

* `cluster-tag-key` (required): Automatically form a cluster with Instances that have this tag key and the tag value
  in `--cluster-tag-value`.
* `cluster-tag-value` (required): Automatically form a cluster with Instances that have the tag key in 
  `--cluster-tag-key` and this tag value.

Example:

```
/opt/couchbase/bin/run-couchbase-server --cluster-tag-key couchbase-cluster --cluster-tag-value prod-cluster 
```




### Required permissions

The `run-couchbase-server` script assumes it is running on an EC2 Instance with an [IAM 
Role](http://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles.html) that has the following permissions:

* `ec2:DescribeInstances`
* `ec2:DescribeTags`
* `autoscaling:DescribeAutoScalingGroups`

These permissions are automatically added by the [couchbase-cluster 
module](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/modules/couchbase-cluster).

