#!/usr/bin/env bash
# @cmd
# @desc List available etcd backups
# @option -d, --dir <path> Backup directory (default: /var/opt/k8s/backups/etcd)
# @example k8s backup list
# @example k8s backup list -d /backup/etcd

cmd_k8s_backup_list() {
  local backup_dir="${opt_dir:-$(_k8s_get_backup_home)}"

  _k8s_backup_list "$backup_dir" || {
    radp_log_info "No backups found in: $backup_dir"
    return 0
  }

  return 0
}
