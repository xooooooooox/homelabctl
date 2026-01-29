#!/usr/bin/env bash
# @cmd
# @desc Show package details
# @arg name! Package name
# @complete name _homelabctl_complete_packages
# @example setup info fzf
# @example setup info nodejs

cmd_setup_info() {
  local name="${1:-}"

  if [[ -z "$name" ]]; then
    radp_cli_help_command "setup info"
    return 1
  fi

  _setup_registry_init

  # Check if package exists
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

  # Check installation status
  local status="Not installed"
  local installed_version=""
  if _setup_is_installed "$check_cmd"; then
    installed_version=$(_setup_get_installed_version "$name")
    if [[ -n "$installed_version" ]]; then
      status="Installed (v$installed_version)"
    else
      status="Installed"
    fi
  fi

  # Check if installer exists
  local has_installer="No"
  local builtin_dir user_dir
  builtin_dir=$(_setup_get_builtin_dir)
  user_dir=$(_setup_get_user_dir)

  if [[ -f "$user_dir/installers/${name}.sh" ]]; then
    has_installer="Yes (user)"
  elif [[ -f "$builtin_dir/installers/${name}.sh" ]]; then
    has_installer="Yes (builtin)"
  fi

  # Display info
  echo "Package: $name"
  echo ""
  printf "  %-15s %s\n" "Description:" "$desc"
  printf "  %-15s %s\n" "Category:" "$category"
  printf "  %-15s %s\n" "Check command:" "$check_cmd"
  printf "  %-15s %s\n" "Status:" "$status"
  printf "  %-15s %s\n" "Installer:" "$has_installer"
  echo ""

  if [[ "$has_installer" == "No" ]]; then
    radp_log_warn "No installer available for this package"
    echo ""
    echo "You can create a custom installer at:"
    echo "  $user_dir/installers/${name}.sh"
  else
    echo "Install with: homelabctl setup install $name"
  fi
}
