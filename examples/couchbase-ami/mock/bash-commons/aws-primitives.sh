#!/bin/bash

set -e

# We are using host networking (see network_mode in docker-compose.yml), so all of these servers will be listening
# on different ports on localhost.
readonly COUCHBASE_NODE_HOSTNAME="127.0.0.1"

function get_instance_private_ip {
  echo -n "$COUCHBASE_NODE_HOSTNAME"
}

function get_instance_public_ip {
  echo -n "$COUCHBASE_NODE_HOSTNAME"
}

function get_instance_private_hostname {
  echo -n "$COUCHBASE_NODE_HOSTNAME"
}

function get_instance_public_hostname {
  echo -n "$COUCHBASE_NODE_HOSTNAME"
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

  cat << EOF
{
  "Reservations": [
    {
      "Instances": [
        {
          "PublicDnsName": "$COUCHBASE_NODE_HOSTNAME",
          "LaunchTime": "2018-03-17T17:38:31.000Z",
          "PublicIpAddress": "$COUCHBASE_NODE_HOSTNAME",
          "PrivateIpAddress": "$COUCHBASE_NODE_HOSTNAME",
          "InstanceId": "i-0ace993b1700c0040",
          "PrivateDnsName": "$COUCHBASE_NODE_HOSTNAME",
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
          "PublicDnsName": "$COUCHBASE_NODE_HOSTNAME",
          "LaunchTime": "2018-03-17T17:38:31.000Z",
          "PublicIpAddress": "$COUCHBASE_NODE_HOSTNAME",
          "PrivateIpAddress": "$COUCHBASE_NODE_HOSTNAME",
          "InstanceId": "i-0bce993b1700c0040",
          "PrivateDnsName": "$COUCHBASE_NODE_HOSTNAME",
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
          "PublicDnsName": "$COUCHBASE_NODE_HOSTNAME",
          "LaunchTime": "2018-03-17T17:38:31.000Z",
          "PublicIpAddress": "$COUCHBASE_NODE_HOSTNAME",
          "PrivateIpAddress": "$COUCHBASE_NODE_HOSTNAME",
          "InstanceId": "i-0cce993b1700c0040",
          "PrivateDnsName": "$COUCHBASE_NODE_HOSTNAME",
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