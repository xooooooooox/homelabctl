#!/usr/bin/env bash

# IDE code completion support
# This references the auto-generated completion.sh which provides navigation to:
#   - Framework library functions (radp_*)
#   - Framework global variables (gr_fw_*, gr_radp_fw_*)
#   - User global variables (gr_radp_extend_*)
#   - User library functions
# Note: completion.sh is auto-generated and should be in .gitignore
# shellcheck source=../config/completion.sh

# homelabctl version - single source of truth for release management
# For package manager installs, this is the authoritative version
declare -g _homelabctl_release_version=v0.1.4

# Build version string: check for manual install .version file
_homelabctl_build_version() {
  local app_root="${RADP_APP_ROOT:-}"
  local version_file="${app_root}/.version"

  # If .version file exists (manual install), build version from it
  if [[ -f "${version_file}" ]]; then
    local ref="" commit="" install_date=""
    while IFS='=' read -r key value; do
      case "${key}" in
        ref) ref="${value}" ;;
        commit) commit="${value}" ;;
        date) install_date="${value}" ;;
      esac
    done < "${version_file}"

    # Build display string
    local display="${ref}"
    [[ -n "${commit}" && "${ref}" != v* ]] && display="${ref}@${commit}"
    [[ -n "${install_date}" ]] && display="${display} (manual, ${install_date})"
    echo "${display}"
    return
  fi

  # Default: use release version
  echo "${_homelabctl_release_version}"
}

declare -gr gr_homelabctl_version="$(_homelabctl_build_version)"
