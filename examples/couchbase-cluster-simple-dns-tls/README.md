# Couchbase Single Cluster Example

This folder shows an example of Terraform code that uses the 
[couchbase-cluster](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/modules/couchbase-cluster) 
module to deploy a [Couchbase](https://www.couchbase.com/) cluster in [AWS](https://aws.amazon.com/). The cluster 
consists of one Auto Scaling Group (ASG) that runs all Couchbase services and Sync Gateway:

![Couchbase single-cluster architecture](https://github.com/gruntwork-io/terraform-aws-couchbase/blob/master/_docs/couchbase-single-cluster-architecture.png?raw=true)

This example also deploys a Load Balancer in front of the Couchbase cluster, and configures SSL/DNS for it (see [DNS
and SSL](#dns-and-ssl)), using the [load-balancer
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
1. Open `variables.tf`, set the environment variables specified at the top of the file, and fill in any other variables that
   don't have a default. If you built a custom AMI, put its ID into the `ami_id` variable. If you didn't, this example
   will use public AMIs that Gruntwork has published, which are fine for testing/learning, but not recommended for
   production use.
1. Run `terraform init`.
1. Run `terraform apply`.



## Connecting to the cluster

Check out [How do you connect to the Couchbase 
cluster](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/modules/couchbase-cluster#how-do-you-connect-to-the-couchbase-cluster)
documentation. Note that this module uses SSL, so make sure to use `https://` instead of `http://` for all URLs!
To log into the Couchbase Web Console, use the username and password from the `cluster_username`and `cluster_password`
vars in [user-data.sh](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/examples/couchbase-cluster-simple-dns-tls/user-data/user-data.sh).

Note that booting up and rebalancing a Couchbase cluster can take 5 - 10 minutes, depending on the number and types of 
instances. 




## DNS and SSL

This module shows an example of one way you can configure the load balancer to:

1. Have a custom domain name
1. Listen for SSL requests

You must specify the domain name to use via the variable `domain_name`. The assumptions around this domain name are:

1. You've created a [Hosted Zone](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/AboutHZWorkingWith.html)
   in [Route 53](https://aws.amazon.com/route53/) for `domain_name`.

1. You've requested a wildcard SSL certificate for `*.domain_name` using [Amazon Certificate
   Manager](https://aws.amazon.com/certificate-manager/) in the same AWS region (default: `us-east-1`). SSL certs from
   ACM are free and renew automatically!

For example, if `domain_name` is `acme.com`, then this module assumes there is a Route 53 Hosted Zone for `acme.com.`
and an ACM cert for `*.acme.com`. If `cluster_name` is set to `couchbase-example`, after deploying this module, the
load balancer will be accessible at `https://couchbase-example.acme.com:8091` (for Couchbase) and
`https://couchbase-example.acme.com:4984` (for Sync Gateway).
