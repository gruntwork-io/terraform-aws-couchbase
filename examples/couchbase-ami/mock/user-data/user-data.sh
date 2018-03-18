#!/bin/bash

set -e

# Send the log output from this script to user-data.log, syslog, and the console
# From: https://alestic.com/2010/12/ec2-user-data-output/
exec > >(tee /opt/couchbase/var/lib/couchbase/logs/mock-user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

/opt/couchbase/bin/run-couchbase-server \
  --asg-name "${asg_name}" \
  --cluster-username "${cluster_username}" \
  --cluster-password "${cluster_password}"