#!/usr/bin/env bash
# K8S Addon Registry loader
# Provides functions to load and query addon definitions

# Global associative arrays for addon data
declare -gA __k8s_addon_registry
declare -g __k8s_addon_registry_loaded=""

#######################################
# Load addon registry from YAML files
# Loads both builtin and user registries
# Returns:
#   0 - Success
#   1 - Failure
#######################################
_k8s_addon_registry_load() {
  if [[ -n "$__k8s_addon_registry_loaded" ]]; then
    return 0
  fi

  local builtin_registry="${RADP_APP_ROOT}/src/main/shell/libs/k8s/addon/registry.yaml"
  local extra_config_path
  extra_config_path=$(_k8s_get_extra_config_path)
  local user_registry="$extra_config_path/addon/registry.yaml"

  # Check if yq is available
  if ! _common_is_command_available yq; then
    radp_log_error "yq is required to parse addon registry"
    return 1
  fi

  # Load builtin registry
  if [[ ! -f "$builtin_registry" ]]; then
    radp_log_error "Builtin addon registry not found: $builtin_registry"
    return 1
  fi

  # Get list of addon names
  local addon_names
  addon_names=$(yq -r '.addons | keys | .[]' "$builtin_registry" 2>/dev/null)

  for addon in $addon_names; do
    __k8s_addon_registry["$addon"]="$builtin_registry"
  done

  # Load user registry if exists (overrides builtin)
  if [[ -f "$user_registry" ]]; then
    local user_addon_names
    user_addon_names=$(yq -r '.addons | keys | .[]' "$user_registry" 2>/dev/null)

    for addon in $user_addon_names; do
      __k8s_addon_registry["$addon"]="$user_registry"
    done
  fi

  __k8s_addon_registry_loaded="true"
  return 0
}

#######################################
# Get addon property from registry
# Arguments:
#   1 - addon_name: Name of the addon
#   2 - property: Property path (e.g., "desc", "helm.repo_url")
# Outputs:
#   Property value
# Returns:
#   0 - Success
#   1 - Addon or property not found
#######################################
_k8s_addon_get_property() {
  local addon_name="${1:?'Addon name required'}"
  local property="${2:?'Property required'}"

  _k8s_addon_registry_load || return 1

  local registry_file="${__k8s_addon_registry[$addon_name]}"
  if [[ -z "$registry_file" ]]; then
    radp_log_error "Addon not found: $addon_name"
    return 1
  fi

  yq -r ".addons.\"$addon_name\".$property // empty" "$registry_file" 2>/dev/null
}

#######################################
# Check if addon exists in registry
# Arguments:
#   1 - addon_name: Name of the addon
# Returns:
#   0 - Addon exists
#   1 - Addon not found
#######################################
_k8s_addon_exists() {
  local addon_name="${1:?'Addon name required'}"

  _k8s_addon_registry_load || return 1

  [[ -n "${__k8s_addon_registry[$addon_name]}" ]]
}

#######################################
# List all available addons
# Outputs:
#   List of addon names with descriptions
# Returns:
#   0 - Success
#######################################
_k8s_addon_list() {
  _k8s_addon_registry_load || return 1

  local addon desc category

  printf "%-35s %-15s %s\n" "NAME" "CATEGORY" "DESCRIPTION"
  printf "%-35s %-15s %s\n" "-----------------------------------" "---------------" "----------------------------------------"

  for addon in "${!__k8s_addon_registry[@]}"; do
    local registry_file="${__k8s_addon_registry[$addon]}"
    desc=$(yq -r ".addons.\"$addon\".desc // \"No description\"" "$registry_file" 2>/dev/null)
    category=$(yq -r ".addons.\"$addon\".category // \"other\"" "$registry_file" 2>/dev/null)
    printf "%-35s %-15s %s\n" "$addon" "$category" "$desc"
  done | sort
}

#######################################
# Get addon default version
# Arguments:
#   1 - addon_name: Name of the addon
# Outputs:
#   Default version string
# Returns:
#   0 - Success
#   1 - Addon not found
#######################################
_k8s_addon_get_version() {
  local addon_name="${1:?'Addon name required'}"

  _k8s_addon_get_property "$addon_name" "default_version"
}

#######################################
# Get addon helm configuration
# Arguments:
#   1 - addon_name: Name of the addon
# Outputs:
#   Helm configuration in key=value format
# Returns:
#   0 - Success
#   1 - Addon not found or no helm config
#######################################
_k8s_addon_get_helm_config() {
  local addon_name="${1:?'Addon name required'}"

  _k8s_addon_registry_load || return 1

  local registry_file="${__k8s_addon_registry[$addon_name]}"
  if [[ -z "$registry_file" ]]; then
    return 1
  fi

  local repo_name repo_url chart namespace create_ns version_prefix
  repo_name=$(yq -r ".addons.\"$addon_name\".helm.repo_name // empty" "$registry_file" 2>/dev/null)
  repo_url=$(yq -r ".addons.\"$addon_name\".helm.repo_url // empty" "$registry_file" 2>/dev/null)
  chart=$(yq -r ".addons.\"$addon_name\".helm.chart // empty" "$registry_file" 2>/dev/null)
  namespace=$(yq -r ".addons.\"$addon_name\".helm.namespace // \"default\"" "$registry_file" 2>/dev/null)
  create_ns=$(yq -r ".addons.\"$addon_name\".helm.create_namespace // false" "$registry_file" 2>/dev/null)
  version_prefix=$(yq -r ".addons.\"$addon_name\".helm.version_prefix // empty" "$registry_file" 2>/dev/null)

  echo "repo_name=$repo_name"
  echo "repo_url=$repo_url"
  echo "chart=$chart"
  echo "namespace=$namespace"
  echo "create_namespace=$create_ns"
  echo "version_prefix=$version_prefix"
}

