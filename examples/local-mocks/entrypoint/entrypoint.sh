#!/bin/bash

set -e

# To start systemd, we have to run /sbin/init at the end of the script. However, that doesn't give us any useful log
# output from our container, so here, we tail a couple useful log files in the background, so the logs still end up
# in stdout, but this script can keep on running.
readonly COUCHBASE_LOGS_DIR="/opt/couchbase/var/lib/couchbase/logs"
readonly SYNC_GATEWAY_LOGS_DIR="/home/sync_gateway/logs"
tail -f --retry \
  "$COUCHBASE_LOGS_DIR/couchdb.log" \
  "$COUCHBASE_LOGS_DIR/mock-user-data.log" \
  "$SYNC_GATEWAY_LOGS_DIR/sync-gateway.log" \
  2>/dev/null &

# We need systemd to run to fire up Couchbase itself. To run systemd, we have to run /sbin/init at the end of this
# script. So how can we run the code we need on boot that normally lives in User Data? Well, our solution is to run
# it using systemd as well! We create a SystemD unit here that will execute our User Data script on boot. The User
# Data script is specified as an environment variable in docker-compose.yml.

cat << EOF > /lib/systemd/system/run-user-data.service
[Unit]
Description=Mock Run Couchbase Script
Documentation=https://github.com/gruntwork-io/terraform-aws-couchbase
After=couchbase-server.service

[Service]
User=root
WorkingDirectory=/opt/couchbase/bin
ExecStart=$USER_DATA_SCRIPT
Restart=no
Type=oneshot

# These environment variables would normally be set in the User Data script via Terraform interpolation, but since we
# are not using Terraform in this mock, we insetad set them manually to test-friendly values.
Environment=cluster_asg_name=mock-couchbase-asg
Environment=cluster_port=8091
Environment=sync_gateway_interface=:4984
Environment=sync_gateway_admin_interface=127.0.0.1:4985
Environment=mock_aws_region=us-east-1
Environment=mock_availability_zone=us-east-1a
Environment=data_volume_device_name=/dev/xvdf
Environment=data_volume_mount_point=/couchbase-data
Environment=index_volume_device_name=/dev/xvdg
Environment=index_volume_mount_point=/couchbase-index
Environment=volume_owner=couchbase

[Install]
WantedBy=multi-user.target
EOF

systemctl enable run-user-data

# Run systemd. Note that systemd must run as PID 1, so we use exec to let it take over the process ID of this
# entrypoint script.
exec /sbin/init