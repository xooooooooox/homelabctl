#!/usr/bin/env bash
# @cmd
# @desc Install a software package
# @arg name! Package name to install
# @complete name _homelabctl_complete_packages
# @option -v, --version <ver> Specific version (default: latest)
# @option --dry-run Show what would be installed without installing
# @option --no-deps Skip automatic dependency installation
# @example setup install fzf
# @example setup install nodejs -v 20.10.0
# @example setup install jdk -v 17
# @example setup install markdownlint-cli --no-deps

cmd_setup_install() {
  local name="${1:-}"
  local version="${opt_version:-latest}"
  local dry_run="${opt_dry_run:-}"
  local no_deps="${opt_no_deps:-}"

  if [[ -z "$name" ]]; then
    radp_cli_help_command "setup install"
    return 1
  fi

  # Initialize registry
  _setup_registry_init

  # Check if package is known
  if ! _setup_registry_has_package "$name"; then
    radp_log_error "Unknown package: $name"
    radp_log_info "Run 'homelabctl setup list' to see available packages"
    return 1
  fi

  # Check for conflicts (skip in dry-run, just show warning)
  if [[ -z "$dry_run" ]]; then
    if ! _setup_check_conflicts "$name"; then
      return 1
    fi
  fi

  # Resolve dependencies unless --no-deps
  local -a install_order=()
  if [[ -z "$no_deps" ]]; then
    local dep_list
    if ! dep_list=$(_setup_get_install_order "$name"); then
      radp_log_error "Failed to resolve dependencies for: $name"
      return 1
    fi

    while IFS= read -r pkg; do
      [[ -n "$pkg" ]] && install_order+=("$pkg")
    done <<<"$dep_list"
  else
    install_order=("$name")
  fi

  # Dry-run output
  if [[ -n "$dry_run" ]]; then
    if [[ ${#install_order[@]} -gt 1 ]]; then
      radp_log_info "[dry-run] Would install (in order):"
      for pkg in "${install_order[@]}"; do
        local pkg_desc pkg_status=""
        pkg_desc=$(_setup_registry_get_package_desc "$pkg")
        if _setup_check_installed "$pkg"; then
          pkg_status=" (already installed)"
        fi
        echo "  - $pkg: $pkg_desc$pkg_status"
      done
    else
      local desc category check_cmd requires recommends conflicts
      desc=$(_setup_registry_get_package_desc "$name")
      category=$(_setup_registry_get_package_category "$name")
      check_cmd=$(_setup_registry_get_package_cmd "$name")
      requires=$(_setup_registry_get_package_requires "$name")
      recommends=$(_setup_registry_get_package_recommends "$name")
      conflicts=$(_setup_registry_get_package_conflicts "$name")

      radp_log_info "[dry-run] Would install: $name $version"
      radp_log_info "  Description: $desc"
      radp_log_info "  Category: $category"
      radp_log_info "  Check command: $check_cmd"
      [[ -n "$requires" ]] && radp_log_info "  Requires: $requires"
      [[ -n "$recommends" ]] && radp_log_info "  Recommends: $recommends"
      [[ -n "$conflicts" ]] && radp_log_info "  Conflicts: $conflicts"
    fi
    return 0
  fi

  # Install packages in order
  local pkg
  for pkg in "${install_order[@]}"; do
    # Skip if already installed (unless specific version requested for target)
    if _setup_check_installed "$pkg"; then
      if [[ "$pkg" == "$name" && "$version" != "latest" ]]; then
        radp_log_info "Reinstalling $pkg with version $version..."
      else
        local installed_ver
        installed_ver=$(_setup_get_installed_version "$pkg")
        if [[ -n "$installed_ver" ]]; then
          radp_log_info "$pkg is already installed (v$installed_ver)"
        else
          radp_log_info "$pkg is already installed"
        fi
        continue
      fi
    fi

    # Determine version: use specified version only for target package
    local pkg_version="latest"
    [[ "$pkg" == "$name" ]] && pkg_version="$version"

    radp_log_info "Installing $pkg ${pkg_version}..."
    if _setup_run_installer "$pkg" "$pkg_version"; then
      radp_log_info "$pkg installed successfully"
    else
      radp_log_error "Failed to install $pkg"
      # Stop on dependency failure
      if [[ "$pkg" != "$name" ]]; then
        radp_log_error "Cannot install $name: dependency $pkg failed"
      fi
      return 1
    fi
  done

  # Show recommended packages
  _setup_show_recommends "$name"

  return 0
}
