#!/bin/bash

set -e

# Send the log output from this script to user-data.log, syslog, and the console
# From: https://alestic.com/2010/12/ec2-user-data-output/
exec > >(tee /opt/couchbase/var/lib/couchbase/logs/mock-user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

# Mount an EBS Volume for the data dir
/opt/couchbase/bash-commons/mount-ebs-volume \
  --aws-region "${aws_region}" \
  --device-name "${data_volume_device_name}" \
  --mount-point "${data_volume_mount_point}" \
  --owner "${volume_owner}"

# Mount an EBS Volume for the index dir
/opt/couchbase/bash-commons/mount-ebs-volume \
  --aws-region "${aws_region}" \
  --device-name "${index_volume_device_name}" \
  --mount-point "${index_volume_mount_point}" \
  --owner "${volume_owner}"

# To keep this example simple, we are hard-coding the credentials for our cluster in this file in plain text. You
# should NOT do this in production usage!!! Instead, you should use tools such as Vault, Keywhiz, or KMS to fetch
# the credentials at runtime and only ever have the plaintext version in memory.
readonly CLUSTER_USERNAME="admin"
readonly CLUSTER_PASSWORD="password"

# Start Couchbase.
/opt/couchbase/bin/run-couchbase-server \
  --cluster-name "${cluster_asg_name}" \
  --cluster-username "$CLUSTER_USERNAME" \
  --cluster-password "$CLUSTER_PASSWORD" \
  --rest-port "${cluster_port}" \
  --data-dir "${data_volume_mount_point}" \
  --index-dir "${index_volume_mount_point}" \
  --use-public-hostname \
  --wait-for-all-nodes

# We create an RBAC user here for testing. To keep this example simple, we are hard-coding the credentials for this
# user in this file in plain text. You should NOT do this in production usage!!! Instead, you should use tools such as
# Vault, Keywhiz, or KMS to fetch the credentials at runtime and only ever have the plaintext version in memory.
readonly TEST_USER_NAME="test-user"
readonly TEST_USER_PASSWORD="password"
source "/opt/couchbase/bash-commons/couchbase-helpers.sh"
create_rbac_user \
  "127.0.0.1" \
  "${cluster_port}" \
  "${CLUSTER_USERNAME}" \
  "${CLUSTER_PASSWORD}" \
  "${TEST_USER_NAME}" \
  "${TEST_USER_PASSWORD}" \
  "cluster_admin"

# We create a bucket here for testing. If there are no buckets at all, Sync Gateway fails to start.
readonly TEST_BUCKET_NAME="test-bucket"
create_bucket \
  "127.0.0.1" \
  "${cluster_port}" \
  "${CLUSTER_USERNAME}" \
  "${CLUSTER_PASSWORD}" \
  "$TEST_BUCKET_NAME"

# Start Sync Gateway
/opt/couchbase-sync-gateway/bin/run-sync-gateway \
  --auto-fill-asg "<SERVERS>=${cluster_asg_name}:${cluster_port}" \
  --auto-fill "<INTERFACE>=${sync_gateway_interface}" \
  --auto-fill "<ADMIN_INTERFACE>=${sync_gateway_admin_interface}" \
  --auto-fill "<DB_NAME>=${cluster_asg_name}" \
  --auto-fill "<BUCKET_NAME>=$TEST_BUCKET_NAME" \
  --auto-fill "<DB_USERNAME>=$TEST_USER_NAME" \
  --auto-fill "<DB_PASSWORD>=$TEST_USER_PASSWORD" \
  --use-public-hostname
