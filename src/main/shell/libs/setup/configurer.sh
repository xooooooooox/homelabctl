#!/usr/bin/env bash
# Common configurer utilities
# Provides functions for loading and running package configurers

#######################################
# Load configurer for a package
# Searches user configurers first, then builtin
# Arguments:
#   1 - package name
# Returns:
#   0 - loaded, 1 - not found
#######################################
_setup_load_configurer() {
    local name="$1"
    local builtin_dir user_dir
    builtin_dir=$(_setup_get_builtin_dir)
    user_dir=$(_setup_get_user_dir)

    # Check user configurers first
    local user_configurer="$user_dir/configurers/${name}.sh"
    if [[ -f "$user_configurer" ]]; then
        # shellcheck source=/dev/null
        source "$user_configurer"
        return 0
    fi

    # Check builtin configurers
    local builtin_configurer="$builtin_dir/configurers/${name}.sh"
    if [[ -f "$builtin_configurer" ]]; then
        # shellcheck source=/dev/null
        source "$builtin_configurer"
        return 0
    fi

    return 1
}

#######################################
# Check if configurer exists for a package
# Arguments:
#   1 - package name
# Returns:
#   0 - configurer exists, 1 - not found
#######################################
_setup_has_configurer() {
    local name="$1"
    local builtin_dir user_dir
    builtin_dir=$(_setup_get_builtin_dir)
    user_dir=$(_setup_get_user_dir)

    # Check user configurers first
    [[ -f "$user_dir/configurers/${name}.sh" ]] && return 0

    # Check builtin configurers
    [[ -f "$builtin_dir/configurers/${name}.sh" ]] && return 0

    return 1
}

#######################################
# Run a specific configurer function
# Arguments:
#   1 - package name
#   2 - action name (e.g., rootless, proxy, mirrors)
#   3+ - arguments to pass to the configurer function
# Returns:
#   0 - success, 1 - failure
#######################################
_setup_run_configurer() {
    local name="$1"
    local action="$2"
    shift 2

    # Load configurer
    if ! _setup_load_configurer "$name"; then
        radp_log_error "No configurer found for: $name"
        return 1
    fi

    # Normalize function name (replace - with _)
    local configure_func="_setup_configure_${name//-/_}_${action//-/_}"

    # Check if configure function exists
    if ! declare -f "$configure_func" &>/dev/null; then
        radp_log_error "Configure function not found: $configure_func"
        return 1
    fi

    # Run the configurer
    "$configure_func" "$@"
}

#######################################
# Check if a specific configurer action exists
# Arguments:
#   1 - package name
#   2 - action name (e.g., rootless, proxy, mirrors)
# Returns:
#   0 - action exists, 1 - not found
#######################################
_setup_has_configurer_action() {
    local name="$1"
    local action="$2"

    # Load configurer
    if ! _setup_load_configurer "$name"; then
        return 1
    fi

    # Normalize function name (replace - with _)
    local configure_func="_setup_configure_${name//-/_}_${action//-/_}"

    # Check if configure function exists
    declare -f "$configure_func" &>/dev/null
}
