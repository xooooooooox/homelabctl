# @cmd
# @desc Validate YAML configuration files
# @option -e, --env <name> Override environment name
# @example vf validate
# @example vf validate -e prod

cmd_vf_validate() {
    local env="${opt_env:-}"

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

    # 构建命令参数
    local args=()

    # 设置配置目录
    if [[ -d "./config" && -z "${RADP_VAGRANT_CONFIG_DIR:-}" ]]; then
        args+=("-c" "$(pwd)/config")
    fi

    # 设置环境覆盖
    if [[ -n "$env" ]]; then
        args+=("-e" "$env")
    fi

    # 执行 radp-vf validate
    "$radp_vf" "${args[@]}" validate
}
