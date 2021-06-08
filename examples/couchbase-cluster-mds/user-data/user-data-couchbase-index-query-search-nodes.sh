#!/bin/bash

set -e

# Send the log output from this script to user-data.log, syslog, and the console
# From: https://alestic.com/2010/12/ec2-user-data-output/
exec > >(tee /opt/couchbase/var/lib/couchbase/logs/mock-user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

source "/opt/couchbase-commons/mount-volume.sh"

function mount_volumes {
  local -r index_volume_device_name="$1"
  local -r index_volume_mount_point="$2"
  local -r volume_owner="$3"

  echo "Mounting EBS Volume for the index directory"
  mount_volume "$index_volume_device_name" "$index_volume_mount_point" "$volume_owner"
}

function run_couchbase {
  local -r cluster_asg_name="$1"
  local -r cluster_username="$2"
  local -r cluster_password="$3"
  local -r cluster_port="$4"
  local -r index_dir="$5"

  echo "Starting Couchbase index, query, and search nodes"

  /opt/couchbase/bin/run-couchbase-server \
    --cluster-name "$cluster_asg_name" \
    --cluster-username "$cluster_username" \
    --cluster-password "$cluster_password" \
    --rest-port "$cluster_port" \
    --index-dir "$index_dir" \
    --node-services "index,query,fts" \
    --use-public-hostname
}

function run {
  local -r cluster_asg_name="$1"
  local -r cluster_port="$2"
  local -r index_volume_device_name="$3"
  local -r index_volume_mount_point="$4"
  local -r volume_owner="$5"

  # To keep this example simple, we are hard-coding all credentials in this file in plain text. You should NOT do this
  # in production usage!!! Instead, you should use tools such as Vault, Keywhiz, or KMS to fetch the credentials at
  # runtime and only ever have the plaintext version in memory.
  local -r cluster_username="admin"
  local -r cluster_password="password"

  mount_volumes "$index_volume_device_name" "$index_volume_mount_point" "$volume_owner"
  run_couchbase "$cluster_asg_name" "$cluster_username" "$cluster_password" "$cluster_port" "$index_volume_mount_point"
}

# The variables below are filled in via Terraform interpolation
run \
  "${cluster_asg_name}" \
  "${cluster_port}" \
  "${index_volume_device_name}" \
  "${index_volume_mount_point}" \
  "${volume_owner}"
