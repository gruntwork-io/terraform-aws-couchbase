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

# We create a bucket here solely for testing. If there are no buckets at all, Sync Gateway fails to start. In
# production usage, you'd probably create the Couchbase cluster first, create buckets manually, and then start Sync
# Gateway, so you probably don't need this.
readonly TEST_BUCKET_NAME="test-bucket"

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
  --rally-point-port "${cluster_port}" \
  --rest-port "${cluster_port}" \
  --create-bucket-for-testing "$TEST_BUCKET_NAME"

# Start Sync Gateway
/opt/couchbase-sync-gateway/bin/run-sync-gateway \
  --auto-fill-asg "<SERVERS>=${cluster_asg_name}:${cluster_port}" \
  --auto-fill "<BUCKET_NAME>=$TEST_BUCKET_NAME" \
  --auto-fill "<INTERFACE>=${sync_gateway_interface}" \
  --auto-fill "<ADMIN_INTERFACE>=${sync_gateway_admin_interface}" \
  --auto-fill "<DB_NAME>=${cluster_asg_name}" \
  --auto-fill "<DB_USERNAME>=$CLUSTER_USERNAME" \
  --auto-fill "<DB_PASSWORD>=$CLUSTER_PASSWORD"
