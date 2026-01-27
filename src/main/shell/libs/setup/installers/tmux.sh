#!/usr/bin/env bash
# tmux installer

_setup_install_tmux() {
  local version="${1:-latest}"

  if _setup_is_installed tmux && [[ "$version" == "latest" ]]; then
    radp_log_info "tmux is already installed"
    return 0
  fi

  local pm
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

  case "$pm" in
  brew)
    radp_log_info "Installing tmux via Homebrew..."
    brew install tmux || return 1
    ;;
  dnf | yum)
    radp_log_info "Installing tmux via dnf..."
    radp_os_install_pkgs tmux || return 1
    ;;
  apt | apt-get)
    radp_log_info "Installing tmux via apt..."
    radp_os_install_pkgs tmux || return 1
    ;;
  pacman)
    radp_log_info "Installing tmux via pacman..."
    radp_os_install_pkgs tmux || return 1
    ;;
  *)
    _setup_tmux_from_source "$version"
    ;;
  esac
}

_setup_tmux_from_source() {
  local version="$1"

  if [[ "$version" == "latest" ]]; then
    version=$(_setup_github_latest_version "tmux/tmux")
    [[ -z "$version" ]] && version="3.5a"
  fi

  radp_log_info "Installing tmux build dependencies..."
  local pm
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")
  case "$pm" in
  apt | apt-get)
    radp_os_install_pkgs libevent-dev ncurses-dev build-essential bison pkg-config || return 1
    ;;
  dnf | yum)
    radp_os_install_pkgs libevent-devel ncurses-devel gcc make bison pkg-config || return 1
    ;;
  *)
    radp_log_error "Cannot install tmux build deps on this platform"
    return 1
    ;;
  esac

  local tmpdir
  tmpdir=$(_setup_mktemp_dir)
  trap 'rm -rf "$tmpdir"; trap - RETURN' RETURN

  local url="https://github.com/tmux/tmux/releases/download/${version}/tmux-${version}.tar.gz"
  local filename="tmux-${version}.tar.gz"

  radp_log_info "Downloading tmux $version..."
  radp_io_download "$url" "$tmpdir/$filename" || return 1

  _setup_extract_archive "$tmpdir/$filename" "$tmpdir" || return 1

  (
    cd "$tmpdir/tmux-${version}" || return 1
    ./configure || return 1
    make || return 1
    $gr_sudo make install || return 1
  ) || return 1
}