#######################################
# Get addon dependencies
# Arguments:
#   1 - addon_name: Name of the addon
# Outputs:
#   Space-separated list of dependency addon names
# Returns:
#   0 - Success (may be empty)
#######################################
_k8s_addon_get_dependencies() {
  local addon_name="${1:?'Addon name required'}"

  _k8s_addon_registry_load || return 1

  local registry_file="${__k8s_addon_registry[$addon_name]}"
  if [[ -z "$registry_file" ]]; then
    return 0
  fi

  yq -r ".addons.\"$addon_name\".depends_on // [] | .[]" "$registry_file" 2>/dev/null | tr '\n' ' '
}

#######################################
# Get addon post-install steps
# Arguments:
#   1 - addon_name: Name of the addon
# Outputs:
#   JSON array of post-install steps
# Returns:
#   0 - Success (may be empty)
#######################################
_k8s_addon_get_post_install() {
  local addon_name="${1:?'Addon name required'}"

  _k8s_addon_registry_load || return 1

  local registry_file="${__k8s_addon_registry[$addon_name]}"
  if [[ -z "$registry_file" ]]; then
    return 0
  fi

  yq -c ".addons.\"$addon_name\".post_install // []" "$registry_file" 2>/dev/null
}

# ============================================================================
# Profile Functions
# ============================================================================

#######################################
# Get builtin profiles directory
# Outputs:
#   Path to builtin profiles directory
#######################################
_k8s_addon_get_builtin_profiles_dir() {
  echo "${RADP_APP_ROOT}/src/main/shell/libs/k8s/addon/profiles"
}

#######################################
# Get user profiles directory
# Outputs:
#   Path to user profiles directory
#######################################
_k8s_addon_get_user_profiles_dir() {
  echo "$(_k8s_get_extra_config_path)/addon/profiles"
}

#######################################
# Find profile file by name
# Checks user directory first, then builtin
# Arguments:
#   1 - profile_name: Name of the profile
# Outputs:
#   Path to profile file
# Returns:
#   0 - Success
#   1 - Profile not found
#######################################
_k8s_addon_find_profile() {
  local profile_name="${1:?'Profile name required'}"

  local user_dir builtin_dir
  user_dir=$(_k8s_addon_get_user_profiles_dir)
  builtin_dir=$(_k8s_addon_get_builtin_profiles_dir)

  # Check user profiles first (takes precedence)
  local user_profile="$user_dir/${profile_name}.yaml"
  if [[ -f "$user_profile" ]]; then
    echo "$user_profile"
    return 0
  fi

  # Check builtin profiles
  local builtin_profile="$builtin_dir/${profile_name}.yaml"
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
# Returns:
#   0 - Success
#######################################
_k8s_addon_list_profiles() {
  local user_dir builtin_dir
  user_dir=$(_k8s_addon_get_user_profiles_dir)
  builtin_dir=$(_k8s_addon_get_builtin_profiles_dir)

  local -A seen_profiles=()

  # User profiles (take precedence)
  if [[ -d "$user_dir" ]]; then
    for profile_file in "$user_dir"/*.yaml; do
      [[ ! -f "$profile_file" ]] && continue
      local name desc
      name=$(basename "$profile_file" .yaml)
      desc=$(yq -r '.desc // "No description"' "$profile_file" 2>/dev/null)
      echo "${name}|${desc}|user"
      seen_profiles["$name"]="1"
    done
  fi

  # Builtin profiles
  if [[ -d "$builtin_dir" ]]; then
    for profile_file in "$builtin_dir"/*.yaml; do
      [[ ! -f "$profile_file" ]] && continue
      local name desc
      name=$(basename "$profile_file" .yaml)
      [[ -n "${seen_profiles[$name]:-}" ]] && continue
      desc=$(yq -r '.desc // "No description"' "$profile_file" 2>/dev/null)
      echo "${name}|${desc}|builtin"
    done
  fi
}

#######################################
# Parse profile and return addon list
# Arguments:
#   1 - profile_file: Path to profile file
# Outputs:
#   addon_name|version per line
# Returns:
#   0 - Success
#   1 - File not found
#######################################
_k8s_addon_parse_profile() {
  local profile_file="${1:?'Profile file required'}"

  [[ ! -f "$profile_file" ]] && return 1

  # Use yq to parse addons
  yq -r '.addons[] | .name + "|" + (.version // "latest")' "$profile_file" 2>/dev/null
}

#######################################
# Get profile metadata
# Arguments:
#   1 - profile_file: Path to profile file
#   2 - field: Field name (name, desc, platform)
# Outputs:
#   Field value
# Returns:
#   0 - Success
#######################################
_k8s_addon_get_profile_field() {
  local profile_file="${1:?'Profile file required'}"
  local field="${2:?'Field name required'}"

  [[ ! -f "$profile_file" ]] && return 1

  yq -r ".$field // empty" "$profile_file" 2>/dev/null
}
