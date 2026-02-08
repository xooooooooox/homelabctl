#!/usr/bin/env bash
# @cmd
# @desc Apply an addon profile (install multiple addons)
# @arg name! Profile name
# @flag --dry-run Show what would be installed
# @flag --continue Continue on error
# @flag --skip-installed Skip already installed addons
# @example k8s addon profile apply quickstart
# @example k8s addon profile apply quickstart --dry-run
# @example k8s addon profile apply production --continue

cmd_k8s_addon_profile_apply() {
  local profile_name="${args_name}"
  local continue_on_error="${opt_continue:-}"
  local skip_installed="${opt_skip_installed:-}"

  # Enable dry-run mode if flag is set
  radp_set_dry_run "${opt_dry_run:-false}"

  # Find profile file
  local profile_file
  profile_file=$(_k8s_addon_find_profile "$profile_name")
  if [[ -z "$profile_file" ]]; then
    radp_log_error "Profile not found: $profile_name"
    radp_log_info "Run 'homelabctl k8s addon profile list' to see available profiles"
    return 1
  fi

  # Check cluster accessibility (skip in dry-run mode)
  if ! radp_is_dry_run; then
    if ! _k8s_is_cluster_accessible; then
      radp_log_error "Cannot connect to Kubernetes cluster"
      return 1
    fi
  fi

  # Ensure helm is available
  if ! _k8s_ensure_helm; then
    return 1
  fi

  radp_log_info "Applying profile: $profile_name"

  if radp_is_dry_run; then
    echo ""
    echo "Addons to install:"
  fi

  # Read addons into array
  local -a addons=()
  while IFS='|' read -r addon_name addon_version; do
    addons+=("$addon_name|$addon_version")
  done < <(_k8s_addon_parse_profile "$profile_file")

  local total=${#addons[@]}
  local installed=0
  local failed=0
  local skipped=0

  for addon_entry in "${addons[@]}"; do
    IFS='|' read -r addon_name addon_version <<<"$addon_entry"

    # Check if already installed (skip in dry-run mode)
    if ! radp_is_dry_run && _k8s_addon_is_installed "$addon_name" 2>/dev/null; then
      if [[ -n "$skip_installed" ]]; then
        radp_log_info "Skipping $addon_name (already installed)"
        ((++skipped))
        continue
      fi
    fi

    if radp_is_dry_run; then
      if [[ "$addon_version" == "latest" ]]; then
        echo "  - $addon_name"
      else
        echo "  - $addon_name (v$addon_version)"
      fi
      continue
    fi

    echo ""
    radp_log_info "[$((installed + failed + skipped + 1))/$total] Installing $addon_name..."

    local install_version=""
    [[ "$addon_version" != "latest" ]] && install_version="$addon_version"

    if _k8s_addon_install "$addon_name" "$install_version"; then
      ((++installed))
      radp_log_info "$addon_name installed successfully"
    else
      ((++failed))
      if [[ -z "$continue_on_error" ]]; then
        radp_log_error "Failed to install $addon_name, stopping"
        echo ""
        echo "Summary: $installed installed, $failed failed, $skipped skipped"
        return 1
      fi
      radp_log_warn "Failed to install $addon_name, continuing..."
    fi
  done

  if radp_is_dry_run; then
    echo ""
    echo "Run without --dry-run to install"
    return 0
  fi

  echo ""
  echo "====================================="
  echo "Profile '$profile_name' applied"
  echo "  Installed: $installed"
  echo "  Failed:    $failed"
  echo "  Skipped:   $skipped"
  echo "  Total:     $total"
  echo "====================================="

  [[ $failed -gt 0 ]] && return 1
  return 0
}
