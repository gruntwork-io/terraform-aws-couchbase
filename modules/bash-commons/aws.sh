#!/bin/bash

set -e

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/logging.sh"

readonly EC2_INSTANCE_METADATA_URL="http://169.254.169.254/latest/meta-data"
readonly EC2_INSTANCE_DYNAMIC_DATA_URL="http://169.254.169.254/latest/dynamic"

readonly MAX_RETRIES=60
readonly SLEEP_BETWEEN_RETRIES_SEC=5

# Look up the given path in the EC2 Instance metadata endpoint
function lookup_path_in_instance_metadata {
  local readonly path="$1"
  curl --silent --show-error --location "$EC2_INSTANCE_METADATA_URL/$path/"
}

# Look up the given path in the EC2 Instance dynamic metadata endpoint
function lookup_path_in_instance_dynamic_data {
  local readonly path="$1"
  curl --silent --show-error --location "$EC2_INSTANCE_DYNAMIC_DATA_URL/$path/"
}

# Get the private IP address for this EC2 Instance
function get_instance_private_ip {
  lookup_path_in_instance_metadata "local-ipv4"
}

# Get the public IP address for this EC2 Instance
function get_instance_public_ip {
  lookup_path_in_instance_metadata "public-ipv4"
}

# Get the private hostname for this EC2 Instance
function get_instance_private_hostname {
  lookup_path_in_instance_metadata "local-hostname"
}

# Get the public hostname for this EC2 Instance
function get_instance_public_hostname {
  lookup_path_in_instance_metadata "public-hostname"
}

# Get the ID of this EC2 Instance
function get_instance_id {
  lookup_path_in_instance_metadata "instance-id"
}

# Get all the tags for the current EC2 Instance. Tags propagate asynchronously, so retry multiple times if tags are not
# found.
function get_instance_tags {
  local readonly instance_region="$1"

  local instance_id
  instance_id=$(get_instance_id)

  log_info "Looking up tags for Instance $instance_id in $instance_region"
  for (( i=1; i<="$MAX_RETRIES"; i++ )); do
    local tags
    tags=$(aws ec2 describe-tags \
      --region "$instance_region" \
      --filters "Name=resource-type,Values=instance" "Name=resource-id,Values=$instance_id")

    local count_tags
    count_tags=$(echo $tags | jq -r ".Tags? | length")

    log_info "Found $count_tags tags for Instance $instance_id in $instance_region: $tags."

    if [[ "$count_tags" -gt 0 ]]; then
      echo "$tags"
      return
    else
      log_warn "Did not find any tags for Instance $instance_id in $instance_region. Will sleep for $SLEEP_BETWEEN_RETRIES_SEC seconds and try again."
      sleep "$SLEEP_BETWEEN_RETRIES_SEC"
    fi
  done

  log_error "Could not find Instance tags for $instance_id in $instance_region after $MAX_RETRIES retries."
  exit 1
}

# Get the value for a specific tag from the tags JSON returned by the AWS describe-tags:
# https://docs.aws.amazon.com/cli/latest/reference/ec2/describe-tags.html
function get_tag_value {
  local readonly tags="$1"
  local readonly tag_key="$2"

  echo "$tags" | jq -r ".Tags[] | select(.Key == \"$tag_key\") | .Value"
}

# Get the desired capacity of the ASG with the given name in the given region
function get_asg_size {
  local readonly asg_name="$1"
  local readonly aws_region="$2"

  log_info "Looking up the size of the Auto Scaling Group $asg_name in $aws_region"

  local asg_json
  asg_json=$(aws autoscaling describe-auto-scaling-groups --region "$aws_region" --auto-scaling-group-names "$asg_name")

  echo "$asg_json" | jq -r '.AutoScalingGroups[0].DesiredCapacity'
}

# Describe the running instances in the given ASG and region. This method will retry until it is able to get the
# information for the number of instances that are defined in the ASG's DesiredCapacity. This ensures the method waits
# until all the Instances have booted.
function describe_instances_in_asg {
  local readonly asg_name="$1"
  local readonly aws_region="$2"

  local asg_size
  asg_size=$(get_asg_size "$asg_name" "$aws_region")

  log_info "Looking up Instances in ASG $asg_name in $aws_region"
  for (( i=1; i<="$MAX_RETRIES"; i++ )); do
    local instances
    instances=$(aws ec2 describe-instances \
      --region "$aws_region" \
      --filters
        "Name=tag:aws:autoscaling:groupName,Values=$asg_name" \
        "Name=instance-state-name,Values=pending,running")

    local count_instances
    count_instances=$(echo "$instances" | jq -r "[.Reservations[].Instances[].InstanceId] | length")

    log_info "Found $count_instances / $count_instances Instances in ASG $asg_name in $aws_region."

    if [[ "$count_instances" -eq "$asg_size" ]]; then
      echo "$instances"
      return
    else
      log_warn "Will sleep for $SLEEP_BETWEEN_RETRIES_SEC seconds and try again."
      sleep "$SLEEP_BETWEEN_RETRIES_SEC"
    fi
  done

  log_error "Could not find all $asg_size Instances in ASG $asg_name in $aws_region after $MAX_RETRIES retries."
  exit 1
}