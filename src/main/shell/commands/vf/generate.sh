# @cmd
# @desc Generate standalone Vagrantfile
# @option -e, --env <name> Environment name
# @option -o, --output <file> Output file (default: Vagrantfile.generated)
# @option -d, --dry-run Preview without saving
# @example vf generate
# @example vf generate -o Vagrantfile
# @example vf generate --dry-run

cmd_vf_generate() {
    local env="${opt_env:-}"
    local output="${opt_output:-Vagrantfile.generated}"
    local dry_run="${opt_dry_run:-false}"

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
    local -a args=("generate")

    # 设置配置目录
    if [[ -d "./config" ]]; then
        args+=("-c" "./config")
    fi

    if [[ -n "$env" ]]; then
        args+=("-e" "$env")
    fi

    # 执行
    if [[ "$dry_run" == "true" ]]; then
        radp_log_info "Dry run - preview Vagrantfile:"
        echo "---"
        "$radp_vf" "${args[@]}"
        echo "---"
    else
        "$radp_vf" "${args[@]}" -o "$output"
        radp_log_info "Vagrantfile generated: $output"
    fi
}
