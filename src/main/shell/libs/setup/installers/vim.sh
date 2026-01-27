#!/usr/bin/env bash
# vim installer

_setup_install_vim() {
  local version="${1:-latest}"

  if _setup_is_installed vim && [[ "$version" == "latest" ]]; then
    radp_log_info "vim is already installed"
    return 0
  fi

  local pm
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

  case "$pm" in
  brew)
    radp_log_info "Installing vim via Homebrew..."
    brew install vim || return 1
    ;;
  dnf | yum)
    radp_log_info "Installing vim via dnf..."
    radp_os_install_pkgs vim-enhanced || return 1
    ;;
  apt | apt-get)
    radp_log_info "Installing vim via apt..."
    radp_os_install_pkgs vim || return 1
    ;;
  pacman)
    radp_log_info "Installing vim via pacman..."
    radp_os_install_pkgs vim || return 1
    ;;
  *)
    radp_log_error "Cannot install vim: unsupported package manager"
    return 1
    ;;
  esac
}
