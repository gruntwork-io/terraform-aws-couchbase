# Couchbase Single Cluster Example

This folder shows an example of Terraform code that uses the 
[couchbase-cluster](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/modules/couchbase-cluster) 
module to deploy a [Couchbase](https://www.couchbase.com/) cluster in [AWS](https://aws.amazon.com/). The cluster 
consists of one Auto Scaling Group (ASG) that runs all Couchbase services and Sync Gateway:

![Couchbase single-cluster architecture](https://github.com/gruntwork-io/terraform-aws-couchbase/blob/master/_docs/couchbase-single-cluster-architecture.png?raw=true)

We've also deployed two Load Balancers using the [load-balancer 
module](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/modules/load-balancer), one for Couchbase, 
one for Sync Gateway.

You will need to create an [Amazon Machine Image (AMI)](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html) 
that has Couchbase installed, which you can do using the [couchbase-ami 
example](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/examples/couchbase-ami)). 

To see an example of the Couchbase services and Sync Gateway deployed in separate clusters, see the [couchbase-multi-cluster
example](https://github.com/gruntwork-io/terraform-aws-couchbase/blob/master/examples/couchbase-multi-cluster). For 
more info on how the Couchbase cluster works, check out the 
[couchbase-cluster](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/modules/couchbase-cluster) documentation.



## Quick start

To deploy a Couchbase Cluster:

1. `git clone` this repo to your computer.
1. Build a Couchbase AMI. See the [couchbase-ami example](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/examples/couchbase-ami) 
   documentation for instructions. Make sure to note down the ID of the AMI.
1. Install [Terraform](https://www.terraform.io/).
1. Open `vars.tf`, set the environment variables specified at the top of the file, and fill in any other variables that
   don't have a default, including putting your AMI ID into the `ami_id` variable.
1. Run `terraform init`.
1. Run `terraform apply`.




## Connecting to the cluster

Check out [How do you connect to the Couchbase 
cluster](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/modules/couchbase-cluster#how-do-you-connect-to-the-couchbase-cluster)
documentation.

Note that booting up and rebalancing a Couchbase cluster can take 5 - 10 minutes, depending on the number and types of 
instances. 
