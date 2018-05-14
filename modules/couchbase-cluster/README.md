# Couchbase Cluster

This folder contains a [Terraform](https://www.terraform.io/) module to deploy a 
[Couchbase](https://www.couchbase.com/) cluster in [AWS](https://aws.amazon.com/) on top of an Auto Scaling Group. 
This module can be used to deploy any or all of the Couchbase services (data, search, index, query) or Sync
Gateway. The idea is to create an [Amazon Machine Image (AMI)](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html)
that has Couchbase and/or Sync Gateway installed using the 
[install-couchbase-server](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/modules/install-couchbase-server) and/or
[install-sync-gateway](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/modules/install-sync-gateway) 
modules.




## How do you use this module?

This folder defines a [Terraform module](https://www.terraform.io/docs/modules/usage.html), which you can use in your
code by adding a `module` configuration and setting its `source` parameter to URL of this folder:

```hcl
module "couchbase_cluster" {
  # TODO: replace <VERSION> with the latest version from the releases page: https://github.com/gruntwork-io/terraform-aws-couchbase/releases
  source = "github.com/gruntwork-io/terraform-aws-couchbase//modules/couchbase-cluster?ref=<VERSION>"

  # Specify the ID of the Couchbase AMI. You should build this using the scripts in the install-couchbase-server and/or 
  # install-sync-gateway modules.
  ami_id = "ami-abcd1234"
  
  # Configure and start Couchbase during boot. 
  user_data = <<-EOF
              #!/bin/bash
              /opt/couchbase/bin/run-couchbase-server --username admin --password password
              EOF
  
  # ... See variables.tf for the other parameters you must define for the couchbase-cluster module
}
```

Note the following parameters:

* `source`: Use this parameter to specify the URL of the couchbase-cluster module. The double slash (`//`) is 
  intentional and required. Terraform uses it to specify subfolders within a Git repo (see [module 
  sources](https://www.terraform.io/docs/modules/sources.html)). The `ref` parameter specifies a specific Git tag in 
  this repo. That way, instead of using the latest version of this module from the `master` branch, which 
  will change every time you run Terraform, you're using a fixed version of the repo.

* `ami_id`: Use this parameter to specify the ID of a Couchbase [Amazon Machine Image 
  (AMI)](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html) to deploy on each server in the cluster. You
  should install Couchbase and/or Sync Gateway in this AMI using the scripts in the 
  [install-couchbase-server](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/modules/install-couchbase-server) and/or
  [install-sync-gateway](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/modules/install-sync-gateway)
  modules.
  
* `user_data`: Use this parameter to specify a [User 
  Data](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html#user-data-shell-scripts) script that each
  server will run during boot. This is where you can use the 
  [run-couchbase-server](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/modules/run-couchbase-server) and/or
  [run-sync-gateway](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/modules/run-sync-gateway)
  scripts to configure and run Couchbase and/or Sync Gateway. 

You can find the other parameters in [variables.tf](variables.tf).

Check out the [examples folder](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/examples) for 
fully-working sample code. 




## How do you connect to the Couchbase cluster?

### Connecting to Sync Gateway

We recommend deploying a load balancer in front of Sync Gateway using the [load-balancer
module](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/examples). If you do that, the module will
output the DNS name of the load balancer, and you can connect to that URL to connect to the Sync Gateway. 

For replication with Couchbase Lite and other external clients, you should connect to the [REST 
API](https://developer.couchbase.com/documentation/mobile/1.5/guides/sync-gateway/rest-api-client/index.html) (default
port 4984). For unrestricted access to the database and administrative tasks, you should connect to the [admin 
UI](https://github.com/couchbaselabs/sync_gateway_admin_ui) (default port 4985, though it's typically only accessible
from localhost, as it provides admin access to everything in the DB!). 


### Connecting to the Couchbase Server Web Console

We recommend deploying a load balancer in front of your Couchbase Servers using the [load-balancer
module](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/examples). If you do that, the module will
output the DNS name of the load balancer, and you can connect to that URL to connect to access the [Couchbase 
Web Console](https://developer.couchbase.com/documentation/server/current/admin/ui-intro.html) at the `/ui` path. 


### Connecting to Couchbase Server via the SDK

Using a Load Balancer to talk to Couchbase APIs (e.g., via an SDK) is NOT recommended (see [the Couchbase 
FAQ](https://blog.couchbase.com/couchbase-101-q-and-a/) for more info), so you will need to get the IPs of the 
individual servers and connect to them directly. Since those servers run in an Auto Scaling Group (ASG) where servers 
can be added/replaced/removed at any time, you can't get their IP addresses from Terraform. Instead, you'll need to look up 
the IPs using the AWS APIs. 

The easiest way to do that is to use the AWS SDK to look up the servers using EC2 Tags. Each server deployed by
the `couchbase-cluster` module has its `Name` and `aws:autoscaling:groupName` tag set to the value you pass in via the
`cluster_name` parameter. You can also specify custom tags via the `tags` parameter. You can use the AWS SDK to find
the IPs of all servers with those tags. 

For example, using the [AWS CLI](https://aws.amazon.com/cli/), you can get the IPs for servers in `us-east-1` with 
the tag `Name=couchbase-example` as follows:

```bash
aws ec2 describe-instances \
    --region "us-east-1" \
    --filter \
      "Name=tag:Name,Values=couchbase-example" \
      "Name=instance-state-name,Values=running"
```

This will return a bunch of JSON that contains the IPs of the servers. You can then use the [Couchbase 
SDK](https://developer.couchbase.com/documentation/server/4.0/sdks/intro.html) for your programming language to connect 
to these IPs. See the [Network Configuration 
documentation](https://developer.couchbase.com/documentation/server/current/install/install-ports.html) to see what
ports different Couchbase services use.




## What's included in this module?

This module creates the following:

* [Auto Scaling Group](#auto-scaling-group)
* [EBS Volumes](#ebs-volumes)
* [Security Group](#security-group)
* [IAM Role and Permissions](#iam-role-and-permissions)


### Auto Scaling Group

This module runs Couchbase on top of an [Auto Scaling Group (ASG)](https://aws.amazon.com/autoscaling/). Typically, you
should run the ASG with multiple Instances spread across multiple [Availability 
Zones](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html). Each of the EC2
Instances should be running an AMI that has Couchbase and/or Sync Gateway installed via the 
[install-couchbase-server](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/modules/install-couchbase-server) and/or
[install-sync-gateway](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/modules/install-sync-gateway) 
modules. You pass in the ID of the AMI to run using the `ami_id` input parameter.


### EBS Volumes

This module can optionally create an [EBS volume](https://aws.amazon.com/ebs/) for each EC2 Instance in the ASG. You 
can use these volume to store Couchbase data. As explained in [the 
documentation](https://developer.couchbase.com/documentation/server/current/cloud/couchbase-aws-best-practices.html#topic_ghd_55f_nbb__aws-storage),
we recommend using two EBS Volumes, one for the Couchbase data dir and one for the index dir.  


### Security Group

Each EC2 Instance in the ASG has a Security Group that allows minimal connectivity:
 
* All outbound requests
* Inbound SSH access from the CIDR blocks and security groups you specify

The Security Group ID is exported as an output variable which you can use with the 
[couchbase-server-security-group-rules](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/modules/couchbase-server-security-group-rules) and
[sync-gateway-security-group-rules](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/modules/sync-gateway-security-group-rules)
modules to open up all the ports necessary for Couchbase and Sync Gateway. 

Check out the [Security section](#security) for more details. 


### IAM Role and Permissions

Each EC2 Instance in the ASG has an [IAM Role](http://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles.html) attached. 
The IAM Role ARN and ID are exported as output variables if you need to add additional permissions. 



## How do you roll out updates?

If you want to deploy a new version of Couchbase across the cluster, the best way to do that is to:


1. Rolling deploy:
    1. Build a new AMI.
    1. Set the `ami_id` parameter to the ID of the new AMI.
    1. Run `terraform apply`.
    1. This updates the Launch Configuration of the ASG, so any new Instances in the ASG will have your new AMI, but it 
       does NOT actually deploy those new instances. You'll have to force the ASG to update the instances as follows.
    1. Remove one of the old nodes from the cluster 
       ([docs](https://developer.couchbase.com/documentation/server/3.x/admin/Tasks/rebalance-remove-node.html)).
    1. Terminate the corresponding EC2 Instance.
    1. The ASG will automatically launch a replacement EC2 Instance after a minute with the new code.
    1. Wait for the replacement node to join the cluster and catch up on replication.
    1. Repeat steps 5-7 for the remaining nodes. 

1. New cluster: 
    1. Build a new AMI.
    1. Create a totally new ASG using the `couchbase-cluster` module with the `ami_id` set to the new AMI, but all 
       other parameters the same as the old cluster.
    1. Wait for all the nodes in the new ASG to join the cluster and catch up on replication.
    1. Remove each of the nodes from the old cluster 
       ([docs](https://developer.couchbase.com/documentation/server/3.x/admin/Tasks/rebalance-remove-node.html)).
    1. Remove the old ASG by removing that `couchbase-cluster` module from your code.
   
We may add a script in the future to automate this process (PRs are welcome!).




## Security

Here are some of the main security considerations to keep in mind when using this module:

1. [Encryption in transit](#encryption-in-transit)
1. [Encryption at rest](#encryption-at-rest)
1. [Dedicated instances](#dedicated-instances)
1. [Security groups](#security-groups)
1. [SSH access](#ssh-access)


### Encryption in transit

Couchbase can encrypt all of its network traffic. For instructions on enabling network encryption, have a look at the
[encryption on the wire documentation](https://developer.couchbase.com/documentation/server/current/security/security-comm-encryption.html).


### Encryption at rest

The EC2 Instances in the cluster can store their data in one of two locations:

* An EBS Volume, if you enable it with this module. Set the `ebs_volume_encrypted` parameter to `true` to enable 
  encryption for the EBS volume.
  
* The root volume. To encrypt the root volume, you must encrypt your AMI. If you're creating the AMI using Packer 
  (e.g. as shown in the [couchbase-ami example](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/examples/couchbase-ami)), 
  you need to set the [encrypt_boot parameter](https://www.packer.io/docs/builders/amazon-ebs.html#encrypt_boot) to 
  `true`.  


### Dedicated instances

If you wish to use dedicated instances, you can set the `tenancy` parameter to `"dedicated"` in this module. 


### Security groups

This module attaches a security group to each EC2 Instance that allows inbound requests as follows:

* **SSH**: For the SSH port (default: 22), you can use the `allowed_ssh_cidr_blocks` parameter to control the list of   
  [CIDR blocks](https://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing) that will be allowed access. You can use 
  the `allowed_inbound_ssh_security_group_ids` parameter to control the list of source Security Groups that will be 
  allowed access.
  
The ID of the security group is exported as an output variable, which you can use with the 
[couchbase-server-security-group-rules](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/modules/couchbase-server-security-group-rules) and
[sync-gateway-security-group-rules](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/modules/sync-gateway-security-group-rules)
modules to open up all the ports necessary for Couchbase and Sync Gateway.
  
  

### SSH access

You can associate an [EC2 Key Pair](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html) with each
of the EC2 Instances in this cluster by specifying the Key Pair's name in the `ssh_key_name` variable. If you don't
want to associate a Key Pair with these servers, set `ssh_key_name` to an empty string.
