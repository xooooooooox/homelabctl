#!/usr/bin/env bash
# mc (MinIO client) installer

_setup_install_mc() {
  local version="${1:-latest}"

  if _setup_is_installed mc && [[ "$version" == "latest" ]]; then
    radp_log_info "mc is already installed"
    return 0
  fi

  local pm
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

  case "$pm" in
  brew)
    radp_log_info "Installing mc via Homebrew..."
    brew install minio/stable/mc || return 1
    ;;
  *)
    _setup_mc_from_binary "$version"
    ;;
  esac
}

_setup_mc_from_binary() {
  local version="$1"

  local arch os
  arch=$(_setup_get_arch)
  os=$(_setup_get_os)

  # MinIO client direct binary download
  local url="https://dl.min.io/client/mc/release/${os}-${arch}/mc"

  local tmpdir
  tmpdir=$(_setup_mktemp_dir)
  trap 'rm -rf "$tmpdir"' EXIT

  radp_log_info "Downloading mc (MinIO client)..."
  radp_io_download "$url" "$tmpdir/mc" || return 1

  chmod +x "$tmpdir/mc"
  _setup_install_binary "$tmpdir/mc" || return 1
}
