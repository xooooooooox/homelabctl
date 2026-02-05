#!/usr/bin/env bash
# Shared utility functions for homelabctl modules
# Sourced by setup, k8s, gitlab, and other modules

#######################################
# Get architecture in common format
# Outputs:
#   amd64 or arm64
#######################################
_common_get_arch() {
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
# Outputs:
#   linux or darwin
#######################################
_common_get_os() {
  local os
  os=$(radp_os_get_distro_os 2>/dev/null || uname -s)
  echo "${os,,}"
}

#######################################
# Get platform string (os-arch format)
# Outputs:
#   Platform string like linux-amd64, darwin-arm64
#######################################
_common_get_platform() {
  local os arch
  os=$(_common_get_os)
  arch=$(_common_get_arch)
  echo "${os}-${arch}"
}

#######################################
# Check if a package is installed
# Arguments:
#   1 - check specification, supports:
#       - command name (default): checks via 'command -v'
#       - "dir:<path>": checks if directory exists
#       - "file:<path>": checks if file exists
# Returns:
#   0 if installed, 1 if not
#######################################
_common_is_installed() {
  local spec="$1"

  case "$spec" in
    dir:*)
      local dir="${spec#dir:}"
      dir="${dir/#\~/$HOME}"
      [[ -d "$dir" ]]
      ;;
    file:*)
      local file="${spec#file:}"
      file="${file/#\~/$HOME}"
      [[ -f "$file" ]]
      ;;
    *)
      command -v "$spec" &>/dev/null
      ;;
  esac
}

#######################################
# Check if a command is available
# Arguments:
#   1 - command name
# Returns:
#   0 if available, 1 if not
#######################################
_common_is_command_available() {
  command -v "$1" &>/dev/null
}

#######################################
# Check system requirements (CPU/RAM)
# Arguments:
#   --min-cpu <cores>    Minimum CPU cores required
#   --min-ram <gb>       Minimum RAM in GB required
#   --product <name>     Product name for warning message
#   --skip-prompt        Skip confirmation prompt on failure
# Returns:
#   0 if requirements met or user confirms, 1 if not
#######################################
_common_check_requirements() {
  local min_cpu="" min_ram="" product="" skip_prompt=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --min-cpu) min_cpu="$2"; shift 2 ;;
      --min-ram) min_ram="$2"; shift 2 ;;
      --product) product="$2"; shift 2 ;;
      --skip-prompt) skip_prompt="true"; shift ;;
      *) shift ;;
    esac
  done

  local failed=""

  if [[ -n "$min_cpu" ]] && ! radp_os_check_min_cpu_cores "$min_cpu"; then
    failed="true"
  fi

  if [[ -n "$min_ram" ]] && ! radp_os_check_min_ram "${min_ram}GB"; then
    failed="true"
  fi

  if [[ -n "$failed" ]]; then
    if [[ -z "$skip_prompt" ]]; then
      radp_log_warn "System does not meet minimum requirements for ${product:-the application}"
      if ! radp_io_prompt_confirm --msg "Continue anyway? (y/N)" --default N --timeout 60; then
        return 1
      fi
    else
      return 1
    fi
  fi

  return 0
}

#######################################
# Simple YAML value parser
# Wrapper for radp_io_yaml_get_value
# Arguments:
#   1 - key name
#   2 - YAML content (via stdin if not provided)
# Outputs:
#   Value for the key
#######################################
_common_yaml_get_value() {
  radp_io_yaml_get_value "$@"
}

#######################################
# Parse YAML list items
# Wrapper for radp_io_yaml_get_list
# Arguments:
#   stdin - YAML content
# Outputs:
#   List items, one per line
#######################################
_common_yaml_get_list_items() {
  radp_io_yaml_get_list
}
