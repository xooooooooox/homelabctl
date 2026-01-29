#!/usr/bin/env bash
# @cmd
# @desc Run vagrant commands (passthrough to vagrant)
# @meta passthrough
# @example vg status
# @example vg up
# @example vg ssh node-1
# @example vg provision myvm --provision-with shell
# @example vg --help
# @example RADP_VAGRANT_ENV=prod vg up

# All arguments are passed through to vagrant
cmd_vg() {
  if [[ $# -eq 0 ]]; then
    radp_cli_help_command "vg"
    return 1
  fi

  # 检查 vagrant 是否可用
  if ! command -v vagrant &>/dev/null; then
    radp_log_error "vagrant not found in PATH"
    return 1
  fi

  # 设置配置目录（默认使用当前目录下的 config）
  if [[ -z "${RADP_VAGRANT_CONFIG_DIR:-}" && -d "./config" ]]; then
    export RADP_VAGRANT_CONFIG_DIR="./config"
  fi

  # 自动检测 RADP_VF_HOME（如果未设置）
  # Auto-detect RADP_VF_HOME if not set
  local radp_vf_home="${RADP_VF_HOME:-}"

  if [[ -z "$radp_vf_home" ]]; then
    # 方法1: 通过 radp-vf 命令位置检测
    # Method 1: Detect from radp-vf command location
    if command -v radp-vf &>/dev/null; then
      local radp_vf_path
      radp_vf_path=$(command -v radp-vf)
      # 解析符号链接
      # Resolve symlinks
      while [[ -L "$radp_vf_path" ]]; do
        local link_target
        link_target=$(readlink "$radp_vf_path")
        if [[ "$link_target" != /* ]]; then
          link_target="$(dirname "$radp_vf_path")/$link_target"
        fi
        radp_vf_path="$link_target"
      done
      local bin_dir
      bin_dir=$(cd "$(dirname "$radp_vf_path")" && pwd)

      # 检测安装模式: Development (bin/radp-vf) 或 Homebrew (libexec/bin/radp-vf)
      # Detect install mode: Development (bin/radp-vf) or Homebrew (libexec/bin/radp-vf)
      if [[ -d "${bin_dir}/../src/main/ruby/lib/radp_vagrant" ]]; then
        # Development mode
        radp_vf_home="$(cd "${bin_dir}/.." && pwd)"
      elif [[ -d "${bin_dir}/../lib/radp_vagrant" ]]; then
        # Homebrew/installed mode (libexec/bin -> libexec)
        radp_vf_home="$(cd "${bin_dir}/.." && pwd)"
      fi
    fi

    # 方法2: 检查常见安装位置
    # Method 2: Check common installation locations
    if [[ -z "$radp_vf_home" ]]; then
      local common_paths=(
        "$HOME/.local/lib/radp-vagrant-framework"
        "/opt/homebrew/opt/radp-vagrant-framework/libexec"
        "/usr/local/opt/radp-vagrant-framework/libexec"
      )
      for path in "${common_paths[@]}"; do
        if [[ -f "$path/Vagrantfile" ]] || [[ -f "$path/src/main/ruby/Vagrantfile" ]]; then
          radp_vf_home="$path"
          break
        fi
      done
    fi

    if [[ -z "$radp_vf_home" ]]; then
      radp_log_error "Cannot locate radp-vagrant-framework. Set RADP_VF_HOME or install radp-vagrant-framework."
      return 1
    fi

    export RADP_VF_HOME="$radp_vf_home"
  fi

  # 设置 Vagrantfile 路径
  # Set Vagrantfile path
  # 支持两种安装模式:
  # 1. Development: ${RADP_VF_HOME}/src/main/ruby/Vagrantfile
  # 2. Homebrew: ${RADP_VF_HOME}/Vagrantfile
  if [[ -f "${radp_vf_home}/src/main/ruby/Vagrantfile" ]]; then
    export VAGRANT_VAGRANTFILE="${radp_vf_home}/src/main/ruby/Vagrantfile"
  elif [[ -f "${radp_vf_home}/Vagrantfile" ]]; then
    export VAGRANT_VAGRANTFILE="${radp_vf_home}/Vagrantfile"
  else
    radp_log_error "Vagrantfile not found in RADP_VF_HOME: $radp_vf_home"
    return 1
  fi

  # 执行 vagrant 命令（所有参数直接传递）
  radp_log_info "Running: vagrant $*"
  exec vagrant "$@"
}
