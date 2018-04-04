#!/bin/bash

set -e

# Return the available memory on the current OS in MB
function get_available_memory_mb {
  free -m | awk 'NR==2{print $2}'
}

# Returns true (0) if this is an Amazon Linux server at the given version or false (1) otherwise.
function is_amazon_linux {
  local readonly version="$1"
  grep -q "Amazon Linux release $version" /etc/*release
}

# Returns true (0) if this is an Ubuntu server at the given version or false (1) otherwise.
function is_ubuntu {
  local readonly version="$1"
  grep -q "Ubuntu $version" /etc/*release
}
