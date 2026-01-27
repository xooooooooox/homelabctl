#!/usr/bin/env bash
# gpg installer

_setup_install_gpg() {
  local version="${1:-latest}"

  if _setup_is_installed gpg && [[ "$version" == "latest" ]]; then
    radp_log_info "gpg is already installed"
    return 0
  fi

  local pm
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

  case "$pm" in
  brew)
    radp_log_info "Installing gpg via Homebrew..."
    brew install gnupg || return 1
    ;;
  dnf | yum)
    radp_log_info "Installing gpg via dnf..."
    radp_os_install_pkgs gnupg2 || return 1
    ;;
  apt | apt-get)
    radp_log_info "Installing gpg via apt..."
    radp_os_install_pkgs gnupg || return 1
    ;;
  pacman)
    radp_log_info "Installing gpg via pacman..."
    radp_os_install_pkgs gnupg || return 1
    ;;
  *)
    radp_log_error "Cannot install gpg: unsupported package manager"
    return 1
    ;;
  esac
}
