#!/usr/bin/env bash
# Common installer utilities
# Provides functions for loading and running package installers

#######################################
# Load installer for a package
# Searches user installers first, then builtin
# Arguments:
#   1 - package name
# Returns:
#   0 - loaded, 1 - not found
#######################################
_setup_load_installer() {
    local name="$1"
    local builtin_dir user_dir
    builtin_dir=$(_setup_get_builtin_dir)
    user_dir=$(_setup_get_user_dir)

    # Check user installers first
    local user_installer="$user_dir/installers/${name}.sh"
    if [[ -f "$user_installer" ]]; then
        # shellcheck source=/dev/null
        source "$user_installer"
        return 0
    fi

    # Check builtin installers
    local builtin_installer="$builtin_dir/installers/${name}.sh"
    if [[ -f "$builtin_installer" ]]; then
        # shellcheck source=/dev/null
        source "$builtin_installer"
        return 0
    fi

    return 1
}

#######################################
# Run installer for a package
# Arguments:
#   1 - package name
#   2 - version (optional, default: latest)
# Returns:
#   0 - success, 1 - failure
#######################################
_setup_run_installer() {
    local name="$1"
    local version="${2:-latest}"

    # Load installer
    if ! _setup_load_installer "$name"; then
        radp_log_error "No installer found for: $name"
        return 1
    fi

    # Normalize function name (replace - with _)
    local install_func="_setup_install_${name//-/_}"

    # Check if install function exists
    if ! declare -f "$install_func" &>/dev/null; then
        radp_log_error "Install function not found: $install_func"
        return 1
    fi

    # Run the installer
    "$install_func" "$version"
}

#######################################
# Check if package is installed
# Uses check-cmd from registry or package name
# Arguments:
#   1 - package name
# Returns:
#   0 if installed, 1 if not
#######################################
_setup_check_installed() {
    local name="$1"
    local check_cmd

    check_cmd=$(_setup_registry_get_package_cmd "$name")
    [[ -z "$check_cmd" ]] && check_cmd="$name"

    _setup_is_installed "$check_cmd"
}

#######################################
# Get installed version of a package
# Arguments:
#   1 - package name
# Returns:
#   Version string or empty
#######################################
_setup_get_installed_version() {
    local name="$1"
    local check_cmd

    check_cmd=$(_setup_registry_get_package_cmd "$name")
    [[ -z "$check_cmd" ]] && check_cmd="$name"

    if ! _setup_is_installed "$check_cmd"; then
        return 1
    fi

    # Try common version flags
    local version=""
    version=$("$check_cmd" --version 2>/dev/null | head -1) ||
    version=$("$check_cmd" -v 2>/dev/null | head -1) ||
    version=$("$check_cmd" version 2>/dev/null | head -1) ||
    version=""

    # Clean up version output
    if [[ -n "$version" ]]; then
        # Extract version number pattern
        version=$(echo "$version" | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1)
    fi

    echo "$version"
}

#######################################
# Install binary to standard location
# Arguments:
#   1 - source binary path
#   2 - target name (optional, uses basename if not provided)
#   3 - target directory (optional, default: /usr/local/bin)
# Returns:
#   0 on success, 1 on failure
#######################################
_setup_install_binary() {
    local src="$1"
    local name="${2:-$(basename "$src")}"
    local dest_dir="${3:-/usr/local/bin}"

    if [[ ! -f "$src" ]]; then
        radp_log_error "Source binary not found: $src"
        return 1
    fi

    # Use sudo if needed
    local sudo_cmd=""
    if [[ ! -w "$dest_dir" ]]; then
        sudo_cmd="${gr_sudo:-sudo}"
    fi

    $sudo_cmd mkdir -p "$dest_dir" || return 1
    $sudo_cmd cp "$src" "$dest_dir/$name" || return 1
    $sudo_cmd chmod +x "$dest_dir/$name" || return 1

    radp_log_info "Installed $name to $dest_dir"
    return 0
}

#######################################
# Wrapper for radp_io_extract (for backward compatibility)
#######################################
_setup_extract_archive() {
    radp_io_extract "$@"
}

#######################################
# Wrapper for radp_io_mktemp_dir (for backward compatibility)
#######################################
_setup_mktemp_dir() {
    radp_io_mktemp_dir "homelabctl-setup"
}

#######################################
# Wrapper for radp_net_github_latest_release (for backward compatibility)
#######################################
_setup_github_latest_version() {
    radp_net_github_latest_release "$@"
}
