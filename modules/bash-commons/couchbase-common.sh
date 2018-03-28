#!/bin/bash

set -e

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/logging.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/strings.sh"

readonly COUCHBASE_BASE_DIR="/opt/couchbase"
readonly COUCHBASE_BIN_DIR="$COUCHBASE_BASE_DIR/bin"
readonly COUCHBASE_CLI="$COUCHBASE_BIN_DIR/couchbase-cli"

# Returns true (0) if the Couchbase cluster has already been initialized and false otherwise.
function cluster_is_initialized {
  local readonly cluster_url="$1"
  local readonly cluster_username="$2"
  local readonly cluster_password="$3"

  local cluster_status
  cluster_status=$(get_cluster_status "$cluster_url" "$cluster_username" "$cluster_password")

  string_contains "$cluster_status" "healthy active"
}

# Returns true if the Couchbase server at the given hostname has booted. Note that this ONLY checks if the Couchbase
# process is running and responding to queries; it does NOT check if the Couchbase server has joined the cluster and is
# active.
function couchbase_is_running {
  local readonly node_url="$1"
  local readonly username="$2"
  local readonly password="$3"

  set +e
  local cluster_status
  cluster_status=$(get_cluster_status "$node_url" "$username" "$password")
  set -e

  string_contains "$cluster_status" "healthy active" || string_contains "$cluster_status" "unknown pool"
}

# Get the status of the Couchbase cluster using the server-list command. If the cluster is initialized, returns output
# of the format:
#
# ns_1@172.19.0.2 172.19.0.2:8091 healthy inactiveAdded
# ns_1@172.19.0.3 172.19.0.3:8091 healthy active
# ns_1@172.19.0.4 172.19.0.4:8091 healthy active
#
# Otherwise, returns error text (e.g., "unknown pool") from the server-list command.
function get_cluster_status {
  local readonly cluster_url="$1"
  local readonly cluster_username="$2"
  local readonly cluster_password="$3"

  log_info "Looking up server status in $cluster_url"

  local server_list_args=()
  server_list_args+=("server-list")
  server_list_args+=("--cluster=$cluster_url")
  server_list_args+=("--username=$cluster_username")
  server_list_args+=("--password=$cluster_password")

  # If the cluster is not yet initialized, the server-list command will exit with an error, so make sure that doesn't
  # cause this entire script to exit as a result
  set +e
  local out
  out=$("$COUCHBASE_CLI" "${server_list_args[@]}")
  set -e

  echo -n "$out"
}

# Returns true if the node with the given hostname has already been added (via the server-add command) to the Couchbase
# cluster. Note that this does NOT necessarily mean the new node is active; in order for the node to be active, you
# not only need to add it, but also rebalance the cluster. See also node_is_active_in_cluster.
function node_is_added_to_cluster {
  local readonly cluster_url="$1"
  local readonly cluster_username="$2"
  local readonly cluster_password="$3"
  local readonly node_url="$4"

  local cluster_status
  cluster_status=$(get_cluster_status "$cluster_url" "$cluster_username" "$cluster_password")

  multiline_string_contains "$cluster_status" "$node_url healthy"
}

# Returns true if the node with the given hostname has already been added (via the server-add command) to the Couchbase
# cluster and is active (via the rebalance command).
function node_is_active_in_cluster {
  local readonly cluster_url="$1"
  local readonly cluster_username="$2"
  local readonly cluster_password="$3"
  local readonly node_url="$4"

  local cluster_status
  cluster_status=$(get_cluster_status "$cluster_url" "$cluster_username" "$cluster_password")

  multiline_string_contains "$cluster_status" "$node_url healthy active"
}