# Sync Gateway Run Script

This folder contains a script for configuring and running Sync Gateway on an [AWS](https://aws.amazon.com/) server. This 
script has been tested on the following operating systems:

* Ubuntu 20.04
* Ubuntu 18.04
* Amazon Linux 2

There is a good chance it will work on other flavors of Debian, CentOS, and RHEL as well.




## Quick start

This script assumes you installed it, plus all of its dependencies (including Sync Gateway itself), using the 
[install-sync-gateway module](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/modules/install-sync-gateway). 
As part of the installation process, we recommend that you create a [Sync Gateway JSON config 
file](https://developer.couchbase.com/documentation/mobile/1.5/guides/sync-gateway/config-properties/index.html) and 
install it using the `--config` option of the `install-sync-gateway` script.

You may want some of the configs, such as the IPs of the Couchbase servers, to be filled in dynamically, when the 
server is booting up. You can do this using the `run-sync-gateway` script! Simply leave placeholders in your
Sync Gateway config file like this (see the [couchbase-ami
folder](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/examples/couchbase-ami) for a full example):

```json
{
  "interface": "<:PORT>",
  "databases": {
    "my-db": {
      "server": "<SERVER_IPS>"
    }
  }
}
```  

Now you can fill in those placeholders and start Sync Gateway by executing the `run-sync-gateway` script as follows:

```
/opt/couchbase/bin/run-sync-gateway --auto-fill-asg <SERVER_IPS>=my-couchbase-cluster --auto-fill <PORT>=4984
```

This will:

1. Replace all instances of the text `<SERVER_IPS>` in the Sync Gateway config file with the IPs of the servers in the
   Auto Scaling Group called `my-couchbase-cluster`. The `run-sync-gateway` script will find these IPs automatically 
   using the AWS APIs.

1. Replace all instances of the text `<PORT>` in the Sync Gateway config file with `4984`.

1. Wait for all databases in the Sync Gateway config to initialize.

1. Start Sync Gateway on the local node.

We recommend using the `run-sync-gateway` command as part of [User 
Data](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html#user-data-shell-scripts), so that it executes
when the EC2 Instance is first booting. 

See the [examples folder](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/examples) for 
fully-working sample code.




## Command line Arguments

Run `run-sync-gateway --help` to see all available arguments.

```
Usage: run-sync-gateway [options]

This script can be used to configure and run Couchbase Sync Gateway. This script has been tested with Ubuntu 20.04/18.04 and Amazon Linux 2.

Options:

  --auto-fill-asg KEY=ASG_NAME[:PORT]	Replace KEY in the Sync Gateway config with the IPs (and optional PORT) of servers in the ASG called ASG_NAME. May be repeated.
  --auto-fill KEY=VALUE			Search the Sync Gateway config file for KEY and replace it with VALUE. May be repeated.
  --use-public-hostname			If this flag is set, use the public hostname for each server in --auto-fill. Without this flag, the private hostname will be used.
  --config				The path to a JSON config file for Sync Gateway. Default: /home/sync_gateway/sync_gateway.json.
  --skip-wait				Don't wait for each Couchbase server defined in the config file to be healthy and active and just boot Sync Gateway immediately.
  --help				Show this help text and exit.

Example:

  run-sync-gateway --auto-fill-asg <SERVER_IPS>=my-couchbase-cluster:8091 --auto-fill <PORT>=4984
```




### Required permissions

The `run-sync-gateway` script assumes it is running on an EC2 Instance with an [IAM 
Role](http://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles.html) that has the following permissions:

* `ec2:DescribeInstances`
* `ec2:DescribeTags`
* `autoscaling:DescribeAutoScalingGroups`

These permissions are automatically added by the [couchbase-cluster 
module](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/modules/couchbase-cluster).




## Debugging tips and tricks

Some tips and tricks for debugging issues with your Couchbase cluster:

* Sync Gateway logs can be found at: `/home/sync_gateway/logs/sync`.
* Use `systemctl status sync_gateway` to see if systemd thinks the Couchbase process is running.