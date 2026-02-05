#!/usr/bin/env bash
# Setup common helper functions
# Sourced by installer.sh and registry.sh

#######################################
# Check if a package is installed
# Wrapper for _common_is_installed
# Arguments:
#   1 - check specification (command, dir:<path>, file:<path>)
# Returns:
#   0 if installed, 1 if not
#######################################
_setup_is_installed() {
  _common_is_installed "$@"
}

#######################################
# Get user setup directory
# Globals:
#   gr_radp_extend_homelabctl_setup_user_dir
# Returns:
#   Path to user setup directory
#######################################
_setup_get_user_dir() {
  echo "${gr_radp_extend_homelabctl_setup_user_dir:-$HOME/.config/homelabctl/setup}"
}

#######################################
# Get builtin setup directory
# Globals:
#   RADP_APP_ROOT
# Returns:
#   Path to builtin setup directory
#######################################
_setup_get_builtin_dir() {
  echo "${RADP_APP_ROOT:-}/src/main/shell/libs/setup"
}

#######################################
# Simple YAML value parser
# Wrapper for _common_yaml_get_value
# Arguments:
#   1 - key name
#   2 - YAML content (via stdin if not provided)
# Outputs:
#   Value for the key
#######################################
_setup_yaml_get_value() {
  _common_yaml_get_value "$@"
}

#######################################
# Parse YAML list items
# Wrapper for _common_yaml_get_list_items
# Arguments:
#   stdin - YAML content
# Outputs:
#   List items, one per line
#######################################
_setup_yaml_get_list_items() {
  _common_yaml_get_list_items
}

#######################################
# Get architecture in common format
# Wrapper for _common_get_arch
# Outputs:
#   amd64 or arm64
#######################################
_setup_get_arch() {
  _common_get_arch
}

#######################################
# Get OS name in common format
# Wrapper for _common_get_os
# Outputs:
#   linux or darwin
#######################################
_setup_get_os() {
  _common_get_os
}

#######################################
# Get platform string (os-arch format)
# Wrapper for _common_get_platform
# Outputs:
#   Platform string like linux-amd64, darwin-arm64
#######################################
_setup_get_platform() {
  _common_get_platform
}

#######################################
# Get vfox home directory
# Returns:
#   Path to vfox home directory
#######################################
_setup_vfox_get_home() {
  local vfox_home="${VFOX_HOME:-$HOME/.version-fox}"
  [[ ! -d "$vfox_home" ]] && vfox_home="$HOME/.vfox"
  echo "$vfox_home"
}

#######################################
# Find vfox SDK bin directory
# Arguments:
#   1 - SDK name (nodejs, java, python, ruby, go)
#   2 - binary name to check (node, java, python3, ruby, go)
# Returns:
#   Path to bin directory (stdout), or empty if not found
#######################################
_setup_vfox_find_sdk_bin() {
  local sdk_name="$1"
  local check_binary="$2"
  local vfox_home
  vfox_home=$(_setup_vfox_get_home)

  # Method 1: Check sdks directory (symlink created by vfox use)
  if [[ -d "$vfox_home/sdks/$sdk_name/bin" ]]; then
    if [[ -z "$check_binary" ]] || [[ -x "$vfox_home/sdks/$sdk_name/bin/$check_binary" ]]; then
      echo "$vfox_home/sdks/$sdk_name/bin"
      return 0
    fi
  fi

  # Method 2: Search in cache directory (handles nested structure)
  # vfox cache structure: cache/<sdk>/v-<version>/<sdk>-<version>/bin/
  if [[ -d "$vfox_home/cache/$sdk_name" ]]; then
    local found_bin
    if [[ -n "$check_binary" ]]; then
      # Use -executable for GNU find, fallback to -perm /111 for POSIX compatibility
      found_bin=$(find "$vfox_home/cache/$sdk_name" -type f -name "$check_binary" -executable 2>/dev/null | head -1)
      if [[ -z "$found_bin" ]]; then
        # Fallback: use -perm /111 (any execute bit set) instead of -perm -111 (all execute bits)
        found_bin=$(find "$vfox_home/cache/$sdk_name" -type f -name "$check_binary" -perm /111 2>/dev/null | head -1)
      fi
      if [[ -n "$found_bin" ]]; then
        dirname "$found_bin"
        return 0
      fi
    else
      found_bin=$(find "$vfox_home/cache/$sdk_name" -type d -name "bin" 2>/dev/null | head -1)
      if [[ -n "$found_bin" ]]; then
        echo "$found_bin"
        return 0
      fi
    fi
  fi

  return 1
}

#######################################
# Add vfox SDK to PATH
# Arguments:
#   1 - SDK name (nodejs, java, python, ruby, go)
#   2 - binary name to check (node, java, python3, ruby, go)
# Returns:
#   0 if added, 1 if not found
#######################################
_setup_vfox_add_sdk_to_path() {
  local sdk_name="$1"
  local check_binary="$2"
  local bin_dir
  bin_dir=$(_setup_vfox_find_sdk_bin "$sdk_name" "$check_binary")

  if [[ -n "$bin_dir" && ":$PATH:" != *":$bin_dir:"* ]]; then
    export PATH="$bin_dir:$PATH"
    hash -r 2>/dev/null || true
    return 0
  fi

  return 1
}

