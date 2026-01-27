#!/usr/bin/env bash
# homebrew installer

_setup_install_homebrew() {
  local version="${1:-latest}"

  if _setup_is_installed brew && [[ "$version" == "latest" ]]; then
    radp_log_info "homebrew is already installed"
    return 0
  fi

  local os
  os=$(_setup_get_os)

  case "$os" in
  darwin)
    radp_log_info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || return 1
    ;;
  linux)
    radp_log_info "Homebrew is not needed on Linux (native package managers are used)"
    return 0
    ;;
  *)
    radp_log_error "Unsupported OS: $os"
    return 1
    ;;
  esac
}
