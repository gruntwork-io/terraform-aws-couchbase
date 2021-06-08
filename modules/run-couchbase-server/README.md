# Couchbase Server Run Script

This folder contains a script for configuring and initializing Couchbase on an [AWS](https://aws.amazon.com/) server. 
This script has been tested on the following operating systems:

* Ubuntu 20.04
* Ubuntu 18.04
* Amazon Linux 2

There is a good chance it will work on other flavors of Debian, CentOS, and RHEL as well.




## Quick start

This script assumes you installed it, plus all of its dependencies (including Couchbase itself), using the 
[install-couchbase-server module](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/modules/install-couchbase-server). 
The default install path is `/opt/couchbase/bin`, so to configure and start Couchbase, you run:

```
/opt/couchbase/bin/run-couchbase-server --cluster-username <USERNAME> --cluser-password <PASSWORD>
```

This will:

1. Figure out a rally point for your Couchbase cluster. This is a "leader" node that will be responsible for 
   initializing the cluster and/or replication. See [Picking a rally point](#picking-a-rally-point) for more info.

1. Configure ports.

1. Start Couchbase on the local node.
   
1. On the rally point, initialize the cluster, including configuring which services to run, credentials, and memory 
   settings.

1. On all other nodes, join the existing cluster.

We recommend using the `run-couchbase-server` command as part of [User 
Data](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html#user-data-shell-scripts), so that it executes
when the EC2 Instance is first booting. 

See the [examples folder](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/examples) for 
fully-working sample code.




## Command line Arguments

Run `run-couchbase-server --help` to see all available arguments.

```
Usage: run-couchbase-server [options]

This script can be used to configure and initialize a Couchbase Server. This script has been tested with Ubuntu 20.04/18.04 and Amazon Linux 2.

Required arguments:

  --cluster-username		The username for the Couchbase cluster.
  --cluster-password		The password for the Couchbase cluster.

Important optional arguments:

  --node-services		Comma-separated list of Couchbase services to run on this node. Default: data,index,query,fts.
  --cluster-services		Comma-separated list of Couchbase services you plan to run in this cluster. Only used when initializing a new cluster. Default: data,index,query,fts.
  --cluster-name		The name of the Couchbase cluster. Must be the name of an Auto Scaling Group (ASG). Default: use the name of the ASG this node is in.
  --hostname			The hostname to use for this node. Default: look up the node's private hostname in EC2 metadata.
  --use-public-hostname		If this flag is set, use the node's public hostname from EC2 metadata.
  --rally-point-hostname	The hostname of the rally point server that initialized the cluster. If not set, automatically pick a rally point server in the ASG.
  --data-dir			The path to store data files create by the Couchbase data service. Default: /opt/couchbase/var/lib/couchbase/data.
  --index-dir			The path to store files create by the Couchbase index service. Default: /opt/couchbase/var/lib/couchbase/data.

Optional port settings:

  --rest-port			The port to use for the Couchbase Web Console and REST/HTTP API. Default: 8091.
  --capi-port			The port to use for Views and XDCR access. Default: 8092.
  --query-port			The port to use for the Query service REST/HTTP traffic. Default: 8093.
  --fts-port			The port to use for the Search service REST/HTTP traffic. Default: 8094.
  --memcached-port		The port to use for the Data service. Default: 11210.
  --xdcr-port			The port to use for the XDCR REST traffic. Default: 9998.

Other optional arguments:

  --index-storage-setting	The index storage mode for the index service. Must be one of: default, memopt. Default: default.
  --manage-memory-manually	If this flag is set, you can set memory settings manually via the --data-ramsize, --fts-ramsize, and --index-ramsize arguments.
  --data-ramsize		The data service memory quota in MB. Only used when initializing a new cluster and if --manage-memory-manually is set.
  --index-ramsize		The index service memory quota in MB. Only used when initializing a new cluster and if --manage-memory-manually is set.
  --fts-ramsize			The full-text service memory quota in MB. Only used when initializing a new cluster and if --manage-memory-manually is set.
  --wait-for-all-nodes		If this flag is set, this script will wait until all servers in the Couchbase Cluster are added and running.
  --help			Show this help text and exit.

Example:

  run-couchbase-server --cluster-username admin --cluser-password password
```




## Picking a rally point

The Couchbase cluster needs a "rally point", which is a single server that is responsible for:

1. Initializing the cluster.
1. Kicking off cross-data-center replication (if you're using it).

We need a way to unambiguously and reliably select exactly one rally point. If there's more than one node, you may end
up with multiple separate clusters instead of just one!

The `run-couchbase-server` script can automatically pick a rally point automatically by:

1. Looking up all the servers in the Auto Scaling Group specified via the `--cluster-name` parameter. If the parameter
   is not specified, the name of the Auto Scaling Group in which `run-couchbase-server` is running is used.

1. Pick the node with the oldest Launch Time as the rally point. If multiple nodes have identical launch times, use the
   one with the earliest Instance ID, alphabetically.
   
If you wish to specify a rally point manually instead of relying on this automatic process, use the 
`--rally-point-hostname` parameter.




## Running multiple Auto Scaling Groups

The recommended deployment pattern for production is to run each Couchbase service (data, index, fts, query) and Sync
Gateway in separate Auto Scaling Groups (ASGs). To ensure that all of these ASGs form a single Couchbase cluster, you 
should:

1. Pick one ASG as the one that will contain the rally point (see [Picking a rally point](#picking-a-rally-point)). 
   Typically, this will be the ASG with the data nodes.  

1. When executing the `run-couchbase-server` script, set the `--cluster-name` parameter on all nodes to the name of 
   the ASG you picked in step (1).    

1. When executing `run-sync-gateway` script, set `ASG_NAME` in the `--auto-fill-asg KEY=ASG_NAME` parameter to the name
   of the ASG you picked in step (1).
   
   
   


## Passing credentials securely

The `run-couchbase-server` requires that you pass in your cluster username and password. You should make sure to never 
store these credentials in plaintext! You should use a secrets management tool to store the credentials in an encrypted
format and only decrypt them, in memory, just before calling `run-couchbase-server`. Here are some tools to consider:

* [Vault](https://www.vaultproject.io/)
* [Keywhiz](https://square.github.io/keywhiz/)
* [KMS](https://aws.amazon.com/kms/)

Moreover, if you're ever calling `run-couchbase-server` interactively (i.e., you're manually running CLI commands
rather than executing a script), be careful of passing credentials directly on the command line, or they will be 
stored, in plaintext, [in Bash 
history](https://www.digitalocean.com/community/tutorials/how-to-use-bash-history-commands-and-expansions-on-a-linux-vps)!
You can either use a CLI tool to set the credentials as environment variables or you can [temporarily disable Bash
history](https://linuxconfig.org/how-to-disable-bash-shell-commands-history-on-linux). 




## Required permissions

The `run-couchbase-server` script assumes it is running on an EC2 Instance with an [IAM 
Role](http://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles.html) that has the following permissions:

* `ec2:DescribeInstances`
* `ec2:DescribeTags`
* `autoscaling:DescribeAutoScalingGroups`

These permissions are automatically added by the [couchbase-cluster 
module](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/modules/couchbase-cluster).




## Memory settings

By default, the `run-couchbase-server` script uses a simple formula to automatically determine memory quotas for the
data, index, and search services:

* The total memory available to couchbase is 65% of the RAM on the current node.
* If you are only running a single service on this node, give that service 100% of the available memory.
* If you are running all three services, give data 50%, index 25%, and search 25%.
* If you are running data and one other service, give data 65% and the other service 35%.
* If you are running index and search, give each 50%.
* Ensure no service is allocated less than 256MB.

You can override this simple calculation by setting the `--manage-memory-manually` flag and specifying the amount of 
memory, in MB, for each service you plan on running using the `--data-ramsize`, `--index-ramsize`, and `--fts-ramsize`
parameters. Example:

```bash
run-couchbase-server \ 
  --cluster-username admin \
  --cluster-password password \
  --manage-memory-manually \
  --data-ramsize 2048 \
  --index-ramsize 1024 \
  --fts-ramsize 1024
```

For more info, see [Sizing Couchbase Server
Resources](https://developer.couchbase.com/documentation/server/current/install/sizing-general.html).




## Debugging tips and tricks

Some tips and tricks for debugging issues with your Couchbase cluster:

* Use [sdk-doctor](https://github.com/couchbaselabs/sdk-doctor) to diagnose connection issues. 
* When using Couchbase SDK tools, set `LCB_LOGLEVEL=5` to get more logging output from Couchbase clients.
* Log file locations: https://developer.couchbase.com/documentation/server/3.x/admin/Misc/Trbl-logs.html.
* Use `systemctl status couchbase-server` to see if systemd thinks the Couchbase process is running.