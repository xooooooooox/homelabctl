#!/usr/bin/env bash
# ruby installer

_setup_install_ruby() {
  local version="${1:-latest}"

  if _setup_is_installed ruby && [[ "$version" == "latest" ]]; then
    radp_log_info "ruby is already installed"
    return 0
  fi

  local pm
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

  # Prefer vfox for version management
  if _setup_is_installed vfox; then
    _setup_ruby_via_vfox "$version"
    return $?
  fi

  # Fall back to system package manager
  case "$pm" in
  brew)
    radp_log_info "Installing ruby via Homebrew..."
    if [[ "$version" == "latest" ]]; then
      brew install ruby || return 1
    else
      brew install "ruby@${version}" || return 1
    fi
    ;;
  dnf | yum)
    radp_log_info "Installing ruby via dnf..."
    radp_os_install_pkgs ruby ruby-devel || return 1
    ;;
  apt | apt-get)
    radp_log_info "Installing ruby via apt..."
    radp_os_install_pkgs ruby ruby-dev || return 1
    ;;
  pacman)
    radp_log_info "Installing ruby via pacman..."
    radp_os_install_pkgs ruby || return 1
    ;;
  *)
    radp_log_error "Cannot install ruby: unsupported package manager and vfox not available"
    return 1
    ;;
  esac
}

_setup_ruby_via_vfox() {
  local version="$1"

  radp_log_info "Installing ruby via vfox..."

  # Ensure ruby plugin is added
  if ! vfox list ruby &>/dev/null; then
    vfox add ruby || return 1
  fi

  if [[ "$version" == "latest" ]]; then
    version=$(vfox search ruby 2>/dev/null | head -1 | awk '{print $1}')
    [[ -z "$version" ]] && version="3.3"
  fi

  vfox install "ruby@$version" || return 1
  vfox use --global "ruby@$version" 2>/dev/null || true
  _setup_vfox_refresh_path
}
