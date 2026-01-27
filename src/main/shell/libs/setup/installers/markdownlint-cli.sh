#!/usr/bin/env bash
# markdownlint-cli installer

_setup_install_markdownlint_cli() {
  local version="${1:-latest}"

  if _setup_is_installed markdownlint && [[ "$version" == "latest" ]]; then
    radp_log_info "markdownlint-cli is already installed"
    return 0
  fi

  local pm
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

  case "$pm" in
  brew)
    radp_log_info "Installing markdownlint-cli via Homebrew..."
    brew install markdownlint-cli || return 1
    ;;
  *)
    # markdownlint-cli is an npm package
    if ! _setup_is_installed npm; then
      radp_log_error "npm is required to install markdownlint-cli. Install nodejs first."
      return 1
    fi
    radp_log_info "Installing markdownlint-cli via npm..."
    $gr_sudo npm install -g markdownlint-cli || return 1
    ;;
  esac
}
