#!/usr/bin/env bash
# ripgrep installer

_setup_install_ripgrep() {
  local version="${1:-latest}"

  if _setup_is_installed rg && [[ "$version" == "latest" ]]; then
    radp_log_info "ripgrep is already installed"
    return 0
  fi

  local pm
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

  case "$pm" in
  brew)
    radp_log_info "Installing ripgrep via Homebrew..."
    brew install ripgrep || return 1
    ;;
  dnf | yum)
    radp_log_info "Installing ripgrep via dnf..."
    if ! radp_os_install_pkgs ripgrep 2>/dev/null; then
      radp_log_info "ripgrep not available in repos, falling back to binary release..."
      _setup_ripgrep_from_release "$version"
    fi
    ;;
  apt | apt-get)
    radp_log_info "Installing ripgrep via apt..."
    radp_os_install_pkgs ripgrep || return 1
    ;;
  pacman)
    radp_log_info "Installing ripgrep via pacman..."
    radp_os_install_pkgs ripgrep || return 1
    ;;
  *)
    _setup_ripgrep_from_release "$version"
    ;;
  esac
}

_setup_ripgrep_from_release() {
  local version="$1"

  if [[ "$version" == "latest" ]]; then
    version=$(_setup_github_latest_version "BurntSushi/ripgrep")
    [[ -z "$version" ]] && version="14.1.1"
  fi

  local arch os
  arch=$(_setup_get_arch)
  os=$(_setup_get_os)

  local target
  case "$os" in
  darwin)
    target="ripgrep-${version}-x86_64-apple-darwin"
    [[ "$arch" == "arm64" ]] && target="ripgrep-${version}-aarch64-apple-darwin"
    ;;
  linux)
    target="ripgrep-${version}-x86_64-unknown-linux-musl"
    [[ "$arch" == "arm64" ]] && target="ripgrep-${version}-aarch64-unknown-linux-gnu"
    ;;
  *)
    radp_log_error "Unsupported OS: $os"
    return 1
    ;;
  esac

  local filename="${target}.tar.gz"
  local url="https://github.com/BurntSushi/ripgrep/releases/download/${version}/${filename}"

  local tmpdir
  tmpdir=$(_setup_mktemp_dir)
  trap 'rm -rf "$tmpdir"; trap - RETURN' RETURN

  radp_log_info "Downloading ripgrep $version..."
  radp_io_download "$url" "$tmpdir/$filename" || return 1

  _setup_extract_archive "$tmpdir/$filename" "$tmpdir" || return 1
  _setup_install_binary "$tmpdir/$target/rg" || return 1
}
