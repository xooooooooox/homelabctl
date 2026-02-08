#!/usr/bin/env bash
# @cmd
# @desc Start GitLab services
# @option --service <name> Specific service to start (puma, sidekiq, etc.)
# @flag --dry-run Show what would be done
# @example gitlab start
# @example gitlab start --service puma
# @example gitlab start --service sidekiq

cmd_gitlab_start() {
  local service="${opt_service:-}"

  # Enable dry-run mode if flag is set
  radp_set_dry_run "${opt_dry_run:-false}"

  # Check if GitLab is installed
  if ! _gitlab_is_installed; then
    radp_log_error "GitLab is not installed"
    return 1
  fi

  # Start services
  _gitlab_start "$service" || return 1

  return 0
}
