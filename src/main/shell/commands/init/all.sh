#!/usr/bin/env bash
# @cmd
# @desc Initialize all user configuration directories (setup + k8s)
# @flag --force Overwrite existing files
# @flag --dry-run Show what would be created without making changes
# @example init all
# @example init all --dry-run
# @example init all --force

cmd_init_all() {
  local force="${opt_force:-false}"
  local dry_run="${opt_dry_run:-false}"
  local failed=0

  radp_log_info "Initializing all user configurations..."
  echo

  # Initialize setup
  radp_log_info "=== Setup Configuration ==="
  if ! cmd_init_setup; then
    radp_log_error "Failed to initialize setup configuration"
    ((failed++))
  fi
  echo

  # Initialize k8s
  radp_log_info "=== K8s Configuration ==="
  if ! cmd_init_k8s; then
    radp_log_error "Failed to initialize k8s configuration"
    ((failed++))
  fi
  echo

  if [[ $failed -gt 0 ]]; then
    radp_log_error "Initialization completed with $failed error(s)"
    return 1
  fi

  radp_log_info "All user configurations initialized successfully"
  radp_log_info ""
  radp_log_info "Configuration directories:"
  radp_log_info "  Setup: $(_setup_get_user_dir)"
  radp_log_info "  K8s:   $(_k8s_get_extra_config_path)"
  return 0
}
