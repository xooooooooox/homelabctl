#!/usr/bin/env bash
# @cmd
# @desc Stop GitLab services
# @option --service <name> Specific service to stop (puma, sidekiq, etc.)
# @flag --dry-run Show what would be done
# @example gitlab stop
# @example gitlab stop --service puma
# @example gitlab stop --service sidekiq

cmd_gitlab_stop() {
  local service="${opt_service:-}"

  # Enable dry-run mode if flag is set
  radp_set_dry_run "${opt_dry_run:-false}"

  # Check if GitLab is installed
  if ! _gitlab_is_installed; then
    radp_log_error "GitLab is not installed"
    return 1
  fi

  # Stop services
  _gitlab_stop "$service" || return 1

  return 0
}
