#!/bin/bash

set -e

readonly ASSERTIONS_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$ASSERTIONS_SCRIPT_DIR/logging.sh"

# Check that the given binary is available on the PATH. If it's not, exit with an error.
function assert_is_installed {
  local readonly name="$1"

  if [[ ! $(command -v ${name}) ]]; then
    log_error "The binary '$name' is required by this script but is not installed or in the system's PATH."
    exit 1
  fi
}

# Check that the value of the given arg is not empty. If it is, exit with an error.
function assert_not_empty {
  local readonly arg_name="$1"
  local readonly arg_value="$2"
  local readonly reason="$3"

  if [[ -z "$arg_value" ]]; then
    log_error "The value for '$arg_name' cannot be empty. $reason"
    print_usage
    exit 1
  fi
}

# Check that the value of the given arg is empty. If it isn't, exit with an error.
function assert_empty {
  local readonly arg_name="$1"
  local readonly arg_value="$2"
  local readonly reason="$3"

  if [[ ! -z "$arg_value" ]]; then
    log_error "The value for '$arg_name' must be empty. $reason"
    print_usage
    exit 1
  fi
}

# Check that the given response from AWS is not empty or null (the null often comes from trying to parse AWS responses
# with jq). If it is, exit with an error.
function assert_not_empty_aws_response {
  local readonly response="$1"
  local readonly description="$2"

  if [[ -z "$response" || "$response" == "null" ]]; then
    log_error "Got empty response for $description"
    exit 1
  fi
}
