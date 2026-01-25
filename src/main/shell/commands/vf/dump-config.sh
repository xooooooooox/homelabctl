# @cmd
# @desc Export merged configuration
# @option -e, --env <name> Environment name
# @option -g, --guest <id> Filter by guest ID or machine name
# @option -f, --format <fmt> Output format: json or yaml (default: json)
# @option -o, --output <file> Output file (default: stdout)
# @example vf dump-config
# @example vf dump-config -e prod
# @example vf dump-config -g node-1
# @example vf dump-config -f yaml

cmd_vf_dump_config() {
    local env="${opt_env:-}"
    local guest="${opt_guest:-}"
    local format="${opt_format:-json}"
    local output="${opt_output:-}"

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
    local -a args=("dump-config")

    # 设置配置目录
    if [[ -d "./config" ]]; then
        args+=("-c" "./config")
    fi

    if [[ -n "$env" ]]; then
        args+=("-e" "$env")
    fi

    if [[ -n "$guest" ]]; then
        args+=("-g" "$guest")
    fi

    if [[ -n "$format" ]]; then
        args+=("-f" "$format")
    fi

    # 执行
    if [[ -n "$output" ]]; then
        "$radp_vf" "${args[@]}" > "$output"
        radp_log_info "Config dumped to: $output"
    else
        "$radp_vf" "${args[@]}"
    fi
}
