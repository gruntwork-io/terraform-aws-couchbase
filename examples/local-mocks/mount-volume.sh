#!/bin/bash
# This script overrides the real mount_volume function with a mock version that can run entirely locally without
# depending on external dependencies, such EC2 Metadata and AWS API calls. This allows us to test all the scripts
# completely locally using Docker.

set -e

source "/opt/gruntwork/bash-commons/log.sh"

function mount_volume {
  local -r device_name="$1"
  local -r mount_point="$2"
  local -r owner="$3"

  log_info "Running MOCK version of mount_volume. Instead of mounting a real volume, will simply create a folder at $mount_point owned by $owner."
  sudo mkdir -p "$mount_point"
  sudo chown -R "$owner:$owner" "$mount_point"
}
