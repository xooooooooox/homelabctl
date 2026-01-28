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

  # Method 1: Add vfox shims to PATH (standard vfox approach)
  local shims_dir="$vfox_home/shims"
  if [[ -d "$shims_dir" && ":$PATH:" != *":$shims_dir:"* ]]; then
    export PATH="$shims_dir:$PATH"
  fi

  # Method 2: Add SDK bin directories to PATH
  # vfox sdks are symlinks: ~/.version-fox/sdks/nodejs -> ~/.version-fox/cache/nodejs/v-xxx/nodejs-xxx
  local sdk_dir
  for sdk_dir in "$vfox_home"/sdks/*; do
    if [[ -L "$sdk_dir" || -d "$sdk_dir" ]]; then
      local bin_dir="$sdk_dir/bin"
      if [[ -d "$bin_dir" && ":$PATH:" != *":$bin_dir:"* ]]; then
        export PATH="$bin_dir:$PATH"
      fi
    fi
  done

  # Method 3: Try vfox env as fallback
  local shell_name
  shell_name=$(basename "${SHELL:-bash}")
  [[ "$shell_name" != "bash" && "$shell_name" != "zsh" ]] && shell_name="bash"
  eval "$(vfox env -s "$shell_name" 2>/dev/null)" || true
}
