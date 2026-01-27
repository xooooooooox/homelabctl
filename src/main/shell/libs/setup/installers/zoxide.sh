#!/usr/bin/env bash
# zoxide installer

_setup_install_zoxide() {
  local version="${1:-latest}"

  if _setup_is_installed zoxide && [[ "$version" == "latest" ]]; then
    radp_log_info "zoxide is already installed"
    return 0
  fi

  local pm
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

  case "$pm" in
  brew)
    radp_log_info "Installing zoxide via Homebrew..."
    brew install zoxide || return 1
    ;;
  dnf | yum)
    radp_log_info "Installing zoxide via dnf..."
    if ! radp_os_install_pkgs zoxide 2>/dev/null; then
      radp_log_info "zoxide not available in repos, falling back to install script..."
      _setup_zoxide_from_script
    fi
    ;;
  apt | apt-get)
    radp_log_info "Installing zoxide via apt..."
    if ! radp_os_install_pkgs zoxide 2>/dev/null; then
      radp_log_info "zoxide not available in repos, falling back to install script..."
      _setup_zoxide_from_script
    fi
    ;;
  pacman)
    radp_log_info "Installing zoxide via pacman..."
    radp_os_install_pkgs zoxide || return 1
    ;;
  *)
    _setup_zoxide_from_script
    ;;
  esac
}

_setup_zoxide_from_script() {
  local tmpdir
  tmpdir=$(_setup_mktemp_dir)
  trap 'rm -rf "$tmpdir"; trap - RETURN' RETURN

  radp_log_info "Installing zoxide via official install script..."
  radp_io_download "https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh" "$tmpdir/install.sh" || return 1
  bash "$tmpdir/install.sh" || return 1
}
