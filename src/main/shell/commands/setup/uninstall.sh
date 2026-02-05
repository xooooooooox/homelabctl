#!/usr/bin/env bash
# @cmd
# @desc Uninstall a software package
# @arg name! Package name to uninstall
# @complete name _homelabctl_complete_packages
# @flag --purge Remove configuration files as well
# @flag --dry-run Show what would be uninstalled without uninstalling
# @example setup uninstall docker
# @example setup uninstall docker --purge
# @example setup uninstall containerd --dry-run

cmd_setup_uninstall() {
  local name="${1:-}"
  local purge="${opt_purge:-}"
  local dry_run="${opt_dry_run:-}"

  if [[ -z "$name" ]]; then
    radp_cli_help_command "setup uninstall"
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

  # Check if package is installed
  if ! _setup_check_installed "$name"; then
    radp_log_info "$name is not installed"
    return 0
  fi

  # Get package info
  local desc check_cmd
  desc=$(_setup_registry_get_package_desc "$name")
  check_cmd=$(_setup_registry_get_package_cmd "$name")
  [[ -z "$check_cmd" ]] && check_cmd="$name"

  # Get installed version if possible
  local installed_ver
  installed_ver=$(_setup_get_installed_version "$name")

  # Dry-run output
  if [[ -n "$dry_run" ]]; then
    radp_log_info "[dry-run] Would uninstall: $name"
    radp_log_info "  Description: $desc"
    radp_log_info "  Check command: $check_cmd"
    if [[ -n "$installed_ver" ]]; then
      radp_log_info "  Installed version: $installed_ver"
    fi
    if [[ -n "$purge" ]]; then
      radp_log_info "  Purge: yes (configuration files will be removed)"
    else
      radp_log_info "  Purge: no (configuration files will be kept)"
    fi

    # Check if uninstaller exists
    if _setup_has_uninstaller "$name"; then
      radp_log_info "  Uninstaller: available"
    else
      radp_log_warn "  Uninstaller: not available (package may need manual removal)"
    fi
    return 0
  fi

  # Check if uninstaller exists
  if ! _setup_has_uninstaller "$name"; then
    radp_log_error "No uninstaller found for: $name"
    radp_log_info "Package may need to be removed manually"
    return 1
  fi

  # Run uninstaller
  radp_log_info "Uninstalling $name..."
  if [[ -n "$installed_ver" ]]; then
    radp_log_info "Current version: $installed_ver"
  fi

  if _setup_run_uninstaller "$name" "$purge"; then
    radp_log_info "$name uninstalled successfully"
  else
    radp_log_error "Failed to uninstall $name"
    return 1
  fi

  return 0
}
