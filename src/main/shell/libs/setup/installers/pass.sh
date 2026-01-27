#!/usr/bin/env bash
# pass installer (password-store)

_setup_install_pass() {
  local version="${1:-latest}"

  if _setup_is_installed pass && [[ "$version" == "latest" ]]; then
    radp_log_info "pass is already installed"
    return 0
  fi

  local pm
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

  case "$pm" in
  brew)
    radp_log_info "Installing pass via Homebrew..."
    brew install pass || return 1
    ;;
  dnf | yum)
    radp_log_info "Installing pass via dnf..."
    if ! radp_os_install_pkgs pass 2>/dev/null; then
      radp_log_info "pass not available in repos, falling back to source install..."
      _setup_pass_from_source "$version"
    fi
    ;;
  apt | apt-get)
    radp_log_info "Installing pass via apt..."
    radp_os_install_pkgs pass || return 1
    ;;
  pacman)
    radp_log_info "Installing pass via pacman..."
    radp_os_install_pkgs pass || return 1
    ;;
  *)
    _setup_pass_from_source "$version"
    ;;
  esac
}

_setup_pass_from_source() {
  local version="$1"
  [[ "$version" == "latest" ]] && version="1.7.4"

  local tmpdir
  tmpdir=$(_setup_mktemp_dir)
  trap 'rm -rf "$tmpdir"; trap - RETURN' RETURN

  local url="https://git.zx2c4.com/password-store/snapshot/password-store-${version}.tar.xz"

  # Ensure make is available
  if ! _setup_is_installed make; then
    radp_os_install_pkgs make || return 1
  fi

  radp_log_info "Downloading pass $version..."
  radp_io_download "$url" "$tmpdir/password-store-${version}.tar.xz" || return 1

  _setup_extract_archive "$tmpdir/password-store-${version}.tar.xz" "$tmpdir" || return 1

  (
    cd "$tmpdir/password-store-${version}" || return 1
    $gr_sudo make install || return 1
  ) || return 1
}
