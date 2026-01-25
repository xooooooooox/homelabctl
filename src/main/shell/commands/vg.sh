# @cmd
# @desc Run vagrant commands (passthrough to vagrant)
# @arg cmd! Vagrant command (up, halt, ssh, destroy, status, etc.)
# @arg args~ Additional arguments passed to vagrant
# @option -e, --env <name> Environment name
# @option -c, --config <dir> Config directory path
# @example vg up
# @example vg ssh node-1
# @example vg -e prod up
# @example vg status

cmd_vg() {
    local cmd="${1:-}"
    shift || true

    if [[ -z "$cmd" ]]; then
        radp_log_error "Vagrant command required"
        echo "Usage: homelabctl vg <command> [args...]"
        echo "Example: homelabctl vg up"
        return 1
    fi

    # 检查 vagrant 是否可用
    if ! command -v vagrant &>/dev/null; then
        radp_log_error "vagrant not found in PATH"
        return 1
    fi

    # 设置环境变量
    if [[ -n "${opt_env:-}" ]]; then
        export RADP_VAGRANT_ENV="$opt_env"
    fi

    # 设置配置目录
    local config_dir="${opt_config:-}"
    if [[ -z "$config_dir" ]]; then
        # 默认使用当前目录下的 config
        if [[ -d "./config" ]]; then
            config_dir="./config"
        fi
    fi

    if [[ -n "$config_dir" ]]; then
        export RADP_VAGRANT_CONFIG_DIR="$config_dir"
    fi

    # 设置 Vagrantfile 路径（如果 RADP_VF_HOME 可用）
    # 支持两种安装模式:
    # 1. Development: ${RADP_VF_HOME}/src/main/ruby/Vagrantfile
    # 2. Homebrew: ${RADP_VF_HOME}/Vagrantfile
    if [[ -n "${RADP_VF_HOME:-}" ]]; then
        if [[ -f "${RADP_VF_HOME}/src/main/ruby/Vagrantfile" ]]; then
            export VAGRANT_VAGRANTFILE="${RADP_VF_HOME}/src/main/ruby/Vagrantfile"
        elif [[ -f "${RADP_VF_HOME}/Vagrantfile" ]]; then
            export VAGRANT_VAGRANTFILE="${RADP_VF_HOME}/Vagrantfile"
        fi
    fi

    # 执行 vagrant 命令
    radp_log_info "Running: vagrant $cmd $*"
    exec vagrant "$cmd" "$@"
}
