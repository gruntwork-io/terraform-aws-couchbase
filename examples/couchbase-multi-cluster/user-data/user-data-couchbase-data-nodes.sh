#!/bin/bash

set -e

# Send the log output from this script to user-data.log, syslog, and the console
# From: https://alestic.com/2010/12/ec2-user-data-output/
exec > >(tee /opt/couchbase/var/lib/couchbase/logs/mock-user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

function mount_volumes {
  local readonly data_volume_device_name="$1"
  local readonly data_volume_mount_point="$2"
  local readonly volume_owner="$3"

  echo "Mounting EBS Volume for the data directory"

  /opt/couchbase/bash-commons/mount-ebs-volume \
    --device-name "$data_volume_device_name" \
    --mount-point "$data_volume_mount_point" \
    --owner "$volume_owner"
}

function run_couchbase {
  local readonly cluster_asg_name="$1"
  local readonly cluster_username="$2"
  local readonly cluster_password="$3"
  local readonly cluster_port="$4"
  local readonly data_dir="$5"

  echo "Starting Couchbase data nodes"

  /opt/couchbase/bin/run-couchbase-server \
    --cluster-name "$cluster_asg_name" \
    --cluster-username "$cluster_username" \
    --cluster-password "$cluster_password" \
    --rest-port "$cluster_port" \
    --data-dir "$data_dir" \
    --node-services "data" \
    --use-public-hostname
}

function create_test_resources {
  local readonly cluster_username="$1"
  local readonly cluster_password="$2"
  local readonly cluster_port="$3"
  local readonly user_name="$4"
  local readonly user_password="$5"
  local readonly bucket_name="$6"

  echo "Creating user $user_name"

  /opt/couchbase/bin/couchbase-cli user-manage \
    --cluster="127.0.0.1:$cluster_port" \
    --username="$cluster_username" \
    --password="$cluster_password" \
    --set \
    --rbac-username="$user_name" \
    --rbac-password="$user_password" \
    --rbac-name="$user_name" \
    --roles="cluster_admin" \
    --auth-domain="local"

  echo "Creating bucket $bucket_name"

  # If the bucket already exists, just ignore the error, as it means one of the other nodes already created it
  set +e
  /opt/couchbase/bin/couchbase-cli  bucket-create \
    --cluster="127.0.0.1:$cluster_port" \
    --username="$user_name" \
    --password="$user_password" \
    --bucket="$bucket_name" \
    --bucket-type="couchbase" \
    --bucket-ramsize="100"
  set -e
}

function run {
  local readonly cluster_asg_name="$1"
  local readonly cluster_port="$2"
  local readonly data_volume_device_name="$3"
  local readonly data_volume_mount_point="$4"
  local readonly volume_owner="$5"

  # To keep this example simple, we are hard-coding all credentials in this file in plain text. You should NOT do this
  # in production usage!!! Instead, you should use tools such as Vault, Keywhiz, or KMS to fetch the credentials at
  # runtime and only ever have the plaintext version in memory.
  local readonly cluster_username="admin"
  local readonly cluster_password="password"
  local readonly test_user_name="test-user"
  local readonly test_user_password="password"
  local readonly test_bucket_name="test-bucket"

  mount_volumes "$data_volume_device_name" "$data_volume_mount_point" "$volume_owner"
  run_couchbase "$cluster_asg_name" "$cluster_username" "$cluster_password" "$cluster_port" "$data_volume_mount_point"
  create_test_resources "$cluster_username" "$cluster_password" "$cluster_port" "$test_user_name" "$test_user_password" "$test_bucket_name"
}

# The variables below are filled in via Terraform interpolation
run \
  "${cluster_asg_name}" \
  "${cluster_port}" \
  "${data_volume_device_name}" \
  "${data_volume_mount_point}" \
  "${volume_owner}"

