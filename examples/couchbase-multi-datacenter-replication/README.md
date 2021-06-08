# Couchbase Multi Datacenter Replication Example

This folder shows an example of Terraform code that uses the 
[couchbase-cluster](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/modules/couchbase-cluster) 
module to deploy two [Couchbase](https://www.couchbase.com/) clusters in [AWS](https://aws.amazon.com/), a primary and
a replica, each one in a different region, with the primary replicating one of its buckets to the replica.

![Couchbase multi-datacenter replication architecture](https://github.com/gruntwork-io/terraform-aws-couchbase/blob/master/_docs/couchbase-multi-datacenter-replication-architecture.png?raw=true)

You will need to create an [Amazon Machine Image (AMI)](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html) 
that has Couchbase installed, which you can do using the [couchbase-ami 
example](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/examples/couchbase-ami)). 

For more info on how the Couchbase cluster works, check out the 
[couchbase-cluster](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/modules/couchbase-cluster) documentation.



## Quick start

To deploy a Couchbase Cluster:

1. `git clone` this repo to your computer.
1. Optional: build custom Couchbase AMIs. See the
   [couchbase-ami example](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/examples/couchbase-ami)
   documentation for instructions. Note that you'll need to build one AMI in each of the regions specified in
   `variables.tf`: `aws_region_primary` and `aws_region_replica`:

    ```
    packer build -var aws_region=us-east-1 -only=ubuntu-20-ami couchbase.json
    packer build -var aws_region=us-west-1 -only=ubuntu-20-ami couchbase.json
    ```

1. Install [Terraform](https://www.terraform.io/).
1. Open `variables.tf`, set the environment variables specified at the top of the file, and fill in any other variables that
   don't have a default. If you built custom AMIs, put their IDs into the `ami_id_primary` and `ami_id_replica`
   variables. If you didn't, this example will use public AMIs that Gruntwork has published, which are fine for
   testing/learning, but not recommended for production use.
1. Run `terraform init`.
1. Run `terraform apply`.




## Connecting to the cluster

Check out [How do you connect to the Couchbase
cluster](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/modules/couchbase-cluster#how-do-you-connect-to-the-couchbase-cluster)
documentation. To log into the Couchbase Web Console, use the username and password from the `cluster_username`
and `cluster_password` vars in
[user-data-primary.sh](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/examples/couchbase-multi-datacenter-replication/user-data/user-data-primary.sh).

Note that booting up and rebalancing a Couchbase cluster can take 5 - 10 minutes, depending on the number and types of
instances.
