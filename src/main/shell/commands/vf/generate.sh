# @cmd
# @desc Generate standalone Vagrantfile
# @option -e, --env <name> Environment name
# @option -o, --output <file> Output file (default: Vagrantfile.generated)
# @option --dry-run Preview without saving
# @example vf generate
# @example vf generate -o Vagrantfile
# @example vf generate --dry-run

cmd_vf_generate() {
    local env="${opt_env:-}"
    local output="${opt_output:-Vagrantfile.generated}"
    local dry_run="${opt_dry_run:-false}"

    # 检查 radp-vf 是否可用
    if ! command -v radp-vf &>/dev/null; then
        radp_log_error "radp-vf not found in PATH"
        radp_log_error "Please ensure radp-vagrant-framework is installed"
        return 1
    fi

    # 构建命令参数
    local -a args=("generate")

    if [[ -n "$env" ]]; then
        args+=("-e" "$env")
    fi

    # 执行
    if [[ "$dry_run" == "true" ]]; then
        radp_log_info "Dry run - preview Vagrantfile:"
        echo "---"
        radp-vf "${args[@]}"
        echo "---"
    else
        radp-vf "${args[@]}" > "$output"
        radp_log_info "Vagrantfile generated: $output"
    fi
}
