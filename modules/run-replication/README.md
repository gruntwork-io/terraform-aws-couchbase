# Couchbase Run Replication Script

This folder contains a script for kicking off replication of a bucket between two Couchbase clusters. This will add
the destination cluster as a remote endpoint using the `couchbase-cli xdcr-setup` command and start replication of
the specified bucket using the `couchbase-cli xdcr-replicate` command. This script is idempotent, so you can run it
multiple times with different buckets.

This script has been tested on the following operating systems:

* Ubuntu 20.04
* Ubuntu 18.04
* Amazon Linux 2

There is a good chance it will work on other flavors of Debian, CentOS, and RHEL as well.




## Quick start

This script assumes you installed it, plus all of its dependencies (including Couchbase itself), using the
[install-couchbase-server module](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/modules/install-couchbase-server).
The default install path is `/opt/couchbase/bin`, so to kick off replication, you can run:

```
/opt/couchbase/bin/run-replication
  --src-cluster-username admin \
  --src-cluster-password password \
  --src-cluster-bucket-name bucket \
  --dest-cluster-name dest \
  --dest-cluster-hostname 1.2.3.4 \
  --dest-cluster-username admin \
  --dest-cluster-password password \
  --dest-cluster-bucket-name bucket-replica \
  --setup-arg xdcr-encryption-type=half \
  --replicate-arg enable-compression=1
```

This will:

1. Wait for the `src` and `dest` clusters to initialize.

1. Wait for the `src` and `dest` buckets to be created.

1. Create a replication cluster reference called `dest`, if it doesn't already exist.

1. Kick of replication between bucket `bucket` in the `src` clsuter and bucket `bucket-replica` in the `dest` cluster,
   if that replication doesn't already exist.

We recommend using the `run-replication` command as part of [User
Data](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html#user-data-shell-scripts), so that it executes
when the EC2 Instance is first booting.

See the [examples folder](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/examples) for
fully-working sample code.




## Command line Arguments

Run `run-replication --help` to see all available arguments.

```
Usage: run-replication [options]

Kick off replication of a bucket between two Couchbase clusters. This will add the destination cluster as a remote endpoint using the couchbase-cli xdcr-setup command and start replication of the specified bucket using the couchbase-cli xdcr-replicate command. This script is idempotent, so you can run it multiple times with different buckets. This script has been tested with Ubuntu 20.04/18.04 and Amazon Linux 2.

Options:

  --src-cluster-hostname		The hostname of the source Couchbase cluster. Default: localhost.
  --src-cluster-username		The username of the Couchbase cluster to replicate from.
  --src-cluster-password		The password of the Couchbase cluster to replicate from.
  --src-cluster-bucket-name		The name of the bucket to replicate from.

  --dest-cluster-name			The name of the Couchbase cluster to replicate to.
  --dest-cluster-hostname		The hostname of the Couchbase cluster to replicate to.
  --dest-cluster-username		The username of the Couchbase cluster to replicate to.
  --dest-cluster-password		The password of the Couchbase cluster to replicate to.
  --dest-cluster-bucket-name		The name of the bucket to replicate to.

  --setup-arg KEY=VALUE			Pass --KEY=VALUE through to the couchbase-cli xdcr-setup command. May be specified multiple times.
  --replicate-arg KEY=VALUE		Pass --KEY=VALUE through to the couchbase-cli xdcr-replicate command. May be specified multiple times.

  --help				Show this help text and exit.

Example:

  run-replication \
    --src-cluster-username admin \
    --src-cluster-password password \
    --src-cluster-bucket-name bucket \
    --dest-cluster-name dest \
    --dest-cluster-hostname 1.2.3.4 \
    --dest-cluster-username admin \
    --dest-cluster-password password \
    --dest-cluster-bucket-name bucket-replica \
    --setup-arg xdcr-encryption-type=half \
    --replicate-arg enable-compression=1
```
