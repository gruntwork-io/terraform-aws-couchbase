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
1. Build a Couchbase AMI for the two regions specified in `vars.tf`: `aws_region_primary` and `aws_region_replica`:

    ```
    packer build -var aws_region=us-east-1 -only=ubuntu-ami couchbase.json
    packer build -var aws_region=us-west-1 -only=ubuntu-ami couchbase.json
    ```

    See the [couchbase-ami example](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/examples/couchbase-ami)
    documentation for instructions. Make sure to note down the ID of the AMIs.
1. Install [Terraform](https://www.terraform.io/).
1. Open `vars.tf`, set the environment variables specified at the top of the file, and fill in any other variables that
   don't have a default, including putting your AMI IDs into the `ami_id_primary` and `ami_id_replica` variables.
1. Run `terraform init`.
1. Run `terraform apply`.

