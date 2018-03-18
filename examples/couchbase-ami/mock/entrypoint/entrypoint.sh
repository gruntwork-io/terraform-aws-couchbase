#!/bin/bash

set -e

readonly COUCHBASE_LOGS_DIR="/opt/couchbase/var/lib/couchbase/logs"

tail -f --retry \
  "$COUCHBASE_LOGS_DIR/couchdb.log" \
  "$COUCHBASE_LOGS_DIR/mock-user-data.log" &

systemctl enable mock-configure-couchbase-server

exec /sbin/init