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
  local failed=

  [[ "$dry_run" == "true" ]] && radp_set_dry_run

  local flags=()
  [[ "$force" == "true" ]] && flags+=(--force)
  [[ "$dry_run" == "true" ]] && flags+=(--dry-run)

  echo "Initializing all user configurations..."
  echo

  local vf_config_dir=""

  # Initialize setup and k8s modules (direct function calls to avoid subprocess banners)
  for module in setup k8s; do
    echo "=== ${module^} Configuration ==="
    source "${BASH_SOURCE[0]%/*}/${module}.sh"
    if ! "cmd_init_${module}"; then
      radp_log_error "Failed to initialize $module configuration"
      ((++failed))
    fi
    echo
  done

  # VF module - must be subprocess (delegates to radp-vf via exec)
  echo "=== Vf Configuration ==="
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
  echo

  if [[ $failed -gt 0 ]]; then
    radp_log_error "Initialization completed with $failed error(s)"
    return 1
  fi

  echo "All user configurations initialized successfully"
  echo ""
  echo "Configuration directories:"
  echo "  Setup: $(_setup_get_user_dir)"
  echo "  K8s:   $(_k8s_get_extra_config_path)"
  [[ -n "$vf_config_dir" ]] && echo "  VF:    $vf_config_dir"
  return 0
}
