#!/usr/bin/env bash
# @cmd
# @desc Clean old etcd backups
# @option --keep-days <n> Days to keep backups (default: from config)
# @option -d, --dir <path> Backup directory (default: /var/opt/k8s/backups/etcd)
# @flag --dry-run Show what would be done
# @example k8s backup cleanup
# @example k8s backup cleanup --keep-days 7
# @example k8s backup cleanup --dry-run

cmd_k8s_backup_cleanup() {
  local keep_days="${opt_keep_days:-$(_k8s_get_backup_keep_days)}"
  local backup_dir="${opt_dir:-$(_k8s_get_backup_home)}"

  radp_set_dry_run "${opt_dry_run:-false}"

  radp_log_info "Cleaning etcd backups..."
  radp_log_info "  Backup directory: $backup_dir"
  radp_log_info "  Keep days: $keep_days"

  _k8s_backup_cleanup "$keep_days" "$backup_dir" || return 1

  return 0
}
