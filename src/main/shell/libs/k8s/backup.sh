#!/usr/bin/env bash
# K8S backup library
# Provides etcd backup and restore functions

#######################################
# Create etcd backup
# Arguments:
#   1 - backup_dir: Directory to store backup (optional, uses config default)
# Outputs:
#   Backup file path to stdout
# Returns:
#   0 - Success
#   1 - Failure
#######################################
_k8s_backup_create() {
  local backup_dir="${1:-$(_k8s_get_backup_home)}"

  radp_log_info "Creating etcd backup..."

  # Check if etcdctl is available
  local etcdctl_path="/usr/local/bin/etcdctl"
  if [[ ! -x "$etcdctl_path" ]]; then
    etcdctl_path=$(command -v etcdctl 2>/dev/null)
    if [[ -z "$etcdctl_path" ]]; then
      radp_log_error "etcdctl not found. Please install etcdctl."
      return 1
    fi
  fi

  # Check if etcd certs exist (skip in dry-run)
  local etcd_ca="/etc/kubernetes/pki/etcd/ca.crt"
  local etcd_cert="/etc/kubernetes/pki/etcd/server.crt"
  local etcd_key="/etc/kubernetes/pki/etcd/server.key"

  if ! radp_is_dry_run; then
    for file in "$etcd_ca" "$etcd_cert" "$etcd_key"; do
      if [[ ! -f "$file" ]]; then
        radp_log_error "etcd certificate not found: $file"
        return 1
      fi
    done
  fi

  # Generate backup filename with timestamp
  local timestamp
  timestamp=$(date +%Y%m%d%H%M%S)
  local backup_file="$backup_dir/etcd-snapshot-${timestamp}.db"

  radp_log_info "Backup file: $backup_file"

  # Create backup directory if needed
  radp_exec_sudo "Create backup directory" mkdir -p "$backup_dir" || {
    radp_log_error "Failed to create backup directory: $backup_dir"
    return 1
  }

  # Create snapshot
  radp_exec_sudo "Create etcd snapshot" \
    env ETCDCTL_API=3 "$etcdctl_path" snapshot save "$backup_file" \
      --endpoints=https://127.0.0.1:2379 \
      --cacert="$etcd_ca" \
      --cert="$etcd_cert" \
      --key="$etcd_key" || {
    radp_log_error "Failed to create etcd snapshot"
    return 1
  }

  # Verify backup (skip in dry-run)
  if ! radp_is_dry_run; then
    local etcdutl_path="/usr/local/bin/etcdutl"
    if [[ ! -x "$etcdutl_path" ]]; then
      etcdutl_path=$(command -v etcdutl 2>/dev/null)
    fi

    if [[ -n "$etcdutl_path" ]]; then
      $gr_sudo "$etcdutl_path" snapshot status "$backup_file" || {
        radp_log_warn "Backup verification failed, but file may still be valid"
      }
    else
      ETCDCTL_API=3 $gr_sudo "$etcdctl_path" snapshot status "$backup_file" 2>/dev/null || true
    fi
  fi

  radp_log_info "etcd backup created successfully: $backup_file"
  echo "$backup_file"
  return 0
}

#######################################
# Restore etcd from backup
# Arguments:
#   1 - backup_file: Path to backup file to restore
#   2 - data_dir: etcd data directory (optional, default: /var/lib/etcd)
# Returns:
#   0 - Success
#   1 - Failure
# Note:
#   This is a destructive operation. Ensure you understand the implications.
#######################################
_k8s_backup_restore() {
  local backup_file="${1:?'Backup file required'}"
  local data_dir="${2:-/var/lib/etcd}"

  radp_log_warn "Restoring etcd from backup. This is a destructive operation!"
  radp_log_info "Backup file: $backup_file"
  radp_log_info "Data directory: $data_dir"

  # Validate backup file (skip in dry-run)
  if ! radp_is_dry_run; then
    if [[ ! -f "$backup_file" ]]; then
      radp_log_error "Backup file not found: $backup_file"
      return 1
    fi
  fi

  # Check if etcdctl/etcdutl is available
  local restore_cmd=""
  if _common_is_command_available etcdutl; then
    restore_cmd="etcdutl"
  elif [[ -x /usr/local/bin/etcdutl ]]; then
    restore_cmd="/usr/local/bin/etcdutl"
  elif _common_is_command_available etcdctl; then
    restore_cmd="etcdctl"
  elif [[ -x /usr/local/bin/etcdctl ]]; then
    restore_cmd="/usr/local/bin/etcdctl"
  else
    radp_log_error "Neither etcdutl nor etcdctl found"
    return 1
  fi

  # Check etcd certs
  local etcd_ca="/etc/kubernetes/pki/etcd/ca.crt"
  local etcd_cert="/etc/kubernetes/pki/etcd/server.crt"
  local etcd_key="/etc/kubernetes/pki/etcd/server.key"

  # Stop kubelet to prevent etcd from being restarted
  radp_log_info "Stopping kubelet..."
  radp_exec_sudo "Stop kubelet" systemctl stop kubelet || true

  # Wait for etcd pod to stop
  if ! radp_is_dry_run; then
    sleep 5
  fi

  # Backup current data directory
  if ! radp_is_dry_run && [[ -d "$data_dir" ]]; then
    local backup_current="$data_dir.backup.$(date +%Y%m%d%H%M%S)"
    radp_log_info "Backing up current data to: $backup_current"
    radp_exec_sudo "Backup current etcd data" mv "$data_dir" "$backup_current" || {
      radp_log_error "Failed to backup current data directory"
      return 1
    }
  fi

  # Restore snapshot
  radp_log_info "Restoring etcd snapshot..."
  radp_exec_sudo "Restore etcd snapshot" \
    env ETCDCTL_API=3 "$restore_cmd" snapshot restore "$backup_file" \
      --data-dir="$data_dir" \
      --endpoints=https://127.0.0.1:2379 \
      --cacert="$etcd_ca" \
      --cert="$etcd_cert" \
      --key="$etcd_key" || {
    radp_log_error "Failed to restore etcd snapshot"
    # Try to restore original data (only in non-dry-run)
    if ! radp_is_dry_run && [[ -d "${backup_current:-}" ]]; then
      $gr_sudo mv "$backup_current" "$data_dir"
    fi
    return 1
  }

  # Start kubelet
  radp_log_info "Starting kubelet..."
  radp_exec_sudo "Start kubelet" systemctl start kubelet

  radp_log_info "etcd restored successfully!"
  radp_log_warn "Please verify cluster health: homelabctl k8s health"
  return 0
}

