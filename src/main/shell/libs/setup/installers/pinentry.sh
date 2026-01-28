#!/usr/bin/env bash
# pinentry installer

_setup_install_pinentry() {
  local version="${1:-latest}"

  if _setup_is_installed pinentry && [[ "$version" == "latest" ]]; then
    radp_log_info "pinentry is already installed"
    return 0
  fi

  local pm
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

  case "$pm" in
  brew)
    radp_log_info "Installing pinentry via Homebrew..."
    brew install pinentry || return 1
    # macOS: also install pinentry-mac for native GUI prompt
    if ! _setup_is_installed pinentry-mac; then
      radp_log_info "Installing pinentry-mac for macOS GUI integration..."
      brew install pinentry-mac || return 1
    fi
    ;;
  dnf | yum)
    radp_log_info "Installing pinentry via dnf..."
    radp_os_install_pkgs pinentry || return 1
    ;;
  apt | apt-get)
    radp_log_info "Installing pinentry via apt..."
    radp_os_install_pkgs pinentry-curses || return 1
    ;;
  pacman)
    radp_log_info "Installing pinentry via pacman..."
    radp_os_install_pkgs pinentry || return 1
    ;;
  *)
    radp_log_error "Cannot install pinentry: unsupported package manager"
    return 1
    ;;
  esac
}
