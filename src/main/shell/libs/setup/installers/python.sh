#!/usr/bin/env bash
# python installer

_setup_install_python() {
  local version="${1:-latest}"

  if _setup_is_installed python3 && [[ "$version" == "latest" ]]; then
    radp_log_info "python is already installed"
    return 0
  fi

  local pm
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

  # Prefer vfox for version management
  if _setup_is_installed vfox; then
    _setup_python_via_vfox "$version"
    return $?
  fi

  case "$pm" in
  brew)
    radp_log_info "Installing python via Homebrew..."
    if [[ "$version" == "latest" ]]; then
      brew install python || return 1
    else
      brew install "python@${version}" || return 1
    fi
    ;;
  dnf | yum)
    radp_log_info "Installing python via dnf..."
    radp_os_install_pkgs python3 python3-pip || return 1
    ;;
  apt | apt-get)
    radp_log_info "Installing python via apt..."
    radp_os_install_pkgs python3 python3-pip python3-venv || return 1
    ;;
  pacman)
    radp_log_info "Installing python via pacman..."
    radp_os_install_pkgs python python-pip || return 1
    ;;
  *)
    radp_log_error "Cannot install python: unsupported package manager and vfox not available"
    return 1
    ;;
  esac
}

_setup_python_via_vfox() {
  local version="$1"

  radp_log_info "Installing python via vfox..."

  if ! vfox list python &>/dev/null; then
    vfox add python || return 1
  fi

  if [[ "$version" == "latest" ]]; then
    version=$(vfox search python 2>/dev/null | head -1 | awk '{print $1}')
    [[ -z "$version" ]] && version="3.12"
  fi

  vfox install "python@$version" || return 1
  vfox use --global "python@$version" 2>/dev/null || true
  _setup_vfox_add_sdk_to_path "python" "python3"
  _setup_vfox_refresh_path

  # Verify python3 is available, if not, explicitly find and add to PATH
  if ! _common_is_command_available python3; then
    local python_bin_dir
    python_bin_dir=$(_setup_vfox_find_sdk_bin "python" "python3")
    if [[ -n "$python_bin_dir" ]]; then
      export PATH="$python_bin_dir:$PATH"
      hash -r 2>/dev/null || true
    fi
  fi
}
