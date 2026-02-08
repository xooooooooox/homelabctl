#!/usr/bin/env bash
# @cmd
# @desc Restart GitLab services
# @option --service <name> Specific service to restart (puma, sidekiq, etc.)
# @flag --dry-run Show what would be done
# @example gitlab restart
# @example gitlab restart --service puma
# @example gitlab restart --service sidekiq

cmd_gitlab_restart() {
  local service="${opt_service:-}"

  # Enable dry-run mode if flag is set
  radp_set_dry_run "${opt_dry_run:-false}"

  # Check if GitLab is installed
  if ! _gitlab_is_installed; then
    radp_log_error "GitLab is not installed"
    return 1
  fi

  # Restart services
  _gitlab_restart "$service" || return 1

  return 0
}
