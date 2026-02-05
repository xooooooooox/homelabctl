#!/usr/bin/env bash
# @cmd
# @desc Expand LVM partition and filesystem to use all available disk space
# @option --partition <dev> LVM partition to expand (e.g., /dev/sda3). Auto-detected if not specified.
# @option --vg <name> Volume group name. Auto-detected if not specified.
# @option --lv <name> Logical volume to expand. Auto-detected if not specified.
# @flag --dry-run Show what would be done without making changes
# @example setup configure expand-lvm
# @example setup configure expand-lvm --partition /dev/sda3 --vg ubuntu-vg --lv ubuntu-lv

cmd_setup_configure_expand_lvm() {
  local partition="${opt_partition:-}"
  local vg="${opt_vg:-}"
  local lv="${opt_lv:-}"

  # Set dry-run mode from flag
  radp_set_dry_run "${opt_dry_run:-}"

  radp_log_info "Expanding LVM partition and filesystem..."

  # Install growpart if needed
  if ! _expand_lvm_install_growpart; then
    return 1
  fi

  # Detect LVM configuration
  partition=$(_expand_lvm_detect_partition "$partition") || return 1
  vg=$(_expand_lvm_detect_vg "$vg") || return 1
  lv=$(_expand_lvm_detect_lv "$lv") || return 1

  if [[ -z "$partition" ]] || [[ -z "$vg" ]] || [[ -z "$lv" ]]; then
    radp_log_error "Cannot auto-detect LVM configuration"
    radp_log_error "  Partition: ${partition:-not found}"
    radp_log_error "  VG: ${vg:-not found}"
    radp_log_error "  LV: ${lv:-not found}"
    return 1
  fi

  local disk part_num lv_path fs_type
  disk=$(_expand_lvm_get_disk "$partition")
  part_num=$(_expand_lvm_get_part_num "$partition")
  lv_path="/dev/${vg}/${lv}"
  fs_type=$(lsblk -no FSTYPE "$lv_path" 2>/dev/null | head -1)

  radp_log_info "Detected configuration:"
  radp_log_info "  Disk: $disk"
  radp_log_info "  Partition: $partition (partition $part_num)"
  radp_log_info "  Volume Group: $vg"
  radp_log_info "  Logical Volume: $lv ($lv_path)"
  radp_log_info "  Filesystem: $fs_type"

  radp_log_info "Current disk layout:"
  lsblk "$disk"

  # Step 1: Expand partition
  radp_log_info "Step 1: Expanding partition $partition..."
  if radp_exec_sudo "Expand partition $partition" growpart "$disk" "$part_num" 2>&1; then
    radp_log_info "Partition expanded"
  else
    radp_log_info "Partition may already be at maximum size (this is OK)"
  fi

  # Step 2: Resize PV
  radp_log_info "Step 2: Resizing physical volume $partition..."
  radp_exec_sudo "Resize physical volume $partition" pvresize "$partition"
  radp_log_info "PV resized"

  # Step 3: Extend LV
  radp_log_info "Step 3: Extending logical volume $lv_path..."
  radp_exec_sudo "Extend logical volume $lv_path" lvextend -l +100%FREE "$lv_path" 2>&1 || radp_log_info "LV may already be at maximum size"
  radp_log_info "LV extended"

  # Step 4: Resize filesystem
  radp_log_info "Step 4: Resizing filesystem ($fs_type)..."
  case "$fs_type" in
    ext4|ext3|ext2)
      radp_exec_sudo "Resize ext filesystem on $lv_path" resize2fs "$lv_path"
      ;;
    xfs)
      radp_exec_sudo "Grow XFS filesystem on $lv_path" xfs_growfs "$lv_path"
      ;;
    *)
      radp_log_warn "Unknown filesystem type: $fs_type. Skipping filesystem resize."
      ;;
  esac
  radp_log_info "Filesystem resized"

  if ! radp_is_dry_run; then
    radp_log_info "Final disk layout:"
    lsblk "$disk"

    radp_log_info "Filesystem usage:"
    df -h "$lv_path"
  fi

  radp_log_info "LVM expansion completed successfully"
}

