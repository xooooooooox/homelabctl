#!/usr/bin/env bash
# @cmd
# @desc Reset GitLab user password
# @arg username! GitLab username to reset password
# @flag --force Skip confirmation prompt
# @flag --dry-run Show what would be done
# @example gitlab reset-password root
# @example gitlab reset-password admin --force

cmd_gitlab_reset_password() {
  local username="${1:-}"
  local force="${opt_force:-}"

  # Enable dry-run mode if flag is set
  radp_set_dry_run "${opt_dry_run:-false}"

  if [[ -z "$username" ]]; then
    radp_cli_help_command "gitlab reset-password"
    return 1
  fi

  # Check if GitLab is installed
  if ! _gitlab_is_installed; then
    radp_log_error "GitLab is not installed"
    return 1
  fi

  # Confirm unless forced
  if [[ -z "$force" ]]; then
    radp_log_warn "This will reset the password for GitLab user: $username"
    if ! radp_io_prompt_confirm --msg "Continue? (y/N)" --default N --level warn --timeout 300; then
      radp_log_info "Password reset cancelled"
      return 1
    fi
  fi

  # Reset password
  _gitlab_reset_password "$username" || {
    radp_log_error "Failed to reset password for user: $username"
    return 1
  }

  if ! radp_is_dry_run; then
    radp_log_info ""
    radp_log_info "Password reset completed for user: $username"
    radp_log_info "You should have been prompted to enter a new password."
  fi

  return 0
}
