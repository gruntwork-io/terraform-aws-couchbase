#!/bin/bash

set -e

# Send the log output from this script to user-data.log, syslog, and the console
# From: https://alestic.com/2010/12/ec2-user-data-output/
exec > >(tee /opt/couchbase/var/lib/couchbase/logs/mock-user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

function run_couchbase {
  local readonly cluster_asg_name="$1"
  local readonly cluster_username="$2"
  local readonly cluster_password="$3"
  local readonly cluster_port="$4"

  echo "Starting Couchbase search nodes"

  /opt/couchbase/bin/run-couchbase-server \
    --cluster-name "$cluster_asg_name" \
    --cluster-username "$cluster_username" \
    --cluster-password "$cluster_password" \
    --rest-port "$cluster_port" \
    --node-services "fts" \
    --use-public-hostname
}

function run {
  local readonly cluster_asg_name="$1"
  local readonly cluster_port="$2"

  # To keep this example simple, we are hard-coding all credentials in this file in plain text. You should NOT do this
  # in production usage!!! Instead, you should use tools such as Vault, Keywhiz, or KMS to fetch the credentials at
  # runtime and only ever have the plaintext version in memory.
  local readonly cluster_username="admin"
  local readonly cluster_password="password"

  run_couchbase "$cluster_asg_name" "$cluster_username" "$cluster_password" "$cluster_port"
}

# The variables below are filled in via Terraform interpolation
run \
  "${cluster_asg_name}" \
  "${cluster_port}"