_expand_lvm_install_growpart() {
  if _common_is_command_available growpart; then
    radp_log_info "growpart is already installed"
    return 0
  fi

  radp_log_info "Installing growpart..."

  local pm
  pm=$(radp_os_get_distro_pm)

  case "$pm" in
    apt|apt-get)
      radp_exec_sudo "Update apt cache" apt-get update -qq
      radp_exec_sudo "Install cloud-guest-utils" apt-get install -y cloud-guest-utils
      ;;
    dnf)
      radp_exec_sudo "Install cloud-utils-growpart" dnf install -y cloud-utils-growpart
      ;;
    yum)
      radp_exec_sudo "Install cloud-utils-growpart" yum install -y cloud-utils-growpart
      ;;
    *)
      radp_log_error "Cannot install growpart: unsupported package manager"
      return 1
      ;;
  esac

  radp_log_info "growpart installed"
}

_expand_lvm_detect_partition() {
  local partition="$1"

  if [[ -n "$partition" ]]; then
    echo "$partition"
    return 0
  fi

  local root_device root_vg pv_device
  root_device=$(findmnt -n -o SOURCE / 2>/dev/null | head -1)

  if [[ -z "$root_device" ]]; then
    radp_log_error "Cannot determine root filesystem device"
    return 1
  fi

  if [[ "$root_device" == /dev/mapper/* ]] || [[ "$root_device" == /dev/dm-* ]]; then
    root_vg=$(${gr_sudo:-} lvs --noheadings -o vg_name "$root_device" 2>/dev/null | tr -d ' ')
    if [[ -z "$root_vg" ]]; then
      radp_log_error "Cannot determine volume group for root"
      return 1
    fi

    pv_device=$(${gr_sudo:-} pvs --noheadings -o pv_name -S "vg_name=$root_vg" 2>/dev/null | tr -d ' ' | head -1)
    if [[ -z "$pv_device" ]]; then
      radp_log_error "Cannot find PV for VG $root_vg"
      return 1
    fi

    echo "$pv_device"
  else
    radp_log_error "Root filesystem is not on LVM"
    return 1
  fi
}

_expand_lvm_detect_vg() {
  local vg="$1"

  if [[ -n "$vg" ]]; then
    echo "$vg"
    return 0
  fi

  local root_device vg_name
  root_device=$(findmnt -n -o SOURCE / 2>/dev/null | head -1)

  if [[ "$root_device" == /dev/mapper/* ]] || [[ "$root_device" == /dev/dm-* ]]; then
    vg_name=$(${gr_sudo:-} lvs --noheadings -o vg_name "$root_device" 2>/dev/null | tr -d ' ')
    echo "$vg_name"
  fi
}

_expand_lvm_detect_lv() {
  local lv="$1"

  if [[ -n "$lv" ]]; then
    echo "$lv"
    return 0
  fi

  local root_device lv_name
  root_device=$(findmnt -n -o SOURCE / 2>/dev/null | head -1)

  if [[ "$root_device" == /dev/mapper/* ]] || [[ "$root_device" == /dev/dm-* ]]; then
    lv_name=$(${gr_sudo:-} lvs --noheadings -o lv_name "$root_device" 2>/dev/null | tr -d ' ')
    echo "$lv_name"
  fi
}

_expand_lvm_get_disk() {
  local partition="$1"
  if [[ "$partition" =~ ^/dev/nvme ]]; then
    echo "${partition%p[0-9]*}"
  else
    echo "${partition%%[0-9]*}"
  fi
}

_expand_lvm_get_part_num() {
  local partition="$1"
  if [[ "$partition" =~ ^/dev/nvme ]]; then
    echo "${partition##*p}"
  else
    echo "${partition##*[a-z]}"
  fi
}
