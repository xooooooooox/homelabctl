#!/usr/bin/env bash
# ansible installer

_setup_install_ansible() {
  local version="${1:-latest}"

  if _setup_is_installed ansible && [[ "$version" == "latest" ]]; then
    radp_log_info "ansible is already installed"
    return 0
  fi

  local pm
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

  case "$pm" in
  brew)
    radp_log_info "Installing ansible via Homebrew..."
    brew install ansible || return 1
    ;;
  dnf | yum)
    radp_log_info "Installing ansible via dnf..."
    radp_os_install_pkgs ansible-core || return 1
    ;;
  apt | apt-get)
    radp_log_info "Installing ansible via apt..."
    radp_os_install_pkgs ansible || return 1
    ;;
  pacman)
    radp_log_info "Installing ansible via pacman..."
    radp_os_install_pkgs ansible || return 1
    ;;
  *)
    _setup_ansible_via_pip
    ;;
  esac
}

_setup_ansible_via_pip() {
  if ! _setup_is_installed pip3 && ! _setup_is_installed pip; then
    radp_log_error "pip is required to install ansible. Install python first."
    return 1
  fi

  local pip_cmd="pip3"
  _setup_is_installed pip3 || pip_cmd="pip"

  radp_log_info "Installing ansible via pip..."
  $pip_cmd install --user ansible || return 1
}
