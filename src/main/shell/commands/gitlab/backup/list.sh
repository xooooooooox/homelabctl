#!/usr/bin/env bash
# @cmd
# @desc List available GitLab backups
# @option --type <type> Backup type: all, data, config (default: all)
# @example gitlab backup list
# @example gitlab backup list --type data

cmd_gitlab_backup_list() {
  local backup_type="${opt_type:-all}"

  if ! _gitlab_is_installed; then
    radp_log_error "GitLab is not installed"
    return 1
  fi

  _gitlab_backup_list --type "$backup_type"
  return 0
}
