#!/bin/bash

set -e

# To start systemd, we have to run /sbin/init at the end of the script. However, that doesn't give us any useful log
# output from our container, so here, we tail a couple useful log files in the background, so the logs still end up
# in stdout, but this script can keep on running.
readonly COUCHBASE_LOGS_DIR="/opt/couchbase/var/lib/couchbase/logs"
tail -f --retry \
  "$COUCHBASE_LOGS_DIR/couchdb.log" \
  "$COUCHBASE_LOGS_DIR/mock-user-data.log" &

# Here, we pass env vars set in docker-compose.yml in an env file that will be read by mock-run-couchbase-server (for
# some reason, systemd services don't see any of the env vars from Docker Compose) and passed to the 
# run-couchbase-server script. We need to override ports because we are using host networking, so each Couchbase 
# Docker container needs unique port numbers. See docker-compose.yml for more info.
readonly ENV_FILE_PATH="/env/entrypoint.env"
mkdir -p "$(dirname "$ENV_FILE_PATH")"
echo "rest_port=$REST_PORT" >> "$ENV_FILE_PATH"
echo "capi_port=$CAPI_PORT" >> "$ENV_FILE_PATH"
echo "query_port=$QUERY_PORT" >> "$ENV_FILE_PATH"
echo "fts_port=$SEARCH_PORT" >> "$ENV_FILE_PATH"
echo "memcached_port=$MEMCACHED_PORT" >> "$ENV_FILE_PATH"
echo "xdcr_port=$XDCR_PORT" >> "$ENV_FILE_PATH"

# We need systemd to run to fire up Couchbase itself. To run systemd, we have to run /sbin/init at the end of this
# script. So how can we run the code we need on boot that normally lives in User Data? Well, our solution is to run
# it using systemd as well! The Docker Compose file mounts the mock-run-couchbase-server systemd unit and this
# command tells systemd to run that unit once we fire up systemd below.
systemctl enable mock-run-couchbase-server

# Run systemd. Note that systemd must run as PID 1, so we use exec to let it take over the process ID of this
# entrypoint script.
exec /sbin/init