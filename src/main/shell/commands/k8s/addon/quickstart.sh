#!/usr/bin/env bash
# @cmd
# @desc Install recommended addons (alias for 'profile apply quickstart')
# @flag --dry-run Show what would be done
# @flag --continue Continue on error
# @flag --skip-installed Skip already installed addons
# @example k8s addon quickstart
# @example k8s addon quickstart --dry-run

cmd_k8s_addon_quickstart() {
  # This is a convenience alias for 'k8s addon profile apply quickstart'
  radp_log_info "Running: homelabctl k8s addon profile apply quickstart"
  echo ""

  # Build args array
  local -a args=("quickstart")
  [[ -n "${opt_dry_run:-}" ]] && args+=("--dry-run")
  [[ -n "${opt_continue:-}" ]] && args+=("--continue")
  [[ -n "${opt_skip_installed:-}" ]] && args+=("--skip-installed")

  # Forward to profile apply
  # Set args_name for the profile apply command
  args_name="quickstart"
  cmd_k8s_addon_profile_apply
}
