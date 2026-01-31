#!/usr/bin/env bash
# @cmd
# @desc Show homelabctl environment information
# @option -j, --json Output as JSON
# @example info
# @example info --json

cmd_info() {
    local json="${opt_json:-false}"

    # Detect config directory
    local config_dir=""
    if [[ -n "${RADP_VAGRANT_CONFIG_DIR:-}" ]]; then
        config_dir="$RADP_VAGRANT_CONFIG_DIR"
    elif [[ -d "./config" ]]; then
        config_dir="./config"
    fi

    # Detect environment from config file
    local env=""
    if [[ -n "${RADP_VAGRANT_ENV:-}" ]]; then
        env="$RADP_VAGRANT_ENV"
    elif [[ -n "$config_dir" ]]; then
        # Read radp.env from config file (supports vagrant.yaml and config.yaml)
        local config_file=""
        if [[ -n "${RADP_VAGRANT_CONFIG_BASE_FILENAME:-}" && -f "$config_dir/${RADP_VAGRANT_CONFIG_BASE_FILENAME}" ]]; then
            config_file="$config_dir/${RADP_VAGRANT_CONFIG_BASE_FILENAME}"
        elif [[ -f "$config_dir/vagrant.yaml" ]]; then
            config_file="$config_dir/vagrant.yaml"
        elif [[ -f "$config_dir/config.yaml" ]]; then
            config_file="$config_dir/config.yaml"
        fi
        if [[ -n "$config_file" ]]; then
            env=$(grep -E '^\s*env:' "$config_file" 2>/dev/null | head -1 | awk '{print $2}' || echo "")
        fi
    fi

    # Detect vagrant version
    local vagrant_version=""
    if command -v vagrant &>/dev/null; then
        vagrant_version=$(vagrant --version 2>/dev/null || echo "unknown")
    fi

    # Detect radp-vf version
    local radp_vf_version=""
    if [[ -n "${RADP_VF_HOME:-}" && -x "${RADP_VF_HOME}/bin/radp-vf" ]]; then
        radp_vf_version=$("${RADP_VF_HOME}/bin/radp-vf" version 2>/dev/null || echo "unknown")
    elif command -v radp-vf &>/dev/null; then
        radp_vf_version=$(radp-vf version 2>/dev/null || echo "unknown")
    fi

    # Get homelabctl version (reads .install-version for manual installs)
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

        # Show installed vagrant plugins
        if command -v vagrant &>/dev/null; then
            echo ""
            echo "Installed Vagrant Plugins:"
            vagrant plugin list 2>/dev/null | sed 's/^/  /'
        fi
    fi
}
