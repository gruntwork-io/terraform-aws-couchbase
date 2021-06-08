#!/bin/bash

set -e

# Send the log output from this script to user-data.log, syslog, and the console
# From: https://alestic.com/2010/12/ec2-user-data-output/
exec > >(tee /opt/couchbase/var/lib/couchbase/logs/mock-user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

source "/opt/couchbase-commons/couchbase-common.sh"

function run_couchbase {
  local -r cluster_asg_name="$1"
  local -r cluster_username="$2"
  local -r cluster_password="$3"
  local -r cluster_port="$4"

  echo "Starting Couchbase data nodes"

  /opt/couchbase/bin/run-couchbase-server \
    --cluster-name "$cluster_asg_name" \
    --cluster-username "$cluster_username" \
    --cluster-password "$cluster_password" \
    --rest-port "$cluster_port" \
    --node-services "data" \
    --cluster-services "data" \
    --use-public-hostname \
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

function start_replication {
  local -r cluster_username="$1"
  local -r cluster_password="$2"
  local -r cluster_port="$3"
  local -r src_bucket_name="$4"
  local -r dest_cluster_name="$5"
  local -r dest_cluster_username="$6"
  local -r dest_cluster_password="$7"
  local -r replication_dest_cluster_aws_region="$8"
  local -r dest_bucket_name="$9"

  echo "Looking up hostname for Couchbase cluster $dest_cluster_name in $replication_dest_cluster_aws_region"

  local dest_cluster_hostname
  read _ _ _ dest_cluster_hostname < <(/opt/couchbase-commons/couchbase-rally-point --cluster-name "$dest_cluster_name" --use-public-hostname "true" --aws-region "$replication_dest_cluster_aws_region" --node-hostname "ignore")

  echo "Starting replication from bucket $src_bucket_name in this cluster to bucket $dest_bucket_name in cluster $dest_cluster_name"

  /opt/couchbase/bin/run-replication \
    --src-cluster-hostname "127.0.0.1:$cluster_port" \
    --src-cluster-username "$cluster_username" \
    --src-cluster-password "$cluster_password" \
    --src-cluster-bucket-name "$src_bucket_name" \
    --dest-cluster-name "$dest_cluster_name" \
    --dest-cluster-hostname "$dest_cluster_hostname" \
    --dest-cluster-username "$dest_cluster_username" \
    --dest-cluster-password "$dest_cluster_password" \
    --dest-cluster-bucket-name "$dest_bucket_name" \
    --replicate-arg xdcr-replication-mode=capi
}

function run {
  local -r cluster_asg_name="$1"
  local -r cluster_port="$2"
  local -r replication_dest_cluster_name="$3"
  local -r replication_dest_cluster_aws_region="$4"

  # To keep this example simple, we are hard-coding all credentials in this file in plain text. You should NOT do this
  # in production usage!!! Instead, you should use tools such as Vault, Keywhiz, or KMS to fetch the credentials at
  # runtime and only ever have the plaintext version in memory.
  local -r cluster_username="admin"
  local -r cluster_password="password"

  run_couchbase "$cluster_asg_name" "$cluster_username" "$cluster_password" "$cluster_port"

  local node_hostname
  local rally_point_hostname
  read _ node_hostname _ rally_point_hostname < <(/opt/couchbase-commons/couchbase-rally-point --cluster-name "$cluster_asg_name" --use-public-hostname "true")

  if [[ "$node_hostname" == "$rally_point_hostname" ]]; then
    echo "This node is the rally point for this cluster"

    # To keep this example simple, we are hard-coding all credentials in this file in plain text. You should NOT do this
    # in production usage!!! Instead, you should use tools such as Vault, Keywhiz, or KMS to fetch the credentials at
    # runtime and only ever have the plaintext version in memory.
    local -r test_user_name="test-user"
    local -r test_user_password="password"
    local -r test_bucket_name="test-bucket"
    local -r dest_cluster_username="admin"
    local -r dest_cluster_password="password"
    local -r dest_bucket_name="test-bucket-replica"

    create_test_resources "$cluster_username" "$cluster_password" "$cluster_port" "$test_user_name" "$test_user_password" "$test_bucket_name"
    start_replication "$cluster_username" "$cluster_password" "$cluster_port" "$test_bucket_name" "$replication_dest_cluster_name" "$dest_cluster_username" "$dest_cluster_password" "$replication_dest_cluster_aws_region" "$dest_bucket_name"
  fi
}

# The variables below are filled in via Terraform interpolation
run \
  "${cluster_asg_name}" \
  "${cluster_port}" \
  "${replication_dest_cluster_name}" \
  "${replication_dest_cluster_aws_region}"
