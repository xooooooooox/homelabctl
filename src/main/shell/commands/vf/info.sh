#!/usr/bin/env bash
# @cmd
# @desc Show current environment information
# @option -e, --env <name> Environment name
# @option -j, --json Output as JSON
# @example vf info
# @example vf info -e prod
# @example vf info --json

cmd_vf_info() {
    local env="${opt_env:-}"
    local json="${opt_json:-false}"

    # 检测配置目录
    local config_dir=""
    if [[ -n "${RADP_VAGRANT_CONFIG_DIR:-}" ]]; then
        config_dir="$RADP_VAGRANT_CONFIG_DIR"
    elif [[ -d "./config" ]]; then
        config_dir="./config"
    fi

    # 检测环境
    if [[ -z "$env" ]]; then
        if [[ -n "${RADP_VAGRANT_ENV:-}" ]]; then
            env="$RADP_VAGRANT_ENV"
        elif [[ -n "$config_dir" && -f "$config_dir/vagrant.yaml" ]]; then
            # 从 vagrant.yaml 读取 radp.env
            env=$(grep -E '^\s*env:' "$config_dir/vagrant.yaml" 2>/dev/null | head -1 | awk '{print $2}' || echo "")
        fi
    fi

    # 检测 vagrant
    local vagrant_version=""
    if command -v vagrant &>/dev/null; then
        vagrant_version=$(vagrant --version 2>/dev/null || echo "unknown")
    fi

    # 检测 radp-vf 版本
    local radp_vf_version=""
    if [[ -n "${RADP_VF_HOME:-}" && -x "${RADP_VF_HOME}/bin/radp-vf" ]]; then
        radp_vf_version=$("${RADP_VF_HOME}/bin/radp-vf" version 2>/dev/null || echo "unknown")
    elif command -v radp-vf &>/dev/null; then
        radp_vf_version=$(radp-vf version 2>/dev/null || echo "unknown")
    fi

    # Get accurate version (reads .install-version for manual installs)
    local homelabctl_version
    homelabctl_version=$(radp_get_install_version "${gr_radp_extend_homelabctl_version:-v0.1.0}")

    if [[ "$json" == "true" ]]; then
        cat << JSON
{
  "homelabctl_version": "${homelabctl_version}",
  "radp_vf_home": "${RADP_VF_HOME:-}",
  "radp_vf_version": "${radp_vf_version:-}",
  "config_dir": "$config_dir",
  "environment": "$env",
  "vagrant_version": "$vagrant_version"
}
JSON
    else
        echo "homelabctl Environment Info"
        echo "============================"
        echo ""
        printf "%-20s %s\n" "homelabctl:" "${homelabctl_version}"
        printf "%-20s %s\n" "RADP_VF_HOME:" "${RADP_VF_HOME:-<not set>}"
        printf "%-20s %s\n" "radp-vf:" "${radp_vf_version:-<not found>}"
        printf "%-20s %s\n" "Config directory:" "${config_dir:-<not found>}"
        printf "%-20s %s\n" "Environment:" "${env:-<not set>}"
        printf "%-20s %s\n" "Vagrant:" "${vagrant_version:-<not found>}"

        # 显示已安装的 vagrant 插件
        if command -v vagrant &>/dev/null; then
            echo ""
            echo "Installed Vagrant Plugins:"
            vagrant plugin list 2>/dev/null | sed 's/^/  /'
        fi
    fi
}
