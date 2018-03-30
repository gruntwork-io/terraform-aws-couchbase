#!/bin/bash

set -e

readonly AWS_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$AWS_SCRIPT_DIR/logging.sh"
source "$AWS_SCRIPT_DIR/aws-primitives.sh"
source "$AWS_SCRIPT_DIR/assertions.sh"

readonly AWS_MAX_RETRIES=60
readonly AWS_SLEEP_BETWEEN_RETRIES_SEC=5

# Get the name of the ASG this EC2 Instance is in
function get_asg_name {
  local instance_id
  instance_id=$(get_instance_id)

  local instance_region
  instance_region=$(get_instance_region)

  get_instance_tag "$instance_id" "$instance_region" "aws:autoscaling:groupName"
}

# Get the value for a specific tag from the tags JSON returned by the AWS describe-tags:
# https://docs.aws.amazon.com/cli/latest/reference/ec2/describe-tags.html
function get_instance_tag {
  local readonly instance_id="$1"
  local readonly instance_region="$2"
  local readonly tag_key="$3"

  for (( i=0; i<"$AWS_MAX_RETRIES"; i++ )); do
    local tags
    tags=$(wait_for_instance_tags "$instance_id" "$instance_region")
    assert_not_empty_or_null "$tags" "tags for Instance $instance_id in $instance_region"

    local tag_value
    tag_value=$(echo "$tags" | jq -r ".Tags[] | select(.Key == \"$tag_key\") | .Value")

    if is_empty_or_null "$tag_value"; then
      log_warn "Instance $instance_id in $instance_region does not yet seem to have tag $tag_key. Will sleep for $AWS_SLEEP_BETWEEN_RETRIES_SEC seconds and check again."
      sleep "$AWS_SLEEP_BETWEEN_RETRIES_SEC"
    else
      log_info "Found value '$tag_value' for tag $tag_key for Instance $instance_id in $instance_region"
      echo -n "$tag_value"
      return
    fi
  done

  log_error "Could not find value for tag $tag_key for Instance $instance_id in $instance_region after $AWS_MAX_RETRIES retries."
  exit 1
}

# Get the tags for the current EC2 Instance. Tags may take time to propagate, so this method will retry until the tags
# are available.
function wait_for_instance_tags {
  local readonly instance_id="$1"
  local readonly instance_region="$2"

  log_info "Looking up tags for Instance $instance_id in $instance_region"

  for (( i=0; i<"$AWS_MAX_RETRIES"; i++ )); do
    local tags
    tags=$(get_instance_tags "$instance_id" "$instance_region")

    local count_tags
    count_tags=$(echo $tags | jq -r ".Tags? | length")
    log_info "Found $count_tags tags for $instance_id."

    if [[ "$count_tags" -gt 0 ]]; then
      echo -n "$tags"
      return
    else
      log_warn "Tags for Instance $instance_id must not have propagated yet. Will sleep for $AWS_SLEEP_BETWEEN_RETRIES_SEC seconds and check again."
      sleep "$AWS_SLEEP_BETWEEN_RETRIES_SEC"
    fi
  done

  log_error "Could not find tags for Instance $instance_id in $instance_region after $AWS_MAX_RETRIES retries."
  exit 1
}

# Get the desired capacity of the ASG with the given name in the given region
function get_asg_size {
  local readonly asg_name="$1"
  local readonly aws_region="$2"

  for (( i=0; i<"$AWS_MAX_RETRIES"; i++ )); do
    log_info "Looking up the size of the Auto Scaling Group $asg_name in $aws_region"

    local asg_json
    asg_json=$(describe_asg "$asg_name" "$aws_region")

    local desired_capacity
    desired_capacity=$(echo "$asg_json" | jq -r '.AutoScalingGroups[0]?.DesiredCapacity')

    if is_empty_or_null "$desired_capacity"; then
      log_warn "Could not find desired capacity for ASG $asg_name. Perhaps the ASG has not been created yet? Will sleep for $AWS_SLEEP_BETWEEN_RETRIES_SEC and check again. AWS response:\n$asg_json"
      sleep "$AWS_SLEEP_BETWEEN_RETRIES_SEC"
    else
      echo -n "$desired_capacity"
      return
    fi
  done

  log_error "Could not find size of ASG $asg_name after $AWS_MAX_RETRIES retries."
  exit 1
}

# Describe the running instances in the given ASG and region. This method will retry until it is able to get the
# information for the number of instances that are defined in the ASG's DesiredCapacity. This ensures the method waits
# until all the Instances have booted.
function wait_for_instances_in_asg {
  local readonly asg_name="$1"
  local readonly aws_region="$2"

  local asg_size
  asg_size=$(get_asg_size "$asg_name" "$aws_region")

  log_info "Looking up Instances in ASG $asg_name in $aws_region"
  for (( i=0; i<"$AWS_MAX_RETRIES"; i++ )); do
    local instances
    instances=$(describe_instances_in_asg "$asg_name" "$aws_region")

    local count_instances
    count_instances=$(echo "$instances" | jq -r "[.Reservations[].Instances[].InstanceId] | length")

    log_info "Found $count_instances / $asg_size Instances in ASG $asg_name in $aws_region."

    if [[ "$count_instances" -eq "$asg_size" ]]; then
      echo "$instances"
      return
    else
      log_warn "Will sleep for $AWS_SLEEP_BETWEEN_RETRIES_SEC seconds and try again."
      sleep "$AWS_SLEEP_BETWEEN_RETRIES_SEC"
    fi
  done

  log_error "Could not find all $asg_size Instances in ASG $asg_name in $aws_region after $AWS_MAX_RETRIES retries."
  exit 1
}

function get_ips_in_asg {
  local readonly asg_name="$1"
  local readonly aws_region="$2"
  local readonly use_public_ips="$3"

  local instances
  instances=$(describe_instances_in_asg "$asg_name" "$aws_region")
  assert_not_empty_or_null "$instances" "Get info about Instances in ASG $asg_name in $aws_region"

  local readonly ip_param=$([[ "$use_public_ips" == "true" ]] && echo "PublicIpAddress" || echo "PrivateIpAddress")
  echo "$instances" | jq -r ".Reservations[].Instances[].$ip_param"
}

function get_hostnames_in_asg {
  local readonly asg_name="$1"
  local readonly aws_region="$2"
  local readonly use_public_hostnames="$3"

  local instances
  instances=$(wait_for_instances_in_asg "$asg_name" "$aws_region")
  assert_not_empty_or_null "$instances" "Get info about Instances in ASG $asg_name in $aws_region"

  local readonly hostname_param=$([[ "$use_public_hostnames" == "true" ]] && echo "PublicDnsName" || echo "PrivateDnsName")
  echo "$instances" | jq -r ".Reservations[].Instances[].$hostname_param"
}