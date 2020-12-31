#!/bin/bash
# A simple helper for mounting EBS volumes 

set -e

source "/opt/gruntwork/bash-commons/log.sh"

# This method is used to configure a new EBS volume. It formats the specified device name using ext4 and mounts it at
# the given mount point, with the given OS user as owner.
function mount_volume {
  local device_name="$1"
  local readonly mount_point="$2"
  local readonly ebs_size="$3"
  local readonly owner="$4"
  local readonly file_system_type="${5:-ext4}"
  local readonly mount_options="${6:-defaults,nofail}"
  local readonly fs_tab_path="/etc/fstab"

  # check if the expected device name exists
  # if not, likely is a nitro based instance and need to get the nvmeXn1 device name
  if [ ! -e $device_name ]; then
    log_info "Device not found with name '$device_name' looking up by size '${ebs_size}'"
    disk_name=`lsblk -do NAME,SIZE | grep ${ebs_size}G | cut -d ' ' -f 1`
    if [[ "$disk_name" == nvme* ]]; then
      ebs_device_name="/dev/${disk_name}"
      log_info "Update device_name with '$ebs_device_name'"
      device_name=$ebs_device_name
    fi
  fi

  case "$file_system_type" in
    "ext4")
      log_info "Creating $file_system_type file system on $device_name..."
      mkfs.ext4 -F "$device_name"
      ;;
    "xfs")
      log_info "Creating $file_system_type file system on $device_name..."
      mkfs.xfs -f "$device_name"
      ;;
    *)
      log_error "The file system type '$file_system_type' is not currently supported by this script."
      exit 1
  esac

  log_info "Creating mount point $mount_point..."
  mkdir "$mount_point"

  log_info "Adding device $device_name to $fs_tab_path with mount point $mount_point..."
  echo "$device_name       $mount_point   $file_system_type    $mount_options  0 2" >> "$fs_tab_path"

  log_info "Mounting volumes..."
  mount -a

  log_info "Changing ownership of $mount_point to $owner..."
  chown "$owner" "$mount_point"
}