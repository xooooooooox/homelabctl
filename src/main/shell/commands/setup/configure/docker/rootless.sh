#!/usr/bin/env bash
# @cmd
# @desc Configure Docker for non-root user access
# @option -u, --user <user> Target user (default: current user)
# @flag --dry-run Show what would be done without making changes
# @example setup configure docker rootless
# @example setup configure docker rootless -u vagrant
# @example setup configure docker rootless --dry-run

cmd_setup_configure_docker_rootless() {
  local user="${opt_user:-$(radp_os_get_current_user)}"
  local dry_run="${opt_dry_run:-}"

  # Set dry-run mode from flag
  radp_set_dry_run "$dry_run"

  # Load configurer
  if ! _setup_load_configurer "docker"; then
    radp_log_error "Docker configurer not found"
    return 1
  fi

  # Dry-run output
  if [[ -n "$dry_run" ]]; then
    radp_log_info "[dry-run] Would configure Docker rootless access for user: $user"
    radp_log_info "[dry-run] Actions:"
    radp_log_info "  1. Ensure 'docker' group exists"
    radp_log_info "  2. Add user '$user' to 'docker' group"
    radp_log_info "  3. Verify Docker access"
    radp_log_info ""
    radp_log_info "After configuration, user '$user' will be able to run Docker commands without sudo."
    radp_log_info "Note: User needs to log out and back in for group changes to take effect."
    return 0
  fi

  # Run configurer
  _setup_configure_docker_rootless "$user"
}