#######################################
# List available etcd backups
# Arguments:
#   1 - backup_dir: Directory containing backups (optional)
# Outputs:
#   List of backup files with timestamps
# Returns:
#   0 - Success
#   1 - No backups found or error
#######################################
_k8s_backup_list() {
  local backup_dir="${1:-$(_k8s_get_backup_home)}"

  if [[ ! -d "$backup_dir" ]]; then
    radp_log_info "No backup directory found: $backup_dir"
    return 1
  fi

  local backups
  backups=$(ls -lt "$backup_dir"/etcd-snapshot-*.db 2>/dev/null)

  if [[ -z "$backups" ]]; then
    radp_log_info "No backups found in: $backup_dir"
    return 1
  fi

  radp_log_info "Available backups in $backup_dir:"
  echo ""
  echo "SIZE       DATE                 FILENAME"
  echo "---------- -------------------- ----------------------------------------"

  while IFS= read -r line; do
    local size date time filename
    size=$(echo "$line" | awk '{print $5}')
    date=$(echo "$line" | awk '{print $6, $7, $8}')
    filename=$(echo "$line" | awk '{print $NF}')

    # Convert size to human readable
    if [[ $size -gt 1073741824 ]]; then
      size="$(echo "scale=1; $size / 1073741824" | bc)G"
    elif [[ $size -gt 1048576 ]]; then
      size="$(echo "scale=1; $size / 1048576" | bc)M"
    elif [[ $size -gt 1024 ]]; then
      size="$(echo "scale=1; $size / 1024" | bc)K"
    fi

    printf "%-10s %-20s %s\n" "$size" "$date" "$(basename "$filename")"
  done <<<"$backups"

  return 0
}

#######################################
# Cleanup old backups based on retention policy
# Arguments:
#   1 - keep_days: Number of days to keep (optional, uses config default)
#   2 - backup_dir: Directory containing backups (optional)
# Returns:
#   0 - Success
#   1 - Failure
#######################################
_k8s_backup_cleanup() {
  local keep_days="${1:-$(_k8s_get_backup_keep_days)}"
  local backup_dir="${2:-$(_k8s_get_backup_home)}"

  if [[ ! -d "$backup_dir" ]]; then
    radp_log_debug "No backup directory found: $backup_dir"
    return 0
  fi

  radp_log_info "Cleaning up backups older than $keep_days days..."

  # In dry-run mode, just show what would be deleted
  if radp_is_dry_run; then
    local files
    files=$(find "$backup_dir" -name "etcd-snapshot-*.db" -type f -mtime +"$keep_days" 2>/dev/null)
    if [[ -n "$files" ]]; then
      radp_log_info "[DRY-RUN] Would delete:"
      echo "$files" | while read -r f; do
        radp_log_info "  - $(basename "$f")"
      done
    else
      radp_log_info "No old backups to clean up"
    fi
    return 0
  fi

  local count
  count=$(find "$backup_dir" -name "etcd-snapshot-*.db" -type f -mtime +"$keep_days" 2>/dev/null | wc -l)

  if [[ $count -eq 0 ]]; then
    radp_log_info "No old backups to clean up"
    return 0
  fi

  radp_log_info "Removing $count old backup(s)..."
  find "$backup_dir" -name "etcd-snapshot-*.db" -type f -mtime +"$keep_days" -delete || {
    radp_log_error "Failed to clean up old backups"
    return 1
  }

  radp_log_info "Cleanup completed"
  return 0
}
