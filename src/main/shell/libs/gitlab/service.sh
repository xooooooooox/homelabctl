#!/usr/bin/env bash
# GitLab service management functions

#######################################
# Execute gitlab-ctl command
# Arguments:
#   @ - Arguments to pass to gitlab-ctl
# Returns:
#   gitlab-ctl exit code
#######################################
_gitlab_ctl() {
  _gitlab_is_installed || {
    radp_log_error "GitLab is not installed"
    return 1
  }

  $gr_sudo gitlab-ctl "$@"
}

#######################################
# Reconfigure GitLab
# Runs gitlab-ctl reconfigure
# Returns:
#   0 on success, 1 on failure
#######################################
_gitlab_reconfigure() {
  radp_log_info "Reconfiguring GitLab..."
  radp_exec_sudo "Reconfigure GitLab" gitlab-ctl reconfigure || {
    radp_log_error "Failed to reconfigure GitLab"
    return 1
  }
  radp_log_info "GitLab reconfigured"
  return 0
}

#######################################
# Start GitLab services
# Arguments:
#   1 - service: Optional specific service (puma, sidekiq, etc.)
# Returns:
#   0 on success, 1 on failure
#######################################
_gitlab_start() {
  local service="${1:-}"

  if [[ -n "$service" ]]; then
    radp_log_info "Starting GitLab service: $service..."
    radp_exec_sudo "Start GitLab $service" gitlab-ctl start "$service" || {
      radp_log_error "Failed to start $service"
      return 1
    }
    radp_log_info "GitLab service $service started"
  else
    radp_log_info "Starting all GitLab services..."
    radp_exec_sudo "Start GitLab" gitlab-ctl start || {
      radp_log_error "Failed to start GitLab"
      return 1
    }
    radp_log_info "GitLab started"
  fi

  return 0
}

#######################################
# Stop GitLab services
# Arguments:
#   1 - service: Optional specific service (puma, sidekiq, etc.)
# Returns:
#   0 on success, 1 on failure
#######################################
_gitlab_stop() {
  local service="${1:-}"

  if [[ -n "$service" ]]; then
    radp_log_info "Stopping GitLab service: $service..."
    radp_exec_sudo "Stop GitLab $service" gitlab-ctl stop "$service" || {
      radp_log_error "Failed to stop $service"
      return 1
    }
    radp_log_info "GitLab service $service stopped"
  else
    radp_log_info "Stopping all GitLab services..."
    radp_exec_sudo "Stop GitLab" gitlab-ctl stop || {
      radp_log_error "Failed to stop GitLab"
      return 1
    }
    radp_log_info "GitLab stopped"
  fi

  return 0
}

#######################################
# Restart GitLab services
# Arguments:
#   1 - service: Optional specific service (puma, sidekiq, etc.)
# Returns:
#   0 on success, 1 on failure
#######################################
_gitlab_restart() {
  local service="${1:-}"

  if [[ -n "$service" ]]; then
    radp_log_info "Restarting GitLab service: $service..."
    radp_exec_sudo "Restart GitLab $service" gitlab-ctl restart "$service" || {
      radp_log_error "Failed to restart $service"
      return 1
    }
    radp_log_info "GitLab service $service restarted"
  else
    radp_log_info "Restarting all GitLab services..."
    radp_exec_sudo "Restart GitLab" gitlab-ctl restart || {
      radp_log_error "Failed to restart GitLab"
      return 1
    }
    radp_log_info "GitLab restarted"
  fi

  return 0
}

#######################################
# Get GitLab service status
# Arguments:
#   1 - service: Optional specific service
# Outputs:
#   Status information
# Returns:
#   0 on success, 1 on failure
#######################################
_gitlab_status() {
  local service="${1:-}"

  if [[ -n "$service" ]]; then
    _gitlab_ctl status "$service"
  else
    _gitlab_ctl status
  fi
}

#######################################
# Run GitLab health check
# Arguments:
#   --verbose    Show detailed output
#   --secrets    Also run secrets doctor
# Returns:
#   0 if healthy, 1 if issues found
#######################################
_gitlab_healthcheck() {
  local verbose="" check_secrets=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --verbose) verbose="true"; shift ;;
      --secrets) check_secrets="true"; shift ;;
      *) shift ;;
    esac
  done

  _gitlab_is_installed || {
    radp_log_error "GitLab is not installed"
    return 1
  }

  # Skip in dry-run mode
  if radp_dry_run_skip "Run GitLab health check"; then
    return 0
  fi

  local result=0

  radp_log_info "Running GitLab health check..."

  if [[ -n "$verbose" ]]; then
    $gr_sudo gitlab-rake gitlab:check SANITIZE=true || result=1
  else
    $gr_sudo gitlab-rake gitlab:check SANITIZE=true 2>&1 | grep -E '(Checking|PASSED|FAILED|ERROR)' || result=1
  fi

  if [[ -n "$check_secrets" ]]; then
    radp_log_info "Running secrets doctor..."
    $gr_sudo gitlab-rake gitlab:doctor:secrets VERBOSE=1 || result=1
  fi

  if [[ "$result" -eq 0 ]]; then
    radp_log_info "Health check passed"
  else
    radp_log_warn "Health check found issues"
  fi

  return $result
}

#######################################
# Reset GitLab user password
# Arguments:
#   1 - username: GitLab username to reset
# Returns:
#   0 on success, 1 on failure
#######################################
_gitlab_reset_password() {
  local username="${1:?'Username required'}"

  _gitlab_is_installed || {
    radp_log_error "GitLab is not installed"
    return 1
  }

  # Skip in dry-run mode
  if radp_dry_run_skip "Reset password for user: $username"; then
    return 0
  fi

  radp_log_info "Resetting password for user: $username..."
  $gr_sudo gitlab-rake "gitlab:password:reset[$username]" || {
    radp_log_error "Failed to reset password for $username"
    return 1
  }

  return 0
}

#######################################
# Get GitLab initial root password
# Outputs:
#   Initial root password if available
# Returns:
#   0 if password found, 1 if not
# Note:
#   Password file expires 24 hours after installation
#######################################
_gitlab_get_initial_password() {
  local password_file
  password_file="$(_gitlab_get_config_home)/initial_root_password"

  if [[ ! -f "$password_file" ]]; then
    radp_log_warn "Initial password file not found (expires 24h after installation)"
    return 1
  fi

  $gr_sudo grep '^Password:' "$password_file" | awk '{print $2}'
}
