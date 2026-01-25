#!/usr/bin/env bash
# @cmd
# @desc List available project templates
# @example vf template list

cmd_vf_template_list() {
    # 查找 radp-vf CLI
    local radp_vf=""
    if [[ -n "${RADP_VF_HOME:-}" && -x "${RADP_VF_HOME}/bin/radp-vf" ]]; then
        radp_vf="${RADP_VF_HOME}/bin/radp-vf"
    elif command -v radp-vf &>/dev/null; then
        radp_vf="radp-vf"
    else
        radp_log_error "radp-vf not found"
        radp_log_error "Please set RADP_VF_HOME or ensure radp-vagrant-framework is installed"
        return 1
    fi

    "$radp_vf" template list
}
