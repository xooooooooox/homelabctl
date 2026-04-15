#!/usr/bin/env bash
# yazi installer

_setup_install_yazi() {
  local version="${1:-latest}"

  if _setup_is_installed yazi && [[ "$version" == "latest" ]]; then
    radp_log_info "yazi is already installed"
    return 0
  fi

  local pm
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

  case "$pm" in
  brew)
    radp_log_info "Installing yazi via Homebrew..."
    brew install yazi || return 1
    ;;
  pacman)
    radp_log_info "Installing yazi via pacman..."
    radp_os_install_pkgs yazi || return 1
    ;;
  *)
    _setup_yazi_from_release "$version"
    ;;
  esac
}

_setup_yazi_from_release() {
  local version="$1"

  if [[ "$version" == "latest" ]]; then
    version=$(_setup_github_latest_version "sxyazi/yazi")
    [[ -z "$version" ]] && version="0.4.2"
  fi

  local arch os
  arch=$(_setup_get_arch)
  os=$(_setup_get_os)

  # yazi release filenames don't include the version
  local target
  case "$os" in
  darwin)
    target="yazi-x86_64-apple-darwin"
    [[ "$arch" == "arm64" ]] && target="yazi-aarch64-apple-darwin"
    ;;
  linux)
    target="yazi-x86_64-unknown-linux-musl"
    [[ "$arch" == "arm64" ]] && target="yazi-aarch64-unknown-linux-musl"
    ;;
  *)
    radp_log_error "Unsupported OS: $os"
    return 1
    ;;
  esac

  local filename="${target}.zip"
  local url="https://github.com/sxyazi/yazi/releases/download/v${version}/${filename}"

  local tmpdir
  tmpdir=$(_setup_mktemp_dir)
  trap 'rm -rf "$tmpdir"; trap - RETURN' RETURN

  radp_log_info "Downloading yazi $version..."
  radp_io_download "$url" "$tmpdir/$filename" || return 1

  _setup_extract_archive "$tmpdir/$filename" "$tmpdir" || return 1
  _setup_install_binary "$tmpdir/$target/yazi" || return 1
}
