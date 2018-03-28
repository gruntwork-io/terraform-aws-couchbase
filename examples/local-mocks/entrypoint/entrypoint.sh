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
# it using systemd as well! The Docker Compose file mounts the run-user-data systemd unit and this
# command tells systemd to run that unit once we fire up systemd below.
systemctl enable run-user-data

# Run systemd. Note that systemd must run as PID 1, so we use exec to let it take over the process ID of this
# entrypoint script.
exec /sbin/init