#!/bin/bash

set -e

# Send the log output from this script to user-data.log, syslog, and the console
# From: https://alestic.com/2010/12/ec2-user-data-output/
exec > >(tee /opt/couchbase/var/lib/couchbase/logs/mock-user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

source "/opt/couchbase-commons/couchbase-common.sh"
source "/opt/couchbase-commons/mount-volume.sh"

function mount_volumes {
  local -r data_volume_device_name="$1"
  local -r data_volume_mount_point="$2"
  local -r index_volume_device_name="$3"
  local -r index_volume_mount_point="$4"
  local -r volume_owner="$5"

  echo "Mounting EBS Volumes for data and index directories"
  mount_volume "$data_volume_device_name" "$data_volume_mount_point" "$volume_owner"
  mount_volume "$index_volume_device_name" "$index_volume_mount_point" "$volume_owner"
}

function run_couchbase {
  local -r cluster_asg_name="$1"
  local -r cluster_username="$2"
  local -r cluster_password="$3"
  local -r cluster_port="$4"
  local -r data_dir="$5"
  local -r index_dir="$6"

  echo "Starting Couchbase"

  /opt/couchbase/bin/run-couchbase-server \
    --cluster-name "$cluster_asg_name" \
    --cluster-username "$cluster_username" \
    --cluster-password "$cluster_password" \
    --rest-port "$cluster_port" \
    --data-dir "$data_dir" \
    --index-dir "$index_dir" \
    --wait-for-all-nodes
}

function create_test_resources {
  local -r cluster_username="$1"
  local -r cluster_password="$2"
  local -r cluster_port="$3"
  local -r user_name="$4"
  local -r user_password="$5"
  local -r bucket_name="$6"

  local -r max_retries=120
  local -r sleep_between_retries_sec=5

  echo "Creating user $user_name"

  run_couchbase_cli_with_retry \
    "Create RBAC user $user_name" \
    "SUCCESS:" \
    "$max_retries" \
    "$sleep_between_retries_sec" \
    "user-manage" \
    "--cluster=127.0.0.1:$cluster_port" \
    "--username=$cluster_username" \
    "--password=$cluster_password" \
    "--set" \
    "--rbac-username=$user_name" \
    "--rbac-password=$user_password" \
    "--rbac-name=$user_name" \
    "--roles=admin" \
    "--auth-domain=local"

  echo "Creating bucket $bucket_name"

  run_couchbase_cli_with_retry \
    "Create bucket $bucket_name" \
    "SUCCESS:" \
    "$max_retries" \
    "$sleep_between_retries_sec" \
    "bucket-create" \
    "--cluster=127.0.0.1:$cluster_port" \
    "--username=$user_name" \
    "--password=$user_password" \
    "--bucket=$bucket_name" \
    "--bucket-type=couchbase" \
    "--bucket-ramsize=100"
}

function run_sync_gateway {
  local -r cluster_asg_name="$1"
  local -r cluster_port="$2"
  local -r sync_gateway_interface="$3"
  local -r sync_gateway_admin_interface="$4"
  local -r bucket="$5"
  local -r username="$6"
  local -r password="$7"

  echo "Starting Sync Gateway"

  /opt/couchbase-sync-gateway/bin/run-sync-gateway \
    --auto-fill-asg "<SERVERS>=$cluster_asg_name:$cluster_port" \
    --auto-fill "<INTERFACE>=$sync_gateway_interface" \
    --auto-fill "<ADMIN_INTERFACE>=$sync_gateway_admin_interface" \
    --auto-fill "<DB_NAME>=$cluster_asg_name" \
    --auto-fill "<BUCKET_NAME>=$bucket" \
    --auto-fill "<DB_USERNAME>=$username" \
    --auto-fill "<DB_PASSWORD>=$password"
}

function run {
  local -r cluster_asg_name="$1"
  local -r cluster_port="$2"
  local -r sync_gateway_interface="$3"
  local -r sync_gateway_admin_interface="$4"
  local -r data_volume_device_name="$5"
  local -r data_volume_mount_point="$6"
  local -r index_volume_device_name="$7"
  local -r index_volume_mount_point="$8"
  local -r volume_owner="$9"

  # To keep this example simple, we are hard-coding all credentials in this file in plain text. You should NOT do this
  # in production usage!!! Instead, you should use tools such as Vault, Keywhiz, or KMS to fetch the credentials at
  # runtime and only ever have the plaintext version in memory.
  local -r cluster_username="admin"
  local -r cluster_password="password"
  local -r test_user_name="test-user"
  local -r test_user_password="password"
  local -r test_bucket_name="test-bucket"

  mount_volumes "$data_volume_device_name" "$data_volume_mount_point" "$index_volume_device_name" "$index_volume_mount_point" "$volume_owner"
  run_couchbase "$cluster_asg_name" "$cluster_username" "$cluster_password" "$cluster_port" "$data_volume_mount_point" "$index_volume_mount_point"

  local node_hostname
  local rally_point_hostname
  read _ node_hostname _ rally_point_hostname < <(/opt/couchbase-commons/couchbase-rally-point --cluster-name "$cluster_asg_name" --use-public-hostname "false")

  if [[ "$node_hostname" == "$rally_point_hostname" ]]; then
    echo "This node is the rally point for this cluster"
    create_test_resources "$cluster_username" "$cluster_password" "$cluster_port" "$test_user_name" "$test_user_password" "$test_bucket_name"
  fi

  run_sync_gateway "$cluster_asg_name" "$cluster_port" "$sync_gateway_interface" "$sync_gateway_admin_interface" "$test_bucket_name" "$test_user_name" "$test_user_password"
}

# The variables below are filled in via Terraform interpolation
run \
  "${cluster_asg_name}" \
  "${cluster_port}" \
  "${sync_gateway_interface}" \
  "${sync_gateway_admin_interface}" \
  "${data_volume_device_name}" \
  "${data_volume_mount_point}" \
  "${index_volume_device_name}" \
  "${index_volume_mount_point}" \
  "${volume_owner}"
