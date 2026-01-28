#!/usr/bin/env bash
# Setup common helper functions
# Sourced by installer.sh and registry.sh

#######################################
# Check if a command is available
# Arguments:
#   1 - command name
# Returns:
#   0 if available, 1 if not
#######################################
_setup_is_installed() {
  local cmd="$1"
  command -v "$cmd" &>/dev/null
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
#   HOMELABCTL_ROOT
# Returns:
#   Path to builtin setup directory
#######################################
_setup_get_builtin_dir() {
  echo "${HOMELABCTL_ROOT:-}/src/main/shell/libs/setup"
}

#######################################
# Simple YAML value parser
# Extracts value for a key from YAML content
# Arguments:
#   1 - key name
#   2 - YAML content (via stdin if not provided)
# Returns:
#   Value for the key
#######################################
_setup_yaml_get_value() {
  local key="$1"
  local content="${2:-$(cat)}"

  echo "$content" | grep -E "^[[:space:]]*${key}:" | head -1 | sed "s/^[[:space:]]*${key}:[[:space:]]*//" | sed 's/^["'"'"']//' | sed 's/["'"'"']$//'
}

#######################################
# Parse YAML list items
# Arguments:
#   1 - YAML content (via stdin)
# Returns:
#   List items, one per line
#######################################
_setup_yaml_get_list_items() {
  grep -E '^[[:space:]]*-[[:space:]]' | sed 's/^[[:space:]]*-[[:space:]]*//'
}

#######################################
# Get architecture in common format
# Returns:
#   amd64 or arm64
#######################################
_setup_get_arch() {
  local arch
  arch=$(radp_os_get_distro_arch 2>/dev/null || uname -m)

  case "$arch" in
  x86_64 | amd64) echo "amd64" ;;
  aarch64 | arm64) echo "arm64" ;;
  *) echo "$arch" ;;
  esac
}

#######################################
# Get OS name in common format
# Returns:
#   linux or darwin
#######################################
_setup_get_os() {
  local os
  os=$(radp_os_get_distro_os 2>/dev/null || uname -s)
  echo "${os,,}"
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

  local vfox_home="${VFOX_HOME:-$HOME/.version-fox}"
  [[ ! -d "$vfox_home" ]] && vfox_home="$HOME/.vfox"

  local bin_dir=""

  # Method 1: Check sdks directory (symlink created by vfox use)
  if [[ -d "$vfox_home/sdks/$sdk_name/bin" ]]; then
    if [[ -z "$check_binary" ]] || [[ -x "$vfox_home/sdks/$sdk_name/bin/$check_binary" ]]; then
      echo "$vfox_home/sdks/$sdk_name/bin"
      return 0
    fi
  fi

  # Method 2: Search in cache directory
  for dir in "$vfox_home"/cache/"$sdk_name"/*/bin; do
    if [[ -d "$dir" ]]; then
      if [[ -z "$check_binary" ]] || [[ -x "$dir/$check_binary" ]]; then
        echo "$dir"
        return 0
      fi
    fi
  done

  # Method 3: Search without /bin suffix (some SDKs have different structure)
  for dir in "$vfox_home"/cache/"$sdk_name"/*; do
    if [[ -d "$dir/bin" ]]; then
      if [[ -z "$check_binary" ]] || [[ -x "$dir/bin/$check_binary" ]]; then
        echo "$dir/bin"
        return 0
      fi
    fi
  done

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
    radp_log_info "Added $bin_dir to PATH"
    return 0
  fi

  return 1
}

#######################################
# Refresh PATH from vfox after install
# Makes vfox-managed tools (node, java, ruby, etc.)
# immediately available in the current shell session.
# This is needed because vfox requires shell hooks
# (vfox activate) to manage PATH, which are not
# available in non-interactive scripts.
#######################################
_setup_vfox_refresh_path() {
  if ! _setup_is_installed vfox; then
    return 0
  fi

  local vfox_home="${VFOX_HOME:-$HOME/.version-fox}"
  [[ ! -d "$vfox_home" ]] && vfox_home="$HOME/.vfox"

  # Method 1: Add vfox shims to PATH (standard vfox approach)
  local shims_dir="$vfox_home/shims"
  if [[ -d "$shims_dir" && ":$PATH:" != *":$shims_dir:"* ]]; then
    export PATH="$shims_dir:$PATH"
  fi

  # Method 2: Add SDK bin directories from sdks symlinks
  local sdk_dir
  for sdk_dir in "$vfox_home"/sdks/*; do
    if [[ -L "$sdk_dir" || -d "$sdk_dir" ]]; then
      local bin_dir="$sdk_dir/bin"
      if [[ -d "$bin_dir" && ":$PATH:" != *":$bin_dir:"* ]]; then
        export PATH="$bin_dir:$PATH"
      fi
    fi
  done

  # Method 3: Add SDK bin directories from cache
  for sdk_dir in "$vfox_home"/cache/*/; do
    for version_dir in "$sdk_dir"*/bin; do
      if [[ -d "$version_dir" && ":$PATH:" != *":$version_dir:"* ]]; then
        export PATH="$version_dir:$PATH"
      fi
    done
  done

  # Method 4: Try vfox env as fallback
  local shell_name
  shell_name=$(basename "${SHELL:-bash}")
  [[ "$shell_name" != "bash" && "$shell_name" != "zsh" ]] && shell_name="bash"
  eval "$(vfox env -s "$shell_name" 2>/dev/null)" || true
}
