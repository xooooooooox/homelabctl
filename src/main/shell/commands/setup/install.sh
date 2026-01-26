#!/usr/bin/env bash
# @cmd
# @desc Install a software package
# @arg name! Package name to install
# @option -v, --version <ver> Specific version (default: latest)
# @option --dry-run Show what would be installed without installing
# @example setup install fzf
# @example setup install nodejs -v 20.10.0
# @example setup install jdk -v 17

cmd_setup_install() {
  local name="$1"
  local version="${opt_version:-latest}"
  local dry_run="${opt_dry_run:-}"

  # Initialize registry
  _setup_registry_init

  # Check if package is known
  if ! _setup_registry_has_package "$name"; then
    radp_log_error "Unknown package: $name"
    radp_log_info "Run 'homelabctl setup list' to see available packages"
    return 1
  fi

  # Get package info
  local desc category check_cmd
  desc=$(_setup_registry_get_package_desc "$name")
  category=$(_setup_registry_get_package_category "$name")
  check_cmd=$(_setup_registry_get_package_cmd "$name")

  # Check if already installed
  if _setup_check_installed "$name"; then
    local installed_version
    installed_version=$(_setup_get_installed_version "$name")
    if [[ -n "$installed_version" ]]; then
      radp_log_info "$name is already installed (version: $installed_version)"
    else
      radp_log_info "$name is already installed"
    fi

    if [[ "$version" == "latest" ]]; then
      return 0
    fi
    radp_log_info "Proceeding with version $version installation..."
  fi

  if [[ -n "$dry_run" ]]; then
    radp_log_info "[dry-run] Would install: $name $version"
    radp_log_info "  Description: $desc"
    radp_log_info "  Category: $category"
    radp_log_info "  Check command: $check_cmd"
    return 0
  fi

  radp_log_info "Installing $name ${version}..."
  if _setup_run_installer "$name" "$version"; then
    radp_log_info "$name installed successfully"
    return 0
  else
    radp_log_error "Failed to install $name"
    return 1
  fi
}
