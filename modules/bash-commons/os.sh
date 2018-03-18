#!/bin/bash

set -e

# Return the available memory on the current OS in MB
function get_available_memory_mb {
  local available_memory_kb
  available_memory_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')

  # Convert from KB to MB
  echo "$(( $available_memory_kb / 1000 ))"
}

# Returns true if this script is executing on an Ubuntu server
function is_ubuntu {
  grep -q "Ubuntu" /etc/os-release
}
