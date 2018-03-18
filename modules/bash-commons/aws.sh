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

  local tags
  tags=$(wait_for_instance_tags "$instance_id" "$instance_region")
  assert_not_empty_aws_response "$tags" "Tags for instance $instance_id"

  get_tag_value "$tags" "aws:autoscaling:groupName"
}

# Get the value for a specific tag from the tags JSON returned by the AWS describe-tags:
# https://docs.aws.amazon.com/cli/latest/reference/ec2/describe-tags.html
function get_tag_value {
  local readonly tags="$1"
  local readonly tag_key="$2"

  echo "$tags" | jq -r ".Tags[] | select(.Key == \"$tag_key\") | .Value"
}

# Get the tags for the current EC2 Instance. Tags may take time to propagate, so this method will retry until the tags
# are available.
function wait_for_instance_tags {
  local readonly instance_id="$1"
  local readonly instance_region="$2"

  log_info "Looking up tags for Instance $instance_id in $instance_region"

  for (( i=1; i<="$AWS_MAX_RETRIES"; i++ )); do
    local tags
    tags=$(get_instance_tags "$instance_id" "$instance_region")

    local count_tags
    count_tags=$(echo $tags | jq -r ".Tags? | length")
    log_info "Found $count_tags tags for $instance_id."

    if [[ "$count_tags" -gt 0 ]]; then
      echo "$tags"
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

  log_info "Looking up the size of the Auto Scaling Group $asg_name in $aws_region"

  local asg_json
  asg_json=$(describe_asg "$asg_name" "$aws_region")
  assert_not_empty_aws_response "$asg_json" "Description of ASG $asg_name"

  echo "$asg_json" | jq -r '.AutoScalingGroups[0].DesiredCapacity'
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
  for (( i=1; i<="$AWS_MAX_RETRIES"; i++ )); do
    local instances
    instances=$(describe_instances_in_asg "$asg_name" "$aws_region")

    local count_instances
    count_instances=$(echo "$instances" | jq -r "[.Reservations[].Instances[].InstanceId] | length")

    log_info "Found $count_instances / $count_instances Instances in ASG $asg_name in $aws_region."

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