#######################################
# Refresh PATH from vfox after install
# Makes vfox-managed tools immediately available
# in non-interactive scripts where vfox activate
# is not available.
#######################################
_setup_vfox_refresh_path() {
  _setup_is_installed vfox || return 0

  local vfox_home bin_dir
  vfox_home=$(_setup_vfox_get_home)

  # Add shims directory
  if [[ -d "$vfox_home/shims" && ":$PATH:" != *":$vfox_home/shims:"* ]]; then
    export PATH="$vfox_home/shims:$PATH"
  fi

  # Add SDK bin directories from sdks symlinks
  for bin_dir in "$vfox_home"/sdks/*/bin; do
    if [[ -d "$bin_dir" && ":$PATH:" != *":$bin_dir:"* ]]; then
      export PATH="$bin_dir:$PATH"
    fi
  done

  # Add bin directories from cache (nested structure)
  if [[ -d "$vfox_home/cache" ]]; then
    while IFS= read -r bin_dir; do
      [[ -n "$bin_dir" && ":$PATH:" != *":$bin_dir:"* ]] && export PATH="$bin_dir:$PATH"
    done < <(find "$vfox_home/cache" -type d -name "bin" 2>/dev/null)
  fi

  # Try vfox env as fallback
  local shell_name
  shell_name=$(basename "${SHELL:-bash}")
  [[ "$shell_name" != "bash" && "$shell_name" != "zsh" ]] && shell_name="bash"
  eval "$(vfox env -s "$shell_name" 2>/dev/null)" || true

  hash -r 2>/dev/null || true
}

#######################################
# Get ordered installation list for a package
# Resolves dependencies recursively with cycle detection
# Arguments:
#   1 - package name
# Outputs:
#   Package names in install order (deps first, target last)
# Returns:
#   0 on success, 1 on circular dependency or error
#######################################
_setup_get_install_order() {
  local pkg="$1"
  local -A _visited=()
  local -A _in_progress=()

  _setup_resolve_deps_recursive "$pkg" _visited _in_progress
}

#######################################
# Internal recursive dependency resolver
# Arguments:
#   1 - package name
#   2 - nameref to visited associative array
#   3 - nameref to in_progress associative array
# Outputs:
#   Package names in dependency order
# Returns:
#   0 on success, 1 on circular dependency
#######################################
_setup_resolve_deps_recursive() {
  local pkg="$1"
  local -n __visited="$2"
  local -n __in_progress="$3"

  # Check for circular dependency
  if [[ "${__in_progress[$pkg]:-}" == "1" ]]; then
    radp_log_error "Circular dependency detected: $pkg"
    return 1
  fi

  # Skip if already processed
  if [[ "${__visited[$pkg]:-}" == "1" ]]; then
    return 0
  fi

  # Mark as in-progress
  __in_progress["$pkg"]="1"

  # Get required dependencies
  local requires dep
  requires=$(_setup_registry_get_package_requires "$pkg")

  # Recursively resolve each dependency
  for dep in $requires; do
    # Verify dependency exists in registry
    if ! _setup_registry_has_package "$dep"; then
      radp_log_warn "Dependency '$dep' for '$pkg' not found in registry, skipping"
      continue
    fi

    # Recurse
    if ! _setup_resolve_deps_recursive "$dep" "$2" "$3"; then
      return 1
    fi
  done

  # Mark as visited and output
  __visited["$pkg"]="1"
  unset '__in_progress[$pkg]'
  echo "$pkg"
}

#######################################
# Show recommended packages hint
# Displays uninstalled recommended packages
# Arguments:
#   1 - package name
#######################################
_setup_show_recommends() {
  local pkg="$1"
  local recommends
  recommends=$(_setup_registry_get_package_recommends "$pkg")

  [[ -z "$recommends" ]] && return 0

  local rec not_installed=""
  for rec in $recommends; do
    local check_cmd
    check_cmd=$(_setup_registry_get_package_cmd "$rec")
    if ! _setup_is_installed "$check_cmd"; then
      not_installed="$not_installed $rec"
    fi
  done

  # Only show hint if there are uninstalled recommended packages
  if [[ -n "$not_installed" ]]; then
    radp_log_info "Recommended packages (optional):$not_installed"
    radp_log_info "Install with: homelabctl setup install <package>"
  fi
}

#######################################
# Check for package conflicts
# Arguments:
#   1 - package name to install
# Returns:
#   0 if no conflicts, 1 if conflicts exist
# Outputs:
#   Error message with conflicting packages
#######################################
_setup_check_conflicts() {
  local pkg="$1"
  local conflicts installed_conflicts=""

  # Get conflicts for this package
  conflicts=$(_setup_registry_get_package_conflicts "$pkg")

  # Check if any conflicting packages are installed
  local conflict_pkg
  for conflict_pkg in $conflicts; do
    local check_cmd
    check_cmd=$(_setup_registry_get_package_cmd "$conflict_pkg")
    if _setup_is_installed "$check_cmd"; then
      installed_conflicts="$installed_conflicts $conflict_pkg"
    fi
  done

  # Also check reverse conflicts (packages that conflict with this one)
  local other_pkg other_conflicts
  for other_pkg in "${!_SETUP_PACKAGES[@]}"; do
    other_conflicts=$(_setup_registry_get_package_conflicts "$other_pkg")
    if [[ " $other_conflicts " == *" $pkg "* ]]; then
      local check_cmd
      check_cmd=$(_setup_registry_get_package_cmd "$other_pkg")
      if _setup_is_installed "$check_cmd"; then
        # Avoid duplicates
        if [[ " $installed_conflicts " != *" $other_pkg "* ]]; then
          installed_conflicts="$installed_conflicts $other_pkg"
        fi
      fi
    fi
  done

  if [[ -n "$installed_conflicts" ]]; then
    radp_log_error "Cannot install $pkg: conflicts with installed package(s):$installed_conflicts"
    return 1
  fi

  return 0
}
