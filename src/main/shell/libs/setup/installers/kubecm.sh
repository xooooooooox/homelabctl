#!/usr/bin/env bash
# kubecm installer

_setup_install_kubecm() {
  local version="${1:-latest}"

  if _setup_is_installed kubecm && [[ "$version" == "latest" ]]; then
    radp_log_info "kubecm is already installed"
    return 0
  fi

  local pm
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

  case "$pm" in
  brew)
    radp_log_info "Installing kubecm via Homebrew..."
    brew install sunny0826/tap/kubecm || return 1
    ;;
  *)
    _setup_kubecm_from_release "$version"
    ;;
  esac
}

_setup_kubecm_from_release() {
  local version="$1"

  if [[ "$version" == "latest" ]]; then
    version=$(_setup_github_latest_version "sunny0826/kubecm")
    [[ -z "$version" ]] && version="0.31.0"
  fi

  local arch os
  arch=$(_setup_get_arch)
  os=$(_setup_get_os)

  # Map to kubecm release naming: kubecm_v0.31.0_Linux_x86_64.tar.gz
  local kubecm_os kubecm_arch
  case "$os" in
  darwin) kubecm_os="Darwin" ;;
  linux) kubecm_os="Linux" ;;
  *)
    radp_log_error "Unsupported OS: $os"
    return 1
    ;;
  esac

  case "$arch" in
  amd64) kubecm_arch="x86_64" ;;
  arm64) kubecm_arch="arm64" ;;
  *) kubecm_arch="$arch" ;;
  esac

  local filename="kubecm_v${version}_${kubecm_os}_${kubecm_arch}.tar.gz"
  local url="https://github.com/sunny0826/kubecm/releases/download/v${version}/${filename}"

  local tmpdir
  tmpdir=$(_setup_mktemp_dir)
  trap 'rm -rf "$tmpdir"' EXIT

  radp_log_info "Downloading kubecm $version..."
  radp_io_download "$url" "$tmpdir/$filename" || return 1

  _setup_extract_archive "$tmpdir/$filename" "$tmpdir" || return 1
  _setup_install_binary "$tmpdir/kubecm" || return 1
}
