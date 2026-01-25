#!/usr/bin/env bash
# @cmd
# @desc Initialize a new radp-vagrant-framework project
# @arg dir Target directory (default: current directory)
# @example vf init
# @example vf init ~/my-lab

cmd_vf_init() {
    local target_dir="${1:-.}"

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

    # 调用 radp-vf init
    "$radp_vf" init "$target_dir"

    echo ""
    radp_log_info "homelabctl commands:"
    radp_log_info "  cd $target_dir"
    radp_log_info "  homelabctl vf info        # Check environment"
    radp_log_info "  homelabctl vf dump-config # Preview merged config"
    radp_log_info "  homelabctl vg status      # Show VM status"
    radp_log_info "  homelabctl vg up          # Start VMs"
}
