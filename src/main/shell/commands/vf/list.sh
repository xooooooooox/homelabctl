#!/usr/bin/env bash
# @cmd
# @desc List clusters and guests from configuration
# @option -e, --env <name> Override environment name
# @option -v, --verbose Show detailed info (box, network, provisions, etc.)
# @option --provisions Show provisions only
# @option --synced-folders Show synced folders only
# @option --triggers Show triggers only
# @arg filter Filter by guest ID or machine name
# @example vf list
# @example vf list -e prod
# @example vf list -v
# @example vf list -v node-1
# @example vf list --provisions
# @example vf list --synced-folders node-1

cmd_vf_list() {
    local env="${opt_env:-}"
    local verbose="${opt_verbose:-}"
    local provisions="${opt_provisions:-}"
    local synced_folders="${opt_synced_folders:-}"
    local triggers="${opt_triggers:-}"
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

    # 构建全局参数
    local global_args=()

    # 设置配置目录
    if [[ -d "./config" && -z "${RADP_VAGRANT_CONFIG_DIR:-}" ]]; then
        global_args+=("-c" "$(pwd)/config")
    fi

    # 设置环境覆盖
    if [[ -n "$env" ]]; then
        global_args+=("-e" "$env")
    fi

    # 构建 list 命令参数
    local list_args=("list")

    # 详细模式
    if [[ -n "$verbose" ]]; then
        list_args+=("-v")
    fi

    # 显示 provisions
    if [[ -n "$provisions" ]]; then
        list_args+=("--provisions")
    fi

    # 显示 synced folders
    if [[ -n "$synced_folders" ]]; then
        list_args+=("--synced-folders")
    fi

    # 显示 triggers
    if [[ -n "$triggers" ]]; then
        list_args+=("--triggers")
    fi

    # 过滤参数
    if [[ -n "$filter" ]]; then
        list_args+=("$filter")
    fi

    # 执行 radp-vf
    "$radp_vf" "${global_args[@]}" "${list_args[@]}"
}
