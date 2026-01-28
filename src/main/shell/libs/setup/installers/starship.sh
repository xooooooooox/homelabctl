#!/usr/bin/env bash
# starship installer

_setup_install_starship() {
  local version="${1:-latest}"

  if _setup_is_installed starship && [[ "$version" == "latest" ]]; then
    radp_log_info "starship is already installed"
    return 0
  fi

  local pm
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

  case "$pm" in
  brew)
    radp_log_info "Installing starship via Homebrew..."
    brew install starship || return 1
    ;;
  dnf | yum)
    _setup_starship_from_installer "$version"
    ;;
  apt | apt-get)
    _setup_starship_from_installer "$version"
    ;;
  pacman)
    radp_log_info "Installing starship via pacman..."
    radp_os_install_pkgs starship || return 1
    ;;
  *)
    _setup_starship_from_installer "$version"
    ;;
  esac
}

_setup_starship_from_installer() {
  local version="$1"

  radp_log_info "Installing starship via official installer..."

  local tmpdir
  tmpdir=$(_setup_mktemp_dir)
  trap 'rm -rf "$tmpdir"; trap - RETURN' RETURN

  radp_io_download "https://starship.rs/install.sh" "$tmpdir/install.sh" || return 1

  local install_args=("-y" "-b" "/usr/local/bin")
  if [[ "$version" != "latest" ]]; then
    install_args+=("-v" "v${version}")
  fi

  $gr_sudo bash "$tmpdir/install.sh" "${install_args[@]}" || return 1
}
