#!/bin/bash

set -e

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/logging.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/strings.sh"

readonly COUCHBASE_BASE_DIR="/opt/couchbase"
readonly COUCHBASE_BIN_DIR="$COUCHBASE_BASE_DIR/bin"
readonly COUCHBASE_CLI="$COUCHBASE_BIN_DIR/couchbase-cli"

function create_rbac_user {
  local readonly node_hostname="$1"
  local readonly rest_port="$2"
  local readonly cluster_username="$3"
  local readonly cluster_password="$4"
  local readonly user_name="$5"
  local readonly user_password="$6"
  shift 6
  local readonly roles=($@)

  local readonly roles_str="$(join "," "${roles[@]}")"
  log_info "Creating user $user_name for testing in cluster $node_hostname:$rest_port with roles $roles_str"

  local create_user_args=()
  create_user_args+=("user-manage")
  create_user_args+=("--cluster=$node_hostname:$rest_port")
  create_user_args+=("--username=$cluster_username")
  create_user_args+=("--password=$cluster_password")
  create_user_args+=("--set")
  create_user_args+=("--rbac-username=$user_name")
  create_user_args+=("--rbac-password=$user_password")
  create_user_args+=("--rbac-name=$user_name")
  create_user_args+=("--roles=$roles_str")
  create_user_args+=("--auth-domain=local")

  set +e
  local out
  out=$("$COUCHBASE_CLI" "${create_user_args[@]}")
  set -e

  if string_contains "$out" "SUCCESS: RBAC user set"; then
    log_info "Successfully created user $user_name in cluster $node_hostname:$rest_port."
  else
    log_error "Failed to create user $user_name in cluster $node_hostname:$rest_port. Log output:\n$out."
    exit 1
  fi
}

function create_bucket {
  local readonly node_hostname="$1"
  local readonly rest_port="$2"
  local readonly username="$3"
  local readonly password="$4"
  local readonly bucket_name="$5"

  log_info "Creating bucket $bucket_name in cluster $node_hostname:$rest_port for testing"

  local create_bucket_args=()
  create_bucket_args+=("bucket-create")
  create_bucket_args+=("--cluster=$node_hostname:$rest_port")
  create_bucket_args+=("--username=$username")
  create_bucket_args+=("--password=$password")
  create_bucket_args+=("--bucket=$bucket_name")
  create_bucket_args+=("--bucket-type=couchbase")
  create_bucket_args+=("--bucket-ramsize=100")

  set +e
  local out
  out=$("$COUCHBASE_CLI" "${create_bucket_args[@]}")
  set -e

  if string_contains "$out" "SUCCESS: Bucket created"; then
    log_info "Successfully created bucket $bucket_name in cluster $node_hostname:$rest_port."
  elif string_contains "$out" "ERROR: name - Bucket with given name already exists"; then
    log_warn "Bucket $bucket_name already exists in cluster $node_hostname:$rest_port. Will not create again."
  else
    log_error "Failed to create bucket $bucket_name in cluster $node_hostname:$rest_port. Log output:\n$out."
    exit 1
  fi
}
