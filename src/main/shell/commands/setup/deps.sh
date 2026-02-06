#!/usr/bin/env bash
# @cmd
# @desc Show package dependency tree
# @arg name! Package name
# @complete name _homelabctl_complete_packages
# @flag --reverse Show reverse dependencies (packages that depend on this one)
# @example setup deps markdownlint-cli
# @example setup deps nodejs --reverse

cmd_setup_deps() {
  local name="${1:-}"
  local reverse="${opt_reverse:-}"

  if [[ -z "$name" ]]; then
    radp_cli_help_command "setup deps"
    return 1
  fi

  _setup_registry_init

  if ! _setup_registry_has_package "$name"; then
    radp_log_error "Unknown package: $name"
    radp_log_info "Run 'homelabctl setup list' to see available packages"
    return 1
  fi

  if [[ -n "$reverse" ]]; then
    _setup_show_reverse_deps "$name"
  else
    _setup_show_deps_tree "$name" "" ""
  fi
}

#######################################
# Show dependency tree recursively
# Arguments:
#   1 - package name
#   2 - prefix for tree drawing
#   3 - visited packages (space-separated, for cycle detection)
#######################################
_setup_show_deps_tree() {
  local pkg="$1"
  local prefix="$2"
  local visited="$3"

  # Check for circular dependency
  if [[ " $visited " == *" $pkg "* ]]; then
    echo "${prefix}${pkg} (circular)"
    return 0
  fi

  # Get package info
  local desc requires status_marker=""
  desc=$(_setup_registry_get_package_desc "$pkg")
  requires=$(_setup_registry_get_package_requires "$pkg")

  # Check if installed
  local check_cmd
  check_cmd=$(_setup_registry_get_package_cmd "$pkg")
  if _setup_is_installed "$check_cmd"; then
    status_marker=" [installed]"
  fi

  # Print current package
  if [[ -z "$prefix" ]]; then
    echo "${pkg}${status_marker}"
  else
    echo "${prefix}${pkg}${status_marker}"
  fi

  # No dependencies
  [[ -z "$requires" ]] && return 0

  # Convert to array
  local -a deps=($requires)
  local total=${#deps[@]}
  local count=0

  visited="$visited $pkg"

  for dep in "${deps[@]}"; do
    ((count++)) || true
    local new_prefix connector

    # Determine tree connector
    if [[ $count -eq $total ]]; then
      connector="└── "
      new_prefix="${prefix//├/│}    "
      new_prefix="${new_prefix//└/ }"
    else
      connector="├── "
      new_prefix="${prefix}│   "
    fi

    # Check if dependency exists in registry
    if ! _setup_registry_has_package "$dep"; then
      echo "${prefix}${connector}${dep} (not in registry)"
      continue
    fi

    # Recurse
    _setup_show_deps_tree "$dep" "${prefix}${connector}" "$visited"
  done
}

#######################################
# Show reverse dependencies (what depends on this package)
# Arguments:
#   1 - package name
#######################################
_setup_show_reverse_deps() {
  local name="$1"
  local -a rdeps=()

  # Find all packages that require this one
  local pkg pkg_requires
  for pkg in "${!_SETUP_PACKAGES[@]}"; do
    pkg_requires=$(_setup_registry_get_package_requires "$pkg")
    if [[ " $pkg_requires " == *" $name "* ]]; then
      rdeps+=("$pkg")
    fi
  done

  echo "$name"

  if [[ ${#rdeps[@]} -eq 0 ]]; then
    echo "  (no packages depend on this)"
    return 0
  fi

  # Sort rdeps
  IFS=$'\n' rdeps=($(sort <<<"${rdeps[*]}")); unset IFS

  local total=${#rdeps[@]}
  local count=0

  for dep in "${rdeps[@]}"; do
    ((count++)) || true
    local connector
    if [[ $count -eq $total ]]; then
      connector="└── "
    else
      connector="├── "
    fi

    local status_marker=""
    local check_cmd
    check_cmd=$(_setup_registry_get_package_cmd "$dep")
    if _setup_is_installed "$check_cmd"; then
      status_marker=" [installed]"
    fi

    echo "${connector}${dep}${status_marker}"
  done
}
