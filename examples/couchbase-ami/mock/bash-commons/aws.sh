#!/bin/bash

set -e

function get_instance_private_ip {
  hostname -i
}

function get_instance_public_ip {
  hostname -i
}

function get_instance_private_hostname {
  hostname -i
}

function get_instance_public_hostname {
  hostname -i
}

# This mock returns a hard-coded, simplified version of the aws ec2 describe-instances call.
function describe_instances_in_asg {
  # These hostnames are set by Docker Compose networking using the names of the services
  # https://docs.docker.com/compose/networking/
  local readonly couchbase_hostname_0="couchbase-ubuntu-0"
  local readonly couchbase_hostname_1="couchbase-ubuntu-1"
  local readonly couchbase_hostname_2="couchbase-ubuntu-2"

  cat << EOF
{
  "Reservations": [
    {
      "Instances": [
        {
          "PublicDnsName": "$couchbase_hostname_0",
          "LaunchTime": "2018-03-17T17:38:31.000Z",
          "PublicIpAddress": "$couchbase_hostname_0",
          "PrivateIpAddress": "$couchbase_hostname_0",
          "VpcId": "vpc-0e0d9a6b",
          "InstanceId": "i-0ece993b1700c0040",
          "ImageId": "ami-66506c1c",
          "PrivateDnsName": "$couchbase_hostname_0",
          "SubnetId": "subnet-d377c6a4",
          "Tags": [
            {
              "Value": "couchbase-mock-name-tag",
              "Key": "Name"
            },
            {
              "Value": "couchbase-mock-name-tag",
              "Key": "aws:autoscaling:groupName"
            }
          ]
        }
      ]
    },
    {
      "Instances": [
        {
          "PublicDnsName": "$couchbase_hostname_1",
          "LaunchTime": "2018-03-17T17:38:31.000Z",
          "PublicIpAddress": "$couchbase_hostname_1",
          "PrivateIpAddress": "$couchbase_hostname_1",
          "VpcId": "vpc-0e0d9a6b",
          "InstanceId": "i-0279ee0e9e82a0afe",
          "ImageId": "ami-66506c1c",
          "PrivateDnsName": "$couchbase_hostname_1",
          "SubnetId": "subnet-3b29db10",
          "Tags": [
            {
              "Value": "couchbase-mock-name-tag",
              "Key": "Name"
            },
            {
              "Value": "couchbase-mock-name-tag",
              "Key": "aws:autoscaling:groupName"
            }
          ]
        },
        {
          "PublicDnsName": "$couchbase_hostname_2",
          "LaunchTime": "2018-03-17T17:38:31.000Z",
          "PublicIpAddress": "$couchbase_hostname_2",
          "PrivateIpAddress": "$couchbase_hostname_2",
          "VpcId": "vpc-0e0d9a6b",
          "InstanceId": "i-0e93dc6f436667dad",
          "ImageId": "ami-66506c1c",
          "PrivateDnsName": "$couchbase_hostname_2",
          "SubnetId": "subnet-1cb53110",
          "Tags": [
            {
              "Value": "couchbase-mock-name-tag",
              "Key": "Name"
            },
            {
              "Value": "couchbase-mock-name-tag",
              "Key": "aws:autoscaling:groupName"
            }
          ]
        }
      ]
    }
  ]
}
EOF
}