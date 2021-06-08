#!/bin/bash

set -e

source "/opt/gruntwork/bash-commons/log.sh"
source "/opt/gruntwork/bash-commons/string.sh"
source "/opt/gruntwork/bash-commons/assert.sh"
source "/opt/gruntwork/bash-commons/aws-wrapper.sh"

readonly COUCHBASE_BASE_DIR="/opt/couchbase"
readonly COUCHBASE_BIN_DIR="$COUCHBASE_BASE_DIR/bin"
readonly COUCHBASE_CLI="$COUCHBASE_BIN_DIR/couchbase-cli"

# Run the Couchbase CLI
function run_couchbase_cli {
  local -r args=($@)

  # The Couchbase CLI may exit with an error, but we almost always want to ignore that and make decision based on
  # stdout instead, so we temporarily disable exit on error
  set +e
  local out
  "$COUCHBASE_CLI" "${args[@]}"
  set -e
}

# Run the Couchbase CLI and retry until its stdout contains the expected message or max retries is exceeded.
function run_couchbase_cli_with_retry {
  local -r cmd_description="$1"
  local -r expected_message="$2"
  local -r max_retries="$3"
  local -r sleep_between_retries_sec="$4"
  shift 4
  local -r args=($@)

  for (( i=0; i<"$max_retries"; i++ )); do
    local out
    out=$(run_couchbase_cli "${args[@]}")

    if string_contains "$out" "$expected_message"; then
      log_info "Success: $cmd_description."
      return
    else
      log_warn "Failed to $cmd_description. Will sleep for $sleep_between_retries_sec seconds and try again. couchbase-cli output:\n$out"
      sleep "$sleep_between_retries_sec"
    fi
  done

  log_error "Failed to $cmd_description after $max_retries retries."
  exit 1
}

# Returns true (0) if the Couchbase cluster has already been initialized and false otherwise.
function cluster_is_initialized {
  local -r cluster_url="$1"
  local -r cluster_username="$2"
  local -r cluster_password="$3"

  local cluster_status
  cluster_status=$(get_cluster_status "$cluster_url" "$cluster_username" "$cluster_password")

  string_contains "$cluster_status" "healthy active"
}

# Returns true if the Couchbase server at the given hostname has booted. Note that this ONLY checks if the Couchbase
# process is running and responding to queries; it does NOT check if the Couchbase server has joined the cluster and is
# active.
function couchbase_is_running {
  local -r node_url="$1"
  local -r username="$2"
  local -r password="$3"

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
  local -r cluster_url="$1"
  local -r cluster_username="$2"
  local -r cluster_password="$3"

  log_info "Looking up server status in $cluster_url"

  local server_list_args=()
  server_list_args+=("server-list")
  server_list_args+=("--cluster=$cluster_url")
  server_list_args+=("--username=$cluster_username")
  server_list_args+=("--password=$cluster_password")

  run_couchbase_cli "${server_list_args[@]}"
}

# Returns true if the node with the given hostname has already been added (via the server-add command) to the Couchbase
# cluster. Note that this does NOT necessarily mean the new node is active; in order for the node to be active, you
# not only need to add it, but also rebalance the cluster. See also node_is_active_in_cluster.
function node_is_added_to_cluster {
  local -r cluster_url="$1"
  local -r cluster_username="$2"
  local -r cluster_password="$3"
  local -r node_url="$4"

  local cluster_status
  cluster_status=$(get_cluster_status "$cluster_url" "$cluster_username" "$cluster_password")

  string_multiline_contains "$cluster_status" "$node_url healthy"
}

# Returns true if the node with the given hostname has already been added (via the server-add command) to the Couchbase
# cluster and is active (via the rebalance command).
function node_is_active_in_cluster {
  local -r cluster_url="$1"
  local -r cluster_username="$2"
  local -r cluster_password="$3"
  local -r node_url="$4"

  local cluster_status
  cluster_status=$(get_cluster_status "$cluster_url" "$cluster_username" "$cluster_password")

  string_multiline_contains "$cluster_status" "$node_url healthy active"
}

# Returns true (0) if the cluster is balanced and false (1) otherwise
function cluster_is_balanced {
  local -r cluster_url="$1"
  local -r cluster_username="$2"
  local -r cluster_password="$3"

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

  [[ "$status" != "running" ]]
}

# Return true (0) if the given bucket exists in the given cluster and false (0) otherwise
function has_bucket {
  local -r cluster_url="$1"
  local -r cluster_username="$2"
  local -r cluster_password="$3"
  local -r bucket_name="$4"

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
  string_multiline_contains "$out" "^$bucket_name$"
}

# Wait until the specified cluster is initialized and not rebalancing
function wait_for_couchbase_cluster {
  local -r cluster_url="$1"
  local -r cluster_username="$2"
  local -r cluster_password="$3"

  local -r retries=200
  local -r sleep_between_retries=5

  for (( i=0; i<"$retries"; i++ )); do
    if cluster_is_ready "$cluster_url" "$cluster_username" "$cluster_password"; then
      log_info "Cluster $cluster_url is ready!"
      return
    else
      log_warn "Cluster $cluster_url is not yet ready. Will sleep for $sleep_between_retries seconds and check again."
      sleep "$sleep_between_retries"
    fi
  done

  log_error "Cluster $cluster_url still not initialized after $retries retries."
  exit 1
}

# Return true (0) if the cluster is initialized and not rebalancing and false (1) otherwise
function cluster_is_ready {
  local -r cluster_url="$1"
  local -r cluster_username="$2"
  local -r cluster_password="$3"

  if ! cluster_is_initialized "$cluster_url" "$cluster_username" "$cluster_password"; then
    log_warn "Cluster $cluster_url is not yet initialized."
    return 1
  fi

  if ! cluster_is_balanced "$cluster_url" "$cluster_username" "$cluster_password"; then
    log_warn "Cluster $cluster_url is currently rebalancing."
    return 1
  fi

  return 0
}

# Wait until the specified bucket exists in the specified cluster
function wait_for_bucket {
  local -r cluster_url="$1"
  local -r cluster_username="$2"
  local -r cluster_password="$3"
  local -r bucket="$4"

  local -r retries=200
  local -r sleep_between_retries=5

  for (( i=0; i<"$retries"; i++ )); do
    if has_bucket "$cluster_url" "$cluster_username" "$cluster_password" "$bucket"; then
      log_info "Bucket $bucket exists in cluster $cluster_url."
      return
    else
      log_warn "Bucket $bucket does not yet exist in cluster $cluster_url. Will sleep for $sleep_between_retries seconds and check again."
      sleep "$sleep_between_retries"
    fi
  done

  log_error "Bucket $bucket still does not exist in cluster $cluster_url after $retries retries."
  exit 1
}


# Identify the server to use as a "rally point." This is the "leader" of the cluster that can be used to initialize
# the cluster and kick off replication. We use a simple technique to identify a unique rally point in each ASG: look
# up all the Instances in the ASG and select the one with the oldest launch time. If there is a tie, pick the one with
# the lowest Instance ID (alphabetically). This way, all servers will always select the same server as the rally point.
# If the rally point server dies, all servers will then select the next oldest launch time / lowest Instance ID.
function get_rally_point_hostname {
  local -r aws_region="$1"
  local -r asg_name="$2"
  local -r use_public_hostname="$3"

  log_info "Looking up rally point for ASG $asg_name in $aws_region"

  local instances
  instances=$(aws_wrapper_wait_for_instances_in_asg "$asg_name" "$aws_region")
  assert_not_empty_or_null "$instances" "Fetch list of Instances in ASG $asg_name"

  local rally_point
  rally_point=$(echo "$instances" | jq -r '[.Reservations[].Instances[]] | sort_by(.LaunchTime, .InstanceId) | .[0]')
  assert_not_empty_or_null "$rally_point" "Select rally point server in ASG $asg_name"

  local hostname_field=".PrivateDnsName"
  if [[ "$use_public_hostname" == "true" ]]; then
    hostname_field=".PublicDnsName"
  fi

  local hostname
  hostname=$(echo "$rally_point" | jq -r "$hostname_field")
  assert_not_empty_or_null "$hostname" "Get hostname from field $hostname_field for rally point in $asg_name: $rally_point"

  echo -n "$hostname"
}
