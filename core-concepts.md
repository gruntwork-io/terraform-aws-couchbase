# Core concepts

## Quick start

If you want to quickly spin up a Couchbase cluster, you can run the simple example that is in the root of this repo.
Check out [couchbase-cluster-simple example
documentation](https://github.com/gruntwork-io/terraform-aws-couchbase/blob/master/examples/couchbase-cluster-simple)
for instructions.

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
