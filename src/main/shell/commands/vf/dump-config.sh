# @cmd
# @desc Export merged configuration
# @option -e, --env <name> Override environment name
# @option -f, --format <format> Output format (json or yaml, default: json)
# @option -o, --output <file> Output file path
# @arg filter Filter by guest ID or machine name
# @example vf dump-config
# @example vf dump-config -e prod
# @example vf dump-config -f yaml
# @example vf dump-config -o config.json
# @example vf dump-config node-1

cmd_vf_dump_config() {
    local env="${opt_env:-}"
    local format="${opt_format:-}"
    local output="${opt_output:-}"
    local filter="${1:-}"

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

    # dump-config 命令
    args+=("dump-config")

    # 格式选项
    if [[ -n "$format" ]]; then
        args+=("-f" "$format")
    fi

    # 输出文件选项
    if [[ -n "$output" ]]; then
        args+=("-o" "$output")
    fi

    # 过滤参数
    if [[ -n "$filter" ]]; then
        args+=("$filter")
    fi

    # 执行 radp-vf
    "$radp_vf" "${args[@]}"
}
