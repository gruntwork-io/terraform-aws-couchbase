# Couchbase Single Cluster Example

The root folder of this repo shows an example of Terraform code that uses the
[couchbase-cluster](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/modules/couchbase-cluster) 
module to deploy a [Couchbase](https://www.couchbase.com/) cluster in [AWS](https://aws.amazon.com/). The cluster 
consists of one Auto Scaling Group (ASG) that runs all Couchbase services and Sync Gateway:

![Couchbase single-cluster architecture](https://github.com/gruntwork-io/terraform-aws-couchbase/blob/master/_docs/couchbase-single-cluster-architecture.png?raw=true)

This example also deploys a Load Balancer in front of the Couchbase cluster using the [load-balancer
module](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/modules/load-balancer).

You will need to create an [Amazon Machine Image (AMI)](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html) 
that has Couchbase installed, which you can do using the [couchbase-ami 
example](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/examples/couchbase-ami)). 

To see an example of the Couchbase services and Sync Gateway deployed in separate clusters, see the [couchbase-cluster-mds
example](https://github.com/gruntwork-io/terraform-aws-couchbase/blob/master/examples/couchbase-cluster-mds). For
more info on how the Couchbase cluster works, check out the 
[couchbase-cluster](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/modules/couchbase-cluster) documentation.



## Quick start

To deploy a Couchbase Cluster:

1. `git clone` this repo to your computer.
1. Optional: build a custom Couchbase AMI. See the
   [couchbase-ami example](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/examples/couchbase-ami)
   documentation for instructions. Make sure to note down the ID of the AMI.
1. Install [Terraform](https://www.terraform.io/).
1. Open the `variables.tf` file in the root of this repo, set the environment variables specified at the top of the
   file, and fill in any other variables that don't have a default. If you built a custom AMI, put its ID into the
   `ami_id` variable. If you didn't, this example will use public AMIs that Gruntwork has published, which are fine for
   testing/learning, but not recommended for production use.
1. Run `terraform init` in the root folder of this repo.
1. Run `terraform apply` in the root folder of this repo.



## Connecting to the cluster

Check out [How do you connect to the Couchbase 
cluster](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/modules/couchbase-cluster#how-do-you-connect-to-the-couchbase-cluster)
documentation. To log into the Couchbase Web Console, use the username and password from the `cluster_username`
and `cluster_password` vars in
[user-data.sh](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/examples/couchbase-cluster-simple/user-data/user-data.sh).

Note that booting up and rebalancing a Couchbase cluster can take 5 - 10 minutes, depending on the number and types of 
instances. 
