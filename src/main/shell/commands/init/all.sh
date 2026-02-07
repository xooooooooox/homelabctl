#!/usr/bin/env bash
# @cmd
# @desc Initialize all user configuration directories
# @flag --force Overwrite existing files
# @flag --dry-run Show what would be created without making changes
# @example init all
# @example init all --dry-run
# @example init all --force

cmd_init_all() {
  local force="${opt_force:-false}"
  local dry_run="${opt_dry_run:-false}"
  local failed=0

  local flags=()
  [[ "$force" == "true" ]] && flags+=(--force)
  [[ "$dry_run" == "true" ]] && flags+=(--dry-run)

  radp_log_info "Initializing all user configurations..."
  radp_log_info ""

  local vf_config_dir=""

  # Initialize setup and k8s modules (direct function calls to avoid subprocess banners)
  for module in setup k8s; do
    radp_log_info "=== ${module^} Configuration ==="
    source "${BASH_SOURCE[0]%/*}/${module}.sh"
    if ! "cmd_init_${module}"; then
      radp_log_error "Failed to initialize $module configuration"
      ((++failed))
    fi
    radp_log_info ""
  done

  # VF module - must be subprocess (delegates to radp-vf via exec)
  radp_log_info "=== Vf Configuration ==="
  local result_file
  result_file=$(mktemp)
  export RADP_VF_INIT_RESULT_FILE="$result_file"

  if GX_RADP_FW_BANNER_MODE=off homelabctl init vf "${flags[@]}"; then
    [[ -f "$result_file" ]] && vf_config_dir=$(cat "$result_file")
  else
    radp_log_error "Failed to initialize vf configuration"
    ((++failed))
  fi
  rm -f "$result_file"
  unset RADP_VF_INIT_RESULT_FILE
  radp_log_info ""

  if [[ $failed -gt 0 ]]; then
    radp_log_error "Initialization completed with $failed error(s)"
    return 1
  fi

  radp_log_info "All user configurations initialized successfully"
  radp_log_info ""
  radp_log_info "Configuration directories:"
  radp_log_info "  Setup: $(_setup_get_user_dir)"
  radp_log_info "  K8s:   $(_k8s_get_extra_config_path)"
  [[ -n "$vf_config_dir" ]] && radp_log_info "  VF:    $vf_config_dir"
  return 0
}
