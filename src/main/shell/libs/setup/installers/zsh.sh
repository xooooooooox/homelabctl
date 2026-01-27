#!/usr/bin/env bash
# zsh installer

_setup_install_zsh() {
  local version="${1:-latest}"

  if _setup_is_installed zsh && [[ "$version" == "latest" ]]; then
    radp_log_info "zsh is already installed"
    return 0
  fi

  local pm
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

  case "$pm" in
  brew)
    radp_log_info "Installing zsh via Homebrew..."
    brew install zsh || return 1
    ;;
  dnf | yum)
    radp_log_info "Installing zsh via dnf..."
    if ! radp_os_install_pkgs zsh 2>/dev/null; then
      _setup_zsh_from_source "$version"
    fi
    ;;
  apt | apt-get)
    radp_log_info "Installing zsh via apt..."
    radp_os_install_pkgs zsh || return 1
    ;;
  pacman)
    radp_log_info "Installing zsh via pacman..."
    radp_os_install_pkgs zsh || return 1
    ;;
  *)
    _setup_zsh_from_source "$version"
    ;;
  esac
}

_setup_zsh_from_source() {
  local version="$1"
  [[ "$version" == "latest" ]] && version="5.9"

  radp_log_info "Installing zsh build dependencies..."
  local pm
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")
  case "$pm" in
  dnf | yum)
    radp_os_install_pkgs gcc wget tar ncurses-devel || return 1
    ;;
  apt | apt-get)
    radp_os_install_pkgs gcc wget tar libncurses-dev || return 1
    ;;
  esac

  local tmpdir
  tmpdir=$(_setup_mktemp_dir)
  trap 'rm -rf "$tmpdir"; trap - RETURN' RETURN

  local url="https://sourceforge.net/projects/zsh/files/zsh/${version}/zsh-${version}.tar.xz/download"

  radp_log_info "Downloading zsh $version..."
  radp_io_download "$url" "$tmpdir/zsh-${version}.tar.xz" || return 1

  _setup_extract_archive "$tmpdir/zsh-${version}.tar.xz" "$tmpdir" || return 1

  (
    cd "$tmpdir/zsh-${version}" || return 1
    ./configure || ./configure --with-tcsetpgrp || ./configure --without-tcsetpgrp || return 1
    make || return 1
    $gr_sudo make install || return 1
  ) || return 1
}
