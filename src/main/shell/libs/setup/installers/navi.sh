#!/usr/bin/env bash
# navi installer

_setup_install_navi() {
  local version="${1:-latest}"

  if _setup_is_installed navi && [[ "$version" == "latest" ]]; then
    radp_log_info "navi is already installed"
    return 0
  fi

  local pm
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

  case "$pm" in
  brew)
    radp_log_info "Installing navi via Homebrew..."
    brew install navi || return 1
    ;;
  pacman)
    radp_log_info "Installing navi via pacman..."
    radp_os_install_pkgs navi || return 1
    ;;
  *)
    _setup_navi_from_release "$version"
    ;;
  esac
}

_setup_navi_from_release() {
  local version="$1"

  if [[ "$version" == "latest" ]]; then
    version=$(_setup_github_latest_version "denisidoro/navi")
    [[ -z "$version" ]] && version="2.24.0"
  fi

  local arch os
  arch=$(_setup_get_arch)
  os=$(_setup_get_os)

  # Map to Rust target triples
  local target
  case "${os}_${arch}" in
  darwin_amd64) target="x86_64-apple-darwin" ;;
  darwin_arm64) target="aarch64-apple-darwin" ;;
  linux_amd64) target="x86_64-unknown-linux-musl" ;;
  linux_arm64) target="aarch64-unknown-linux-gnu" ;;
  *)
    radp_log_error "Unsupported platform: ${os}/${arch}"
    return 1
    ;;
  esac

  local filename="navi-v${version}-${target}.tar.gz"
  local url="https://github.com/denisidoro/navi/releases/download/v${version}/${filename}"

  local tmpdir
  tmpdir=$(_setup_mktemp_dir)
  trap 'rm -rf "$tmpdir"; trap - RETURN' RETURN

  radp_log_info "Downloading navi $version..."
  radp_io_download "$url" "$tmpdir/$filename" || return 1

  _setup_extract_archive "$tmpdir/$filename" "$tmpdir" || return 1
  _setup_install_binary "$tmpdir/navi" || return 1
}
