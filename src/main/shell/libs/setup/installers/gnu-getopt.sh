#!/usr/bin/env bash
# gnu-getopt installer

_setup_install_gnu_getopt() {
  local version="${1:-latest}"

  # Check for GNU getopt (not BSD)
  if _setup_is_installed getopt; then
    if getopt --test &>/dev/null; [ $? -eq 4 ]; then
      radp_log_info "GNU getopt is already installed"
      return 0
    fi
  fi

  local pm
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

  case "$pm" in
  brew)
    radp_log_info "Installing gnu-getopt via Homebrew..."
    brew install gnu-getopt || return 1
    radp_log_info "Add to PATH: export PATH=\"\$(brew --prefix gnu-getopt)/bin:\$PATH\""
    ;;
  dnf | yum)
    # GNU getopt is part of util-linux, typically pre-installed
    if ! _setup_is_installed getopt; then
      radp_log_info "Installing util-linux via dnf..."
      radp_os_install_pkgs util-linux || return 1
    else
      radp_log_info "GNU getopt is already available via util-linux"
    fi
    ;;
  apt | apt-get)
    if ! _setup_is_installed getopt; then
      radp_log_info "Installing util-linux via apt..."
      radp_os_install_pkgs util-linux || return 1
    else
      radp_log_info "GNU getopt is already available via util-linux"
    fi
    ;;
  pacman)
    if ! _setup_is_installed getopt; then
      radp_log_info "Installing util-linux via pacman..."
      radp_os_install_pkgs util-linux || return 1
    else
      radp_log_info "GNU getopt is already available via util-linux"
    fi
    ;;
  *)
    radp_log_error "Cannot install gnu-getopt: unsupported package manager"
    return 1
    ;;
  esac
}
