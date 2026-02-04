#!/usr/bin/env bash
# @cmd
# @desc Clean old GitLab backups
# @option --keep-days <n> Days to keep backups (default: from config)
# @flag --dry-run Show what would be done
# @example gitlab backup cleanup
# @example gitlab backup cleanup --keep-days 7

cmd_gitlab_backup_cleanup() {
  local keep_days="${opt_keep_days:-$(_gitlab_get_backup_keep_days)}"

  radp_set_dry_run "${opt_dry_run:-}"

  if ! _gitlab_is_installed; then
    radp_log_error "GitLab is not installed"
    return 1
  fi

  _gitlab_backup_cleanup --keep-days "$keep_days"
  return $?
}
