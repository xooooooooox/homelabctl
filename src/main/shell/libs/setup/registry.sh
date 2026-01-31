#!/usr/bin/env bash
# Setup registry management
# Handles loading and querying package/profile registries

# Global variables for loaded registry data
declare -gA _SETUP_PACKAGES=()
declare -gA _SETUP_PACKAGE_DESCS=()
declare -gA _SETUP_PACKAGE_CATS=()
declare -gA _SETUP_PACKAGE_CMDS=()
declare -gA _SETUP_PACKAGE_REQUIRES=()
declare -gA _SETUP_PACKAGE_RECOMMENDS=()
declare -gA _SETUP_PACKAGE_CONFLICTS=()
# Platform-specific dependencies (keyed as "pkg:platform")
declare -gA _SETUP_PACKAGE_REQUIRES_PLATFORM=()
declare -gA _SETUP_PACKAGE_RECOMMENDS_PLATFORM=()
declare -gA _SETUP_PACKAGE_CONFLICTS_PLATFORM=()
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
  # State for nested platform parsing
  local in_platform=""
  local current_platform=""
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
      in_categories=""
      in_platform=""
      current_platform=""
      continue
    fi

    # Count leading spaces
    indent="${line%%[! ]*}"
    indent=${#indent}

    # Parse packages section
    if [[ -n "$in_packages" ]]; then
      # Package name (2-space indent) - exit platform block
      if [[ $indent -eq 2 && "$line" =~ ^[[:space:]]*([a-zA-Z0-9_-]+):[[:space:]]*$ ]]; then
        current_pkg="${BASH_REMATCH[1]}"
        _SETUP_PACKAGES["$current_pkg"]="1"
        in_platform=""
        current_platform=""
        continue
      fi

      # Package properties (4-space indent)
      if [[ $indent -eq 4 && -n "$current_pkg" ]]; then
        # Exit platform block when we're back at 4-space indent
        in_platform=""
        current_platform=""

        # Check for platform block start
        if [[ "$line" =~ ^[[:space:]]*platform:[[:space:]]*$ ]]; then
          in_platform="true"
          continue
        fi

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
        requires)
          _SETUP_PACKAGE_REQUIRES["$current_pkg"]="$value"
          ;;
        requires-*)
          # Legacy format (deprecated) - still supported for backward compatibility
          local platform="${key#requires-}"
          _SETUP_PACKAGE_REQUIRES_PLATFORM["$current_pkg:$platform"]="$value"
          ;;
        recommends)
          _SETUP_PACKAGE_RECOMMENDS["$current_pkg"]="$value"
          ;;
        recommends-*)
          # Legacy format (deprecated) - still supported for backward compatibility
          local platform="${key#recommends-}"
          _SETUP_PACKAGE_RECOMMENDS_PLATFORM["$current_pkg:$platform"]="$value"
          ;;
        conflicts)
          _SETUP_PACKAGE_CONFLICTS["$current_pkg"]="$value"
          ;;
        conflicts-*)
          # Legacy format (deprecated) - still supported for backward compatibility
          local platform="${key#conflicts-}"
          _SETUP_PACKAGE_CONFLICTS_PLATFORM["$current_pkg:$platform"]="$value"
          ;;
        esac
        continue
      fi

      # Platform name (6-space indent inside platform block)
      # Matches: os (e.g., linux, darwin) or os-arch (e.g., linux-arm64, darwin-amd64)
      if [[ -n "$in_platform" && $indent -eq 6 && "$line" =~ ^[[:space:]]*([a-z]+(-[a-z0-9]+)?):[[:space:]]*$ ]]; then
        current_platform="${BASH_REMATCH[1]}"
        continue
      fi

      # Platform-specific properties (8-space indent)
      if [[ -n "$in_platform" && -n "$current_platform" && $indent -eq 8 ]]; then
        key=$(echo "$line" | sed 's/^[[:space:]]*//' | cut -d: -f1)
        value=$(echo "$line" | sed "s/^[[:space:]]*${key}:[[:space:]]*//" | sed 's/^["'"'"']//' | sed 's/["'"'"']$//')

        case "$key" in
        requires)
          _SETUP_PACKAGE_REQUIRES_PLATFORM["$current_pkg:$current_platform"]="$value"
          ;;
        recommends)
          _SETUP_PACKAGE_RECOMMENDS_PLATFORM["$current_pkg:$current_platform"]="$value"
          ;;
        conflicts)
          _SETUP_PACKAGE_CONFLICTS_PLATFORM["$current_pkg:$current_platform"]="$value"
          ;;
        esac
        continue
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
# Resolve platform-specific value using lookup chain
# Lookup order: os-arch (e.g., linux-arm64) → os (e.g., linux) → empty
# Only ONE platform value is selected, then merged with base by caller
# Arguments:
#   1 - nameref to platform associative array
#   2 - package name
# Returns:
#   Platform-specific value (may include ! prefix for override)
#######################################
_setup_resolve_platform_value() {
  local -n __plat_arr="$1"
  local pkg="$2"
  local os arch
  os=$(_setup_get_os)
  arch=$(_setup_get_arch)

  # Priority 1: Try os-arch (e.g., linux-arm64)
  local os_arch_key="${pkg}:${os}-${arch}"
  if [[ -n "${__plat_arr[$os_arch_key]:-}" ]]; then
    echo "${__plat_arr[$os_arch_key]}"
    return 0
  fi

  # Priority 2: Fallback to os (e.g., linux)
  local os_key="${pkg}:${os}"
  if [[ -n "${__plat_arr[$os_key]:-}" ]]; then
    echo "${__plat_arr[$os_key]}"
    return 0
  fi

  # No platform-specific value found
  echo ""
}

