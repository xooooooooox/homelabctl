#!/usr/bin/env bash
# Setup registry management
# Handles loading and querying package/profile registries

# Global variables for loaded registry data
declare -gA _SETUP_PACKAGES=()
declare -gA _SETUP_PACKAGE_DESCS=()
declare -gA _SETUP_PACKAGE_CATS=()
declare -gA _SETUP_PACKAGE_CMDS=()
declare -gA _SETUP_CATEGORIES=()
declare -g _SETUP_REGISTRY_INITIALIZED=""

#######################################
# Load packages from registry YAML file
# Uses simple line-based parsing to avoid yq dependency
# Globals:
#   _SETUP_PACKAGES, _SETUP_PACKAGE_DESCS, _SETUP_PACKAGE_CATS, _SETUP_PACKAGE_CMDS
# Arguments:
#   1 - registry file path
#######################################
_setup_registry_load() {
  local registry_file="$1"
  [[ ! -f "$registry_file" ]] && return 1

  local in_packages=""
  local in_categories=""
  local current_pkg=""
  local current_cat=""
  local line key value indent

  while IFS= read -r line || [[ -n "$line" ]]; do
    # Skip empty lines and comments
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

    # Detect section
    if [[ "$line" =~ ^packages:[[:space:]]*$ ]]; then
      in_packages="true"
      in_categories=""
      continue
    elif [[ "$line" =~ ^categories:[[:space:]]*$ ]]; then
      in_packages=""
      in_categories="true"
      continue
    fi

    # Count leading spaces
    indent="${line%%[! ]*}"
    indent=${#indent}

    # Parse packages section
    if [[ -n "$in_packages" ]]; then
      # Package name (2-space indent)
      if [[ $indent -eq 2 && "$line" =~ ^[[:space:]]*([a-zA-Z0-9_-]+):[[:space:]]*$ ]]; then
        current_pkg="${BASH_REMATCH[1]}"
        _SETUP_PACKAGES["$current_pkg"]="1"
        continue
      fi

      # Package properties (4-space indent)
      if [[ $indent -eq 4 && -n "$current_pkg" ]]; then
        key=$(echo "$line" | sed 's/^[[:space:]]*//' | cut -d: -f1)
        value=$(echo "$line" | sed "s/^[[:space:]]*${key}:[[:space:]]*//" | sed 's/^["'"'"']//' | sed 's/["'"'"']$//')

        case "$key" in
        desc)
          _SETUP_PACKAGE_DESCS["$current_pkg"]="$value"
          ;;
        category)
          _SETUP_PACKAGE_CATS["$current_pkg"]="$value"
          ;;
        check-cmd)
          _SETUP_PACKAGE_CMDS["$current_pkg"]="$value"
          ;;
        esac
      fi
    fi

    # Parse categories section
    if [[ -n "$in_categories" ]]; then
      # Category name (2-space indent)
      if [[ $indent -eq 2 && "$line" =~ ^[[:space:]]*([a-zA-Z0-9_-]+):[[:space:]]*$ ]]; then
        current_cat="${BASH_REMATCH[1]}"
        continue
      fi

      # Category description (4-space indent)
      if [[ $indent -eq 4 && -n "$current_cat" && "$line" =~ desc: ]]; then
        value=$(echo "$line" | sed 's/^[[:space:]]*desc:[[:space:]]*//' | sed 's/^["'"'"']//' | sed 's/["'"'"']$//')
        _SETUP_CATEGORIES["$current_cat"]="$value"
      fi
    fi
  done <"$registry_file"
}

#######################################
# Initialize registry (builtin + user)
# Loads both builtin and user registries
# Globals:
#   _SETUP_REGISTRY_INITIALIZED
#######################################
_setup_registry_init() {
  [[ -n "$_SETUP_REGISTRY_INITIALIZED" ]] && return 0

  local builtin_dir user_dir
  builtin_dir=$(_setup_get_builtin_dir)
  user_dir=$(_setup_get_user_dir)

  local builtin_registry="$builtin_dir/registry.yaml"
  local user_registry="$user_dir/registry.yaml"

  # Load builtin registry
  if [[ -f "$builtin_registry" ]]; then
    _setup_registry_load "$builtin_registry"
  fi

  # Merge user registry (user values override builtin)
  if [[ -f "$user_registry" ]]; then
    _setup_registry_load "$user_registry"
  fi

  _SETUP_REGISTRY_INITIALIZED="true"
}

#######################################
# Check if package exists in registry
# Arguments:
#   1 - package name
# Returns:
#   0 if exists, 1 if not
#######################################
_setup_registry_has_package() {
  local name="$1"
  [[ -n "${_SETUP_PACKAGES[$name]:-}" ]]
}

#######################################
# Get package description
# Arguments:
#   1 - package name
# Returns:
#   Package description
#######################################
_setup_registry_get_package_desc() {
  local name="$1"
  echo "${_SETUP_PACKAGE_DESCS[$name]:-}"
}

