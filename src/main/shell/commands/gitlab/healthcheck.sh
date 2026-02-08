#!/usr/bin/env bash
# @cmd
# @desc Run GitLab health checks
# @flag --verbose Show detailed output
# @flag --check-secrets Also run secrets doctor
# @flag --dry-run Show what would be done
# @example gitlab healthcheck
# @example gitlab healthcheck --verbose
# @example gitlab healthcheck --verbose --check-secrets

cmd_gitlab_healthcheck() {
  local verbose="${opt_verbose:-}"
  local check_secrets="${opt_check_secrets:-}"

  # Enable dry-run mode if flag is set
  radp_set_dry_run "${opt_dry_run:-false}"

  # Check if GitLab is installed
  if ! _gitlab_is_installed; then
    radp_log_error "GitLab is not installed"
    return 1
  fi

  # Build args
  local args=()
  [[ -n "$verbose" ]] && args+=(--verbose)
  [[ -n "$check_secrets" ]] && args+=(--secrets)

  # Run health check
  _gitlab_healthcheck "${args[@]}"
  local result=$?

  return $result
}
