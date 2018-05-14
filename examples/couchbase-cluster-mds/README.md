# Couchbase Multi Cluster Example

This folder shows an example of Terraform code that uses the 
[couchbase-cluster](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/modules/couchbase-cluster) 
module to deploy a [Couchbase](https://www.couchbase.com/) cluster in [AWS](https://aws.amazon.com/). The cluster 
consists of three Auto Scaling Groups (ASGs): one for data nodes, one for index, query, and search nodes, and one for 
SyncGateway nodes. 

![Couchbase multi-cluster architecture](https://github.com/gruntwork-io/terraform-aws-couchbase/blob/master/_docs/couchbase-multi-cluster-architecture.png?raw=true)

You will need to create an [Amazon Machine Image (AMI)](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html) 
that has Couchbase installed, which you can do using the [couchbase-ami 
example](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/examples/couchbase-ami)). 

To see an example of all the Couchbase services and Sync Gateway deployed in a single cluster, see the [couchbase-cluster-simple
example](https://github.com/gruntwork-io/terraform-aws-couchbase/blob/master/examples/couchbase-cluster-simple). For
more info on how the Couchbase cluster works, check out the 
[couchbase-cluster](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/modules/couchbase-cluster) documentation.



## Quick start

To deploy a Couchbase Cluster:

1. `git clone` this repo to your computer.
1. Optional: build a custom Couchbase AMI. See the
   [couchbase-ami example](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/examples/couchbase-ami)
   documentation for instructions. Make sure to note down the ID of the AMI.
1. Install [Terraform](https://www.terraform.io/).
1. Open `variables.tf`, set the environment variables specified at the top of the file, and fill in any other variables that
   don't have a default. If you built a custom AMI, put its ID into the `ami_id` variable. If you didn't, this example
   will use public AMIs that Gruntwork has published, which are fine for testing/learning, but not recommended for
   production use.
1. Run `terraform init`.
1. Run `terraform apply`.




## Connecting to the cluster

Check out [How do you connect to the Couchbase 
cluster](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/modules/couchbase-cluster#how-do-you-connect-to-the-couchbase-cluster)
documentation. To log into the Couchbase Web Console, use the username and password from the `cluster_username`
and `cluster_password` vars in
[user-data-couchbase-data-nodes.sh](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/examples/couchbase-cluster-mds/user-data/user-data-couchbase-data-nodes.sh).

Note that booting up and rebalancing a Couchbase cluster can take 5 - 10 minutes, depending on the number and types of 
instances.