#######################################
# Get package category
# Arguments:
#   1 - package name
# Returns:
#   Package category
#######################################
_setup_registry_get_package_category() {
  local name="$1"
  echo "${_SETUP_PACKAGE_CATS[$name]:-}"
}

#######################################
# Get package check command
# Arguments:
#   1 - package name
# Returns:
#   Command to check if installed
#######################################
_setup_registry_get_package_cmd() {
  local name="$1"
  echo "${_SETUP_PACKAGE_CMDS[$name]:-$name}"
}

#######################################
# List all packages
# Arguments:
#   1 - category filter (optional)
# Outputs:
#   package_name|description|category per line
#######################################
_setup_registry_list_packages() {
  local category_filter="${1:-}"

  for pkg in "${!_SETUP_PACKAGES[@]}"; do
    local cat="${_SETUP_PACKAGE_CATS[$pkg]:-}"
    local desc="${_SETUP_PACKAGE_DESCS[$pkg]:-}"

    # Apply category filter
    if [[ -n "$category_filter" && "$cat" != "$category_filter" ]]; then
      continue
    fi

    echo "${pkg}|${desc}|${cat}"
  done | sort
}

#######################################
# List all categories
# Outputs:
#   category_name|description per line
#######################################
_setup_registry_list_categories() {
  for cat in "${!_SETUP_CATEGORIES[@]}"; do
    local desc="${_SETUP_CATEGORIES[$cat]:-}"
    echo "${cat}|${desc}"
  done | sort
}

#######################################
# Find profile file by name
# Arguments:
#   1 - profile name
# Returns:
#   Path to profile file, empty if not found
#######################################
_setup_find_profile() {
  local name="$1"
  local builtin_dir user_dir
  builtin_dir=$(_setup_get_builtin_dir)
  user_dir=$(_setup_get_user_dir)

  # Check user profiles first
  local user_profile="$user_dir/profiles/${name}.yaml"
  if [[ -f "$user_profile" ]]; then
    echo "$user_profile"
    return 0
  fi

  # Check builtin profiles
  local builtin_profile="$builtin_dir/profiles/${name}.yaml"
  if [[ -f "$builtin_profile" ]]; then
    echo "$builtin_profile"
    return 0
  fi

  return 1
}

#######################################
# List all available profiles
# Outputs:
#   profile_name|description|source per line
#######################################
_setup_list_profiles() {
  local builtin_dir user_dir
  builtin_dir=$(_setup_get_builtin_dir)
  user_dir=$(_setup_get_user_dir)

  local -A seen_profiles=()

  # User profiles (take precedence)
  if [[ -d "$user_dir/profiles" ]]; then
    for profile_file in "$user_dir/profiles"/*.yaml; do
      [[ ! -f "$profile_file" ]] && continue
      local name desc
      name=$(basename "$profile_file" .yaml)
      desc=$(_setup_yaml_get_value "desc" <"$profile_file")
      echo "${name}|${desc}|user"
      seen_profiles["$name"]="1"
    done
  fi

  # Builtin profiles
  if [[ -d "$builtin_dir/profiles" ]]; then
    for profile_file in "$builtin_dir/profiles"/*.yaml; do
      [[ ! -f "$profile_file" ]] && continue
      local name desc
      name=$(basename "$profile_file" .yaml)
      [[ -n "${seen_profiles[$name]:-}" ]] && continue
      desc=$(_setup_yaml_get_value "desc" <"$profile_file")
      echo "${name}|${desc}|builtin"
    done
  fi
}

#######################################
# Parse profile and return package list
# Arguments:
#   1 - profile file path
# Outputs:
#   package_name|version per line
#######################################
_setup_parse_profile() {
  local profile_file="$1"
  [[ ! -f "$profile_file" ]] && return 1

  local in_packages=""
  local current_pkg=""
  local current_version="latest"
  local line indent

  while IFS= read -r line || [[ -n "$line" ]]; do
    # Skip empty lines and comments
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

    # Count leading spaces
    indent="${line%%[! ]*}"
    indent=${#indent}

    # Detect packages section
    if [[ "$line" =~ ^packages:[[:space:]]*$ ]]; then
      in_packages="true"
      continue
    fi

    # Exit packages section on new top-level key
    if [[ $indent -eq 0 && ! "$line" =~ ^packages: ]]; then
      in_packages=""
      continue
    fi

    # Parse packages
    if [[ -n "$in_packages" ]]; then
      # Package entry start (- name:)
      if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*name:[[:space:]]*([a-zA-Z0-9_-]+) ]]; then
        # Output previous package if exists
        if [[ -n "$current_pkg" ]]; then
          echo "${current_pkg}|${current_version}"
        fi
        current_pkg="${BASH_REMATCH[1]}"
        current_version="latest"
        continue
      fi

      # Version property
      if [[ -n "$current_pkg" && "$line" =~ version:[[:space:]]*[\"\']*([^\"\']+) ]]; then
        current_version="${BASH_REMATCH[1]}"
      fi
    fi
  done <"$profile_file"

  # Output last package
  if [[ -n "$current_pkg" ]]; then
    echo "${current_pkg}|${current_version}"
  fi
}
