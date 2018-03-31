#!/bin/bash

set -e

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/logging.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/strings.sh"

readonly COUCHBASE_BASE_DIR="/opt/couchbase"
readonly COUCHBASE_BIN_DIR="$COUCHBASE_BASE_DIR/bin"
readonly COUCHBASE_CLI="$COUCHBASE_BIN_DIR/couchbase-cli"

# Run the Couchbase CLI
function run_couchbase_cli {
  local readonly args=($@)

  # The Couchbase CLI may exit with an error, but we almost always want to ignore that and make decision based on
  # stdout instead, so we temporarily disable exit on error
  set +e
  local out
  "$COUCHBASE_CLI" "${args[@]}"
  set -e
}

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

  local out
  out=$(run_couchbase_cli "${server_list_args[@]}")

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

# Returns true (0) if the cluster is currently rebalancing and false (1) otherwise
function cluster_is_rebalancing {
  local readonly cluster_url="$1"
  local readonly cluster_username="$2"
  local readonly cluster_password="$3"

  log_info "Checking if cluster $cluster_url is currently rebalancing..."

  local server_list_args=()
  server_list_args+=("rebalance-status")
  server_list_args+=("--cluster=$cluster_url")
  server_list_args+=("--username=$cluster_username")
  server_list_args+=("--password=$cluster_password")

  local out
  out=$(run_couchbase_cli "${server_list_args[@]}")

  local status
  status=$(echo "$out" | jq -r '.status')

  [[ "$status" == "running" ]]
}

# Return true (0) if the given bucket exists in the given cluster and false (0) otherwise
function has_bucket {
  local readonly cluster_url="$1"
  local readonly cluster_username="$2"
  local readonly cluster_password="$3"
  local readonly bucket_name="$4"

  log_info "Checking if bucket $bucket_name exists in $cluster_url"

  local server_list_args=()
  server_list_args+=("bucket-list")
  server_list_args+=("--cluster=$cluster_url")
  server_list_args+=("--username=$cluster_username")
  server_list_args+=("--password=$cluster_password")

  local out
  out=$(run_couchbase_cli "${server_list_args[@]}")

  # The bucket-list output is of the format:
  #
  # <BUCKET_NAME_1>
  #  bucketType: membase
  #  numReplicas: 1
  #  ramQuota: 314572800
  #  ramUsed: 27230952
  # <BUCKET_NAME_2>
  #  bucketType: membase
  #  numReplicas: 1
  #  ramQuota: 314572800
  #  ramUsed: 27230952
  #
  # So all we do is grep for a line that exactly matches the name of the bucket we're looking for
  multiline_string_contains "$out" "^$bucket_name$"
}