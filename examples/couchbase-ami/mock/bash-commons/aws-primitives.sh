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

function get_instance_region {
  echo "us-east-1"
}

# Return the container ID of the current Docker container. Per https://stackoverflow.com/a/25729598/2308858
function get_instance_id {
  cat /proc/1/cgroup | grep 'docker/' | tail -1 | sed 's/^.*\///'
}

# This mock returns a hard-coded, simplified version of the aws ec2 describe-tags call.
function get_instance_tags {
  local readonly instance_id="$1"
  local readonly instance_region="$2"

  # The cluster_asg_name below is an env var from mock/user-data/mock-couchbase.env
  cat << EOF
{
  "Tags": [
    {
      "ResourceType": "instance",
      "ResourceId": "$instance_id",
      "Value": "$cluster_asg_name",
      "Key": "Name"
    },
    {
      "ResourceType": "instance",
      "ResourceId": "$instance_id",
      "Value": "$cluster_asg_name",
      "Key": "aws:autoscaling:groupName"
    }
  ]
}
EOF
}

# This mock returns a hard-coded, simplified version of the aws autoscaling describe-auto-scaling-groups call.
function describe_asg {
  local readonly asg_name="$1"
  local readonly aws_region="$2"

  cat << EOF
{
  "AutoScalingGroups": [
    {
      "AutoScalingGroupARN": "arn:aws:autoscaling:$aws_region:123456789012:autoScalingGroup:930d940e-891e-4781-a11a-7b0acd480f03:autoScalingGroupName/$asg_name",
      "DesiredCapacity": 3,
      "AutoScalingGroupName": "$asg_name",
      "LaunchConfigurationName": "$asg_name",
      "CreatedTime": "2013-08-19T20:53:25.584Z"
    }
  ]
}
EOF
}

# This mock returns a hard-coded, simplified version of the aws ec2 describe-instances call.
function describe_instances_in_asg {
  local readonly asg_name="$1"
  local readonly aws_region="$2"

  # These hostnames are set by Docker Compose networking using the names of the services
  # (https://docs.docker.com/compose/networking/). We use getent (https://unix.stackexchange.com/a/20793/215969) to get
  # the IP addresses for these hostnames, as that's what the servers themselves will advertise (see the mock
  # get_instance_xxx_hostname methods above).

  local readonly couchbase_hostname_0=$(getent hosts couchbase-ubuntu-0 | awk '{ print $1 }')
  local readonly couchbase_hostname_1=$(getent hosts couchbase-ubuntu-1 | awk '{ print $1 }')
  local readonly couchbase_hostname_2=$(getent hosts couchbase-ubuntu-2 | awk '{ print $1 }')

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
          "InstanceId": "i-0ece993b1700c0040",
          "PrivateDnsName": "$couchbase_hostname_0",
          "Tags": [
            {
              "Value": "$asg_name",
              "Key": "Name"
            },
            {
              "Value": "$asg_name",
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
          "PrivateDnsName": "$couchbase_hostname_1",
          "Tags": [
            {
              "Value": "$asg_name",
              "Key": "Name"
            },
            {
              "Value": "$asg_name",
              "Key": "aws:autoscaling:groupName"
            }
          ]
        },
        {
          "PublicDnsName": "$couchbase_hostname_2",
          "LaunchTime": "2018-03-17T17:38:31.000Z",
          "PublicIpAddress": "$couchbase_hostname_2",
          "PrivateIpAddress": "$couchbase_hostname_2",
          "PrivateDnsName": "$couchbase_hostname_2",
          "Tags": [
            {
              "Value": "$asg_name",
              "Key": "Name"
            },
            {
              "Value": "$asg_name",
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