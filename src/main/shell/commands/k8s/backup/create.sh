#!/usr/bin/env bash
# @cmd
# @desc Create etcd backup
# @option -d, --dir <path> Backup directory (default: /var/opt/k8s/backups/etcd)
# @flag --dry-run Show what would be done
# @example k8s backup create
# @example k8s backup create -d /backup/etcd

cmd_k8s_backup_create() {
  local backup_dir="${opt_dir:-$(_k8s_get_backup_home)}"

  # Enable dry-run mode if flag is set
  radp_set_dry_run "${opt_dry_run:-false}"

  radp_log_info "Creating etcd backup..."
  radp_log_info "  Backup directory: $backup_dir"

  local backup_file
  backup_file=$(_k8s_backup_create "$backup_dir") || return 1

  radp_log_info ""
  radp_log_info "Backup created successfully!"
  radp_log_info "  File: $backup_file"

  return 0
}
