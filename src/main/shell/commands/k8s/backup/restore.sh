#!/usr/bin/env bash
# @cmd
# @desc Restore etcd from backup
# @arg file! Backup file to restore from
# @option --data-dir <path> etcd data directory (default: /var/lib/etcd)
# @flag --dry-run Show what would be done
# @flag --force Skip confirmation prompt
# @example k8s backup restore /var/opt/k8s/backups/etcd/etcd-snapshot-20240101120000.db

cmd_k8s_backup_restore() {
  local backup_file="${args_file}"
  local data_dir="${opt_data_dir:-/var/lib/etcd}"
  local force="${opt_force:-}"

  # Enable dry-run mode if flag is set
  radp_set_dry_run "${opt_dry_run:-false}"

  # Validate backup file exists (skip in dry-run mode)
  if ! radp_is_dry_run && [[ ! -f "$backup_file" ]]; then
    radp_log_error "Backup file not found: $backup_file"
    return 1
  fi

  radp_log_warn "WARNING: This is a destructive operation!"
  radp_log_warn "Restoring etcd will replace all current cluster data."
  radp_log_info ""
  radp_log_info "  Backup file: $backup_file"
  radp_log_info "  Data directory: $data_dir"
  echo ""

  # Skip confirmation in dry-run mode
  if ! radp_is_dry_run && [[ -z "$force" ]]; then
    if ! radp_io_prompt_confirm --msg "Are you sure you want to restore? (y/N)" --default N --timeout 60; then
      radp_log_info "Restore cancelled"
      return 0
    fi
  fi

  _k8s_backup_restore "$backup_file" "$data_dir" || return 1

  radp_log_info ""
  radp_log_info "Restore completed!"
  radp_log_info ""
  radp_log_info "Please verify cluster health:"
  radp_log_info "  homelabctl k8s health"

  return 0
}
