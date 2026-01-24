# @cmd
# @desc Export merged configuration
# @option -e, --env <name> Environment name
# @option -g, --guest <id> Filter by guest ID
# @option -o, --output <file> Output file (default: stdout)
# @example vf dump-config
# @example vf dump-config -e prod
# @example vf dump-config -g node-1

cmd_vf_dump_config() {
    local env="${opt_env:-}"
    local guest="${opt_guest:-}"
    local output="${opt_output:-}"

    # 检查 radp-vf 是否可用
    if ! command -v radp-vf &>/dev/null; then
        radp_log_error "radp-vf not found in PATH"
        radp_log_error "Please ensure radp-vagrant-framework is installed"
        return 1
    fi

    # 构建命令参数
    local -a args=("dump-config")

    if [[ -n "$env" ]]; then
        args+=("-e" "$env")
    fi

    if [[ -n "$guest" ]]; then
        args+=("-g" "$guest")
    fi

    # 执行
    if [[ -n "$output" ]]; then
        radp-vf "${args[@]}" > "$output"
        radp_log_info "Config dumped to: $output"
    else
        radp-vf "${args[@]}"
    fi
}
