#!/usr/bin/env bash
# k9s installer

_setup_install_k9s() {
  local version="${1:-latest}"

  if _setup_is_installed k9s && [[ "$version" == "latest" ]]; then
    radp_log_info "k9s is already installed"
    return 0
  fi

  local pm
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

  case "$pm" in
  brew)
    radp_log_info "Installing k9s via Homebrew..."
    brew install k9s || return 1
    ;;
  pacman)
    radp_log_info "Installing k9s via pacman..."
    radp_os_install_pkgs k9s || return 1
    ;;
  *)
    _setup_k9s_from_release "$version"
    ;;
  esac
}

_setup_k9s_from_release() {
  local version="$1"

  if [[ "$version" == "latest" ]]; then
    version=$(_setup_github_latest_version "derailed/k9s")
    [[ -z "$version" ]] && version="0.50.6"
  fi

  local arch os
  arch=$(_setup_get_arch)
  os=$(_setup_get_os)

  # Map to k9s release naming
  local k9s_os k9s_arch
  case "$os" in
  darwin) k9s_os="Darwin" ;;
  linux) k9s_os="Linux" ;;
  *)
    radp_log_error "Unsupported OS: $os"
    return 1
    ;;
  esac

  case "$arch" in
  amd64) k9s_arch="amd64" ;;
  arm64) k9s_arch="arm64" ;;
  *) k9s_arch="$arch" ;;
  esac

  local filename="k9s_${k9s_os}_${k9s_arch}.tar.gz"
  local url="https://github.com/derailed/k9s/releases/download/v${version}/${filename}"

  local tmpdir
  tmpdir=$(_setup_mktemp_dir)
  trap 'rm -rf "$tmpdir"; trap - RETURN' RETURN

  radp_log_info "Downloading k9s $version..."
  radp_io_download "$url" "$tmpdir/$filename" || return 1

  _setup_extract_archive "$tmpdir/$filename" "$tmpdir" || return 1
  _setup_install_binary "$tmpdir/k9s" || return 1
}
