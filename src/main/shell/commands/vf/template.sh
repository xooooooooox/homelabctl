#!/usr/bin/env bash
# @cmd
# @desc Manage project templates
# @arg subcommand! Subcommand (list, show)
# @arg args~ Additional arguments
# @example vf template list
# @example vf template show base
# @example vf template show k8s-cluster

cmd_vf_template() {
    local subcommand="${1:-list}"
    shift || true

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

    # 调用 radp-vf template
    "$radp_vf" template "$subcommand" "$@"
}
