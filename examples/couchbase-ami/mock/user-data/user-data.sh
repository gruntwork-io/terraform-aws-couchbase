#!/bin/bash

set -e

# Send the log output from this script to user-data.log, syslog, and the console
# From: https://alestic.com/2010/12/ec2-user-data-output/
exec > >(tee /opt/couchbase/var/lib/couchbase/logs/mock-user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

# The variables below come from mock-couchbase.env or entrypoint.env
/opt/couchbase/bin/run-couchbase-server \
  --cluster-username "${cluster_username}" \
  --cluster-password "${cluster_password}" \
  --rest-port "${rest_port}" \
  --capi-port "${capi_port}" \
  --query-port "${query_port}" \
  --fts-port "${fts_port}" \
  --memcached-port "${memcached_port}" \
  --xdcr-port "${xdcr_port}"