#######################################
# Get package required dependencies
# Merges base requires with platform-specific requires
# Uses lookup chain: os-arch → os → (none)
# Supports ! prefix for override mode (clears base, uses platform value)
# Arguments:
#   1 - package name
# Returns:
#   Space-separated list of required dependencies
#######################################
_setup_registry_get_package_requires() {
  local name="$1"
  local base="${_SETUP_PACKAGE_REQUIRES[$name]:-}"
  local platform_specific
  platform_specific=$(_setup_resolve_platform_value _SETUP_PACKAGE_REQUIRES_PLATFORM "$name")

  # Handle override syntax (! prefix)
  _setup_apply_platform_deps "$base" "$platform_specific"
}

#######################################
# Get package recommended dependencies
# Merges base recommends with platform-specific recommends
# Uses lookup chain: os-arch → os → (none)
# Supports ! prefix for override mode (clears base, uses platform value)
# Arguments:
#   1 - package name
# Returns:
#   Space-separated list of recommended dependencies
#######################################
_setup_registry_get_package_recommends() {
  local name="$1"
  local base="${_SETUP_PACKAGE_RECOMMENDS[$name]:-}"
  local platform_specific
  platform_specific=$(_setup_resolve_platform_value _SETUP_PACKAGE_RECOMMENDS_PLATFORM "$name")

  # Handle override syntax (! prefix)
  _setup_apply_platform_deps "$base" "$platform_specific"
}

#######################################
# Get package conflicts
# Merges base conflicts with platform-specific conflicts
# Uses lookup chain: os-arch → os → (none)
# Supports ! prefix for override mode (clears base, uses platform value)
# Arguments:
#   1 - package name
# Returns:
#   Space-separated list of conflicting packages
#######################################
_setup_registry_get_package_conflicts() {
  local name="$1"
  local base="${_SETUP_PACKAGE_CONFLICTS[$name]:-}"
  local platform_specific
  platform_specific=$(_setup_resolve_platform_value _SETUP_PACKAGE_CONFLICTS_PLATFORM "$name")

  # Handle override syntax (! prefix)
  _setup_apply_platform_deps "$base" "$platform_specific"
}

#######################################
# Merge two space-separated dependency lists
# Removes duplicates while preserving order
# Arguments:
#   1 - first list
#   2 - second list
# Returns:
#   Merged space-separated list
#######################################
_setup_merge_deps() {
  local list1="$1"
  local list2="$2"
  local -A seen=()
  local result=""

  local item
  for item in $list1 $list2; do
    if [[ -z "${seen[$item]:-}" ]]; then
      seen["$item"]=1
      result="$result $item"
    fi
  done

  echo "${result# }"
}

