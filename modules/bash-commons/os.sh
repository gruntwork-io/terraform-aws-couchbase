#!/bin/bash

set -e

# Return the available memory on the current OS in MB
function get_available_memory_mb {
  free -m | awk 'NR==2{print $2}'
}

# Returns true if this script is executing on an Ubuntu server
function is_ubuntu {
  grep -q "Ubuntu" /etc/os-release
}
