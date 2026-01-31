#!/usr/bin/env bash
# @cmd
# @desc Apply a setup profile (install multiple packages)
# @arg name! Profile name
# @complete name _homelabctl_complete_profiles
# @option --dry-run Show what would be installed
# @option --continue Continue on error
# @option --skip-installed Skip already installed packages
# @option --no-deps Skip automatic dependency installation
# @example setup profile apply recommend
# @example setup profile apply recommend --dry-run
# @example setup profile apply recommend --continue

cmd_setup_profile_apply() {
  local profile_name="${1:-}"
  local dry_run="${opt_dry_run:-}"
  local continue_on_error="${opt_continue:-}"
  local skip_installed="${opt_skip_installed:-}"
  local no_deps="${opt_no_deps:-}"

  if [[ -z "$profile_name" ]]; then
    radp_cli_help_command "setup profile apply"
    return 1
  fi

  _setup_registry_init

  # Find profile file
  local profile_file
  profile_file=$(_setup_find_profile "$profile_name")
  if [[ -z "$profile_file" ]]; then
    radp_log_error "Profile not found: $profile_name"
    radp_log_info "Run 'homelabctl setup profile list' to see available profiles"
    return 1
  fi

  # Check platform compatibility
  local platform current_os
  platform=$(_setup_yaml_get_value "platform" <"$profile_file")
  current_os=$(_setup_get_os)

  if [[ -n "$platform" && "$platform" != "any" && "$platform" != "$current_os" ]]; then
    radp_log_warn "Profile '$profile_name' is designed for platform: $platform"
    radp_log_warn "Current platform: $current_os"
    radp_log_warn "Some packages may not install correctly"
    echo ""
  fi

  radp_log_info "Applying profile: $profile_name"

  if [[ -n "$dry_run" ]]; then
    echo ""
    echo "Packages to install:"
  fi

  # Count packages
  local total=0
  local installed=0
  local failed=0
  local skipped=0

  # Read packages into array to avoid subshell issues
  local -a packages=()
  while IFS='|' read -r pkg_name pkg_version; do
    packages+=("$pkg_name|$pkg_version")
  done < <(_setup_parse_profile "$profile_file")

  total=${#packages[@]}

  # Track installed packages to avoid reinstalling deps
  local -A already_installed_in_session=()

  for pkg_entry in "${packages[@]}"; do
    IFS='|' read -r pkg_name pkg_version <<<"$pkg_entry"

    # Check if already installed
    if _setup_registry_has_package "$pkg_name"; then
      local check_cmd
      check_cmd=$(_setup_registry_get_package_cmd "$pkg_name")
      if _setup_is_installed "$check_cmd"; then
        if [[ -n "$skip_installed" ]]; then
          radp_log_info "Skipping $pkg_name (already installed)"
          ((++skipped))
          continue
        fi
      fi
    fi

    # Resolve dependencies for this package
    local -a pkg_install_order=()
    if [[ -z "$no_deps" ]]; then
      local dep_list
      if dep_list=$(_setup_get_install_order "$pkg_name" 2>/dev/null); then
        while IFS= read -r dep; do
          [[ -n "$dep" ]] && pkg_install_order+=("$dep")
        done <<<"$dep_list"
      else
        pkg_install_order=("$pkg_name")
      fi
    else
      pkg_install_order=("$pkg_name")
    fi

    # Install package and its dependencies
    local dep_pkg
    for dep_pkg in "${pkg_install_order[@]}"; do
      # Skip if already installed in this session
      if [[ -n "${already_installed_in_session[$dep_pkg]:-}" ]]; then
        # If this is the target package (not a dependency), count it as installed
        if [[ "$dep_pkg" == "$pkg_name" ]]; then
          ((++installed))
          radp_log_info "[$((installed + failed + skipped))/$total] $pkg_name already installed (as dependency)"
        fi
        continue
      fi

      # Skip already installed deps (but not the target package unless --skip-installed)
      if [[ "$dep_pkg" != "$pkg_name" ]]; then
        local dep_check_cmd
        dep_check_cmd=$(_setup_registry_get_package_cmd "$dep_pkg")
        if _setup_is_installed "$dep_check_cmd"; then
          already_installed_in_session["$dep_pkg"]=1
          continue
        fi
      fi

      if [[ -n "$dry_run" ]]; then
        if [[ "$dep_pkg" == "$pkg_name" ]]; then
          if [[ "$pkg_version" == "latest" ]]; then
            echo "  - $pkg_name"
          else
            echo "  - $pkg_name (v$pkg_version)"
          fi
        else
          echo "  - $dep_pkg (dependency of $pkg_name)"
        fi
        already_installed_in_session["$dep_pkg"]=1
        continue
      fi

      local install_version="latest"
      [[ "$dep_pkg" == "$pkg_name" ]] && install_version="$pkg_version"

      echo ""
      if [[ "$dep_pkg" == "$pkg_name" ]]; then
        radp_log_info "[$((installed + failed + skipped + 1))/$total] Installing $dep_pkg ${install_version}..."
      else
        radp_log_info "Installing dependency $dep_pkg for $pkg_name..."
      fi

      if _setup_run_installer "$dep_pkg" "$install_version"; then
        already_installed_in_session["$dep_pkg"]=1
        if [[ "$dep_pkg" == "$pkg_name" ]]; then
          ((++installed))
          radp_log_info "$pkg_name installed successfully"
        else
          radp_log_info "$dep_pkg installed successfully"
        fi
      else
        if [[ "$dep_pkg" == "$pkg_name" ]]; then
          ((++failed))
          if [[ -z "$continue_on_error" ]]; then
            radp_log_error "Failed to install $pkg_name, stopping"
            echo ""
            echo "Summary: $installed installed, $failed failed, $skipped skipped"
            return 1
          fi
          radp_log_warn "Failed to install $pkg_name, continuing..."
        else
          # Dependency failed
          ((++failed))
          if [[ -z "$continue_on_error" ]]; then
            radp_log_error "Failed to install dependency $dep_pkg for $pkg_name, stopping"
            echo ""
            echo "Summary: $installed installed, $failed failed, $skipped skipped"
            return 1
          fi
          radp_log_warn "Failed to install dependency $dep_pkg, continuing..."
          break # Skip remaining deps and the target package
        fi
      fi
    done
  done

  if [[ -n "$dry_run" ]]; then
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
