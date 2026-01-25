#!/usr/bin/env bash
# @cmd
# @desc Show radp-vagrant-framework version
# @example vf version

cmd_vf_version() {
    local version=""

    # Try to get version from RADP_VF_HOME
    if [[ -n "${RADP_VF_HOME:-}" ]]; then
        if [[ -x "${RADP_VF_HOME}/bin/radp-vf" ]]; then
            version=$("${RADP_VF_HOME}/bin/radp-vf" version 2>/dev/null || echo "")
        fi
    fi

    # Try radp-vf from PATH
    if [[ -z "$version" ]] && command -v radp-vf &>/dev/null; then
        version=$(radp-vf version 2>/dev/null || echo "")
    fi

    if [[ -n "$version" ]]; then
        echo "radp-vagrant-framework $version"
    else
        radp_log_error "radp-vagrant-framework not found"
        radp_log_error "Set RADP_VF_HOME or install radp-vagrant-framework"
        return 1
    fi
}
