#!/usr/bin/env bash
# @cmd
# @desc Show package details
# @arg name! Package name
# @flag --all-platforms Show dependencies for all platforms
# @complete name _homelabctl_complete_packages
# @example setup info fzf
# @example setup info nodejs
# @example setup info git-credential-manager --all-platforms

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

  # Display dependencies based on --all-platforms flag
  if [[ -n "${opt_all_platforms:-}" ]]; then
    _setup_info_show_all_platforms "$name"
  else
    _setup_info_show_current_platform "$name"
  fi

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

#######################################
# Show dependencies for current platform (merged result)
# Arguments:
#   1 - package name
#######################################
_setup_info_show_current_platform() {
  local name="$1"

  # Get dependency info (merged for current platform)
  local requires recommends conflicts
  requires=$(_setup_registry_get_package_requires "$name")
  recommends=$(_setup_registry_get_package_recommends "$name")
  conflicts=$(_setup_registry_get_package_conflicts "$name")

  # Find reverse dependencies (packages that require this one)
  local rdeps=""
  local pkg pkg_requires
  for pkg in "${!_SETUP_PACKAGES[@]}"; do
    pkg_requires=$(_setup_registry_get_package_requires "$pkg")
    if [[ " $pkg_requires " == *" $name "* ]]; then
      rdeps="$rdeps $pkg"
    fi
  done

  [[ -n "$requires" ]] && printf "  %-15s %s\n" "Requires:" "$requires"
  [[ -n "$recommends" ]] && printf "  %-15s %s\n" "Recommends:" "$recommends"
  [[ -n "$conflicts" ]] && printf "  %-15s %s\n" "Conflicts:" "$conflicts"
  [[ -n "$rdeps" ]] && printf "  %-15s%s\n" "Required by:" "$rdeps"
}

#######################################
# Show dependencies for all platforms (base + per-platform)
# Groups os-arch entries under their parent OS
# Arguments:
#   1 - package name
#######################################
_setup_info_show_all_platforms() {
  local name="$1"

  # Get base dependencies
  local base_requires base_recommends base_conflicts
  base_requires=$(_setup_registry_get_package_requires_base "$name")
  base_recommends=$(_setup_registry_get_package_recommends_base "$name")
  base_conflicts=$(_setup_registry_get_package_conflicts_base "$name")

  # Show base dependencies
  echo ""
  echo "  Base dependencies:"
  if [[ -n "$base_requires" || -n "$base_recommends" || -n "$base_conflicts" ]]; then
    [[ -n "$base_requires" ]] && printf "    %-13s %s\n" "requires:" "$base_requires"
    [[ -n "$base_recommends" ]] && printf "    %-13s %s\n" "recommends:" "$base_recommends"
    [[ -n "$base_conflicts" ]] && printf "    %-13s %s\n" "conflicts:" "$base_conflicts"
  else
    echo "    (none)"
  fi

  # Get platforms with specific dependencies
  local platforms
  platforms=$(_setup_registry_get_package_platforms "$name")

  if [[ -n "$platforms" ]]; then
    echo ""
    echo "  Platform-specific:"

    # Group platforms by OS (os-only first, then os-arch)
    local -A os_shown=()
    local -a os_list=()
    local -a os_arch_list=()
    local platform

    # Separate OS-only and OS-arch platforms
    for platform in $platforms; do
      if [[ "$platform" == *-* ]]; then
        os_arch_list+=("$platform")
      else
        os_list+=("$platform")
      fi
    done

    # Sort both lists
    IFS=$'\n' os_list=($(sort <<<"${os_list[*]}")); unset IFS
    IFS=$'\n' os_arch_list=($(sort <<<"${os_arch_list[*]}")); unset IFS

    # Show OS-only platforms first
    for platform in "${os_list[@]}"; do
      [[ -z "$platform" ]] && continue
      _setup_info_show_platform_deps "$name" "$platform" "    "
      os_shown["$platform"]=1
    done

    # Show OS-arch platforms (grouped under parent OS if parent not shown)
    for platform in "${os_arch_list[@]}"; do
      [[ -z "$platform" ]] && continue
      local parent_os="${platform%%-*}"

      # If parent OS was shown, indent as sub-item
      if [[ -n "${os_shown[$parent_os]:-}" ]]; then
        _setup_info_show_platform_deps "$name" "$platform" "      "
      else
        _setup_info_show_platform_deps "$name" "$platform" "    "
      fi
    done
  fi

  # Find reverse dependencies
  local rdeps=""
  local pkg pkg_requires
  for pkg in "${!_SETUP_PACKAGES[@]}"; do
    pkg_requires=$(_setup_registry_get_package_requires "$pkg")
    if [[ " $pkg_requires " == *" $name "* ]]; then
      rdeps="$rdeps $pkg"
    fi
  done

  if [[ -n "$rdeps" ]]; then
    echo ""
    printf "  %-15s%s\n" "Required by:" "$rdeps"
  fi
}

#######################################
# Show platform-specific dependencies with given indent
# Arguments:
#   1 - package name
#   2 - platform key (e.g., linux, linux-arm64)
#   3 - indent string
#######################################
_setup_info_show_platform_deps() {
  local name="$1"
  local platform="$2"
  local indent="$3"

  local plat_req plat_rec plat_con
  plat_req=$(_setup_registry_get_package_requires_platform "$name" "$platform")
  plat_rec=$(_setup_registry_get_package_recommends_platform "$name" "$platform")
  plat_con=$(_setup_registry_get_package_conflicts_platform "$name" "$platform")

  echo "${indent}$platform:"
  [[ -n "$plat_req" ]] && printf "${indent}  %-11s %s\n" "requires:" "$plat_req"
  [[ -n "$plat_rec" ]] && printf "${indent}  %-11s %s\n" "recommends:" "$plat_rec"
  [[ -n "$plat_con" ]] && printf "${indent}  %-11s %s\n" "conflicts:" "$plat_con"
  return 0
}
