# @cmd
# @desc Generate standalone Vagrantfile
# @option -e, --env <name> Override environment name
# @arg output Output file path (default: stdout)
# @example vf generate
# @example vf generate Vagrantfile.standalone
# @example vf generate -e prod Vagrantfile.prod

cmd_vf_generate() {
    local env="${opt_env:-}"
    local output="${1:-}"

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

    # 设置配置目录环境变量
    if [[ -d "./config" && -z "${RADP_VAGRANT_CONFIG_DIR:-}" ]]; then
        export RADP_VAGRANT_CONFIG_DIR="$(pwd)/config"
    fi

    # 设置环境变量覆盖
    if [[ -n "$env" ]]; then
        export RADP_VAGRANT_ENV="$env"
    fi

    # 执行 radp-vf generate [output]
    if [[ -n "$output" ]]; then
        "$radp_vf" generate "$output"
    else
        "$radp_vf" generate
    fi
}
