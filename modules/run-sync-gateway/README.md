# Sync Gateway Run Script

This folder contains a script for configuring and running Sync Gateway on an [AWS](https://aws.amazon.com/) server. This 
script has been tested on the following operating systems:

* Ubuntu 16.04
* Amazon Linux

There is a good chance it will work on other flavors of Debian, CentOS, and RHEL as well.




## Quick start

This script assumes you installed it, plus all of its dependencies (including Sync Gateway itself), using the 
[install-sync-gateway module](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/modules/install-sync-gateway). 
The default install path is `/opt/couchbase/bin`, so to configure and start Couchbase, you run:

```
/opt/couchbase/bin/run-sync-gateway
```

This will:

1. Use EC2 tags to find all the nodes in the cluster.

1. Fill in the Sync Gateway config file with the details of the discovered Couchbase servers.   
   
We recommend using the `run-sync-gateway` command as part of [User 
Data](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html#user-data-shell-scripts), so that it executes
when the EC2 Instance is first booting. 

See the [examples folder](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/examples) for 
fully-working sample code.




## Command line Arguments

Run `run-sync-gateway --help` to see all available arguments.

```
Usage: run-sync-gateway [options]

This script can be used to configure and run Couchbase Sync Gateway. This script has been tested with Ubuntu 16.04 and Amazon Linux.

Options:

  --auto-fill-asg KEY=ASG_NAME[:PORT]	Replace KEY in the Sync Gateway config with the IPs (and optional PORT) of servers in the ASG called ASG_NAME. May be repeated.
  --auto-fill KEY=VALUE			          Search the Sync Gateway config file for KEY and replace it with VALUE. May be repeated.
  --use-public-hostname			          If this flag is set, use the public hostname for each server in --auto-fill. Without this flag, the private hostname will be used.
  --config				                    The path to a JSON config file for Sync Gateway. Default: /home/sync_gateway/sync_gateway.json.
  --help				                      Show this help text and exit.

Example:

  run-sync-gateway --auto-fill-asg __SERVER_IPS__=my-couchbase-cluster:8091 --auto-fill __PORT__=4984 
```




### Required permissions

The `run-sync-gateway` script assumes it is running on an EC2 Instance with an [IAM 
Role](http://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles.html) that has the following permissions:

* `ec2:DescribeInstances`
* `ec2:DescribeTags`
* `autoscaling:DescribeAutoScalingGroups`

These permissions are automatically added by the [couchbase-cluster 
module](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/modules/couchbase-cluster).