#######################################
# Apply platform-specific dependencies with override support
# Handles ! prefix for override mode:
#   - "!pkg1 pkg2" -> clears base, uses "pkg1 pkg2"
#   - "!"          -> clears base, returns empty
#   - "pkg1"       -> appends to base
# Arguments:
#   1 - base dependency list
#   2 - platform-specific dependency list
# Returns:
#   Final dependency list
#######################################
_setup_apply_platform_deps() {
  local base="$1"
  local platform_val="$2"

  # No platform value: return base as-is
  if [[ -z "$platform_val" ]]; then
    echo "$base"
    return 0
  fi

  # Check for override syntax (! prefix)
  if [[ "$platform_val" == "!"* ]]; then
    # Override mode: ignore base, use platform value (without !)
    local override_val="${platform_val#!}"
    # Trim leading/trailing whitespace
    override_val="${override_val#"${override_val%%[![:space:]]*}"}"
    override_val="${override_val%"${override_val##*[![:space:]]}"}"
    echo "$override_val"
    return 0
  fi

  # Append mode: merge base and platform-specific
  _setup_merge_deps "$base" "$platform_val"
}

#######################################
# Get base (non-platform-specific) requires
# Arguments:
#   1 - package name
# Returns:
#   Base requires value
#######################################
_setup_registry_get_package_requires_base() {
  local name="$1"
  echo "${_SETUP_PACKAGE_REQUIRES[$name]:-}"
}

#######################################
# Get base (non-platform-specific) recommends
# Arguments:
#   1 - package name
# Returns:
#   Base recommends value
#######################################
_setup_registry_get_package_recommends_base() {
  local name="$1"
  echo "${_SETUP_PACKAGE_RECOMMENDS[$name]:-}"
}

#######################################
# Get base (non-platform-specific) conflicts
# Arguments:
#   1 - package name
# Returns:
#   Base conflicts value
#######################################
_setup_registry_get_package_conflicts_base() {
  local name="$1"
  echo "${_SETUP_PACKAGE_CONFLICTS[$name]:-}"
}

#######################################
# Get platform-specific requires (raw value)
# Arguments:
#   1 - package name
#   2 - platform (linux, darwin, etc.)
# Returns:
#   Platform-specific requires value (may include ! prefix)
#######################################
_setup_registry_get_package_requires_platform() {
  local name="$1"
  local platform="$2"
  echo "${_SETUP_PACKAGE_REQUIRES_PLATFORM[$name:$platform]:-}"
}

#######################################
# Get platform-specific recommends (raw value)
# Arguments:
#   1 - package name
#   2 - platform (linux, darwin, etc.)
# Returns:
#   Platform-specific recommends value (may include ! prefix)
#######################################
_setup_registry_get_package_recommends_platform() {
  local name="$1"
  local platform="$2"
  echo "${_SETUP_PACKAGE_RECOMMENDS_PLATFORM[$name:$platform]:-}"
}

#######################################
# Get platform-specific conflicts (raw value)
# Arguments:
#   1 - package name
#   2 - platform (linux, darwin, etc.)
# Returns:
#   Platform-specific conflicts value (may include ! prefix)
#######################################
_setup_registry_get_package_conflicts_platform() {
  local name="$1"
  local platform="$2"
  echo "${_SETUP_PACKAGE_CONFLICTS_PLATFORM[$name:$platform]:-}"
}

#######################################
# Get all platforms with specific dependencies for a package
# Arguments:
#   1 - package name
# Returns:
#   Space-separated list of platforms (linux, darwin, etc.)
#######################################
_setup_registry_get_package_platforms() {
  local name="$1"
  local -A platforms=()

  # Scan all platform keys for this package
  local key
  for key in "${!_SETUP_PACKAGE_REQUIRES_PLATFORM[@]}"; do
    if [[ "$key" == "$name:"* ]]; then
      platforms["${key#$name:}"]=1
    fi
  done
  for key in "${!_SETUP_PACKAGE_RECOMMENDS_PLATFORM[@]}"; do
    if [[ "$key" == "$name:"* ]]; then
      platforms["${key#$name:}"]=1
    fi
  done
  for key in "${!_SETUP_PACKAGE_CONFLICTS_PLATFORM[@]}"; do
    if [[ "$key" == "$name:"* ]]; then
      platforms["${key#$name:}"]=1
    fi
  done

  echo "${!platforms[*]}"
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
