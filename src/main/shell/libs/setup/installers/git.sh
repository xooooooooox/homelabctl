#!/usr/bin/env bash
# git installer

_setup_install_git() {
  local version="${1:-latest}"

  if _setup_is_installed git && [[ "$version" == "latest" ]]; then
    radp_log_info "git is already installed"
    return 0
  fi

  local pm
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

  case "$pm" in
  brew)
    radp_log_info "Installing git via Homebrew..."
    brew install git || return 1
    ;;
  dnf | yum)
    radp_log_info "Installing git via dnf..."
    radp_os_install_pkgs git || return 1
    ;;
  apt | apt-get)
    radp_log_info "Installing git via apt..."
    radp_os_install_pkgs git || return 1
    ;;
  pacman)
    radp_log_info "Installing git via pacman..."
    radp_os_install_pkgs git || return 1
    ;;
  *)
    _setup_git_from_source "$version"
    ;;
  esac
}

_setup_git_from_source() {
  local version="$1"
  [[ "$version" == "latest" ]] && version="2.47.1"

  radp_log_info "Installing git build dependencies..."
  local pm
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")
  case "$pm" in
  dnf | yum)
    radp_os_install_pkgs dh-autoreconf curl-devel expat-devel gettext-devel openssl-devel perl-devel zlib-devel || return 1
    ;;
  apt | apt-get)
    radp_os_install_pkgs dh-autoreconf libcurl4-gnutls-dev libexpat1-dev gettext libz-dev libssl-dev || return 1
    ;;
  *)
    radp_log_error "Cannot install git build deps on this platform"
    return 1
    ;;
  esac

  local tmpdir
  tmpdir=$(_setup_mktemp_dir)
  trap 'rm -rf "$tmpdir"; trap - RETURN' RETURN

  local filename="git-${version}.tar.gz"
  local url="https://mirrors.edge.kernel.org/pub/software/scm/git/${filename}"

  radp_log_info "Downloading git $version..."
  radp_io_download "$url" "$tmpdir/$filename" || return 1

  _setup_extract_archive "$tmpdir/$filename" "$tmpdir" || return 1

  (
    cd "$tmpdir/git-${version}" || return 1
    ./configure || return 1
    make || return 1
    $gr_sudo make install || return 1
  ) || return 1
}
