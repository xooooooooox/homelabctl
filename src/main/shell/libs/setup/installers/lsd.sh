#!/usr/bin/env bash
# lsd installer

_setup_install_lsd() {
  local version="${1:-latest}"

  if _setup_is_installed lsd && [[ "$version" == "latest" ]]; then
    radp_log_info "lsd is already installed"
    return 0
  fi

  local pm
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

  case "$pm" in
  brew)
    radp_log_info "Installing lsd via Homebrew..."
    brew install lsd || return 1
    ;;
  pacman)
    radp_log_info "Installing lsd via pacman..."
    radp_os_install_pkgs lsd || return 1
    ;;
  *)
    _setup_lsd_from_release "$version"
    ;;
  esac
}

_setup_lsd_from_release() {
  local version="$1"

  if [[ "$version" == "latest" ]]; then
    version=$(_setup_github_latest_version "lsd-rs/lsd")
    [[ -z "$version" ]] && version="1.1.5"
  fi

  local arch os
  arch=$(_setup_get_arch)
  os=$(_setup_get_os)

  local target
  case "$os" in
  darwin)
    target="lsd-v${version}-x86_64-apple-darwin"
    [[ "$arch" == "arm64" ]] && target="lsd-v${version}-aarch64-apple-darwin"
    ;;
  linux)
    target="lsd-v${version}-x86_64-unknown-linux-musl"
    [[ "$arch" == "arm64" ]] && target="lsd-v${version}-aarch64-unknown-linux-musl"
    ;;
  *)
    radp_log_error "Unsupported OS: $os"
    return 1
    ;;
  esac

  local filename="${target}.tar.gz"
  local url="https://github.com/lsd-rs/lsd/releases/download/v${version}/${filename}"

  local tmpdir
  tmpdir=$(_setup_mktemp_dir)
  trap 'rm -rf "$tmpdir"; trap - RETURN' RETURN

  radp_log_info "Downloading lsd $version..."
  radp_io_download "$url" "$tmpdir/$filename" || return 1

  _setup_extract_archive "$tmpdir/$filename" "$tmpdir" || return 1
  _setup_install_binary "$tmpdir/$target/lsd" || return 1
}
