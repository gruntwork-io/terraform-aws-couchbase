#!/bin/bash

set -e

# Send the log output from this script to user-data.log, syslog, and the console
# From: https://alestic.com/2010/12/ec2-user-data-output/
exec > >(tee /opt/couchbase/var/lib/couchbase/logs/mock-user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

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
    --auto-fill "<DB_PASSWORD>=$password" \
    --use-public-hostname
}

function run {
  local -r cluster_asg_name="$1"
  local -r cluster_port="$2"
  local -r sync_gateway_interface="$3"
  local -r sync_gateway_admin_interface="$4"

  # To keep this example simple, we are hard-coding all credentials in this file in plain text. You should NOT do this
  # in production usage!!! Instead, you should use tools such as Vault, Keywhiz, or KMS to fetch the credentials at
  # runtime and only ever have the plaintext version in memory.
  local -r cluster_username="admin"
  local -r cluster_password="password"
  local -r test_user_name="test-user"
  local -r test_user_password="password"
  local -r test_bucket_name="test-bucket"

  run_sync_gateway "$cluster_asg_name" "$cluster_port" "$sync_gateway_interface" "$sync_gateway_admin_interface" "$test_bucket_name" "$test_user_name" "$test_user_password"
}

# The variables below are filled in via Terraform interpolation
run \
  "${cluster_asg_name}" \
  "${cluster_port}" \
  "${sync_gateway_interface}" \
  "${sync_gateway_admin_interface}"
