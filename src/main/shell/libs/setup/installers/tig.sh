#!/usr/bin/env bash
# tig installer

_setup_install_tig() {
  local version="${1:-latest}"

  if _setup_is_installed tig && [[ "$version" == "latest" ]]; then
    radp_log_info "tig is already installed"
    return 0
  fi

  local pm
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

  case "$pm" in
  brew)
    radp_log_info "Installing tig via Homebrew..."
    brew install tig || return 1
    ;;
  dnf | yum)
    radp_log_info "Installing tig via dnf..."
    if ! radp_os_install_pkgs tig 2>/dev/null; then
      radp_log_info "tig not available in repos, falling back to source build..."
      _setup_tig_from_source "$version"
    fi
    ;;
  apt | apt-get)
    radp_log_info "Installing tig via apt..."
    radp_os_install_pkgs tig || return 1
    ;;
  pacman)
    radp_log_info "Installing tig via pacman..."
    radp_os_install_pkgs tig || return 1
    ;;
  *)
    _setup_tig_from_source "$version"
    ;;
  esac
}

_setup_tig_from_source() {
  local version="$1"

  if [[ "$version" == "latest" ]]; then
    # tig tags are "tig-X.Y.Z", strip the "tig-" prefix
    version=$(radp_net_github_latest_release "jonas/tig" 2>/dev/null)
    version="${version#tig-}"
    [[ -z "$version" ]] && version="2.6.0"
  fi

  radp_log_info "Installing tig build dependencies..."
  local pm
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")
  case "$pm" in
  dnf | yum)
    radp_os_install_pkgs gcc make ncurses-devel || return 1
    ;;
  apt | apt-get)
    radp_os_install_pkgs gcc make libncurses-dev || return 1
    ;;
  esac

  local tmpdir
  tmpdir=$(_setup_mktemp_dir)
  trap 'rm -rf "$tmpdir"; trap - RETURN' RETURN

  local filename="tig-${version}.tar.gz"
  local url="https://github.com/jonas/tig/releases/download/tig-${version}/${filename}"

  radp_log_info "Downloading tig $version..."
  radp_io_download "$url" "$tmpdir/$filename" || return 1

  _setup_extract_archive "$tmpdir/$filename" "$tmpdir" || return 1

  (
    cd "$tmpdir/tig-${version}" || return 1
    make prefix=/usr/local || return 1
    $gr_sudo make install prefix=/usr/local || return 1
  ) || return 1
}
