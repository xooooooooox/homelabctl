#!/usr/bin/env bash
# lazydocker installer

_setup_install_lazydocker() {
  local version="${1:-latest}"

  if _setup_is_installed lazydocker && [[ "$version" == "latest" ]]; then
    radp_log_info "lazydocker is already installed"
    return 0
  fi

  local pm
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

  case "$pm" in
  brew)
    radp_log_info "Installing lazydocker via Homebrew..."
    brew install lazydocker || return 1
    ;;
  pacman)
    radp_log_info "Installing lazydocker via pacman..."
    radp_os_install_pkgs lazydocker || return 1
    ;;
  *)
    _setup_lazydocker_from_release "$version"
    ;;
  esac
}

_setup_lazydocker_from_release() {
  local version="$1"

  if [[ "$version" == "latest" ]]; then
    version=$(_setup_github_latest_version "jesseduffield/lazydocker")
    [[ -z "$version" ]] && version="0.24.1"
  fi

  local arch os
  arch=$(_setup_get_arch)
  os=$(_setup_get_os)

  # Map to lazydocker release naming
  local ld_os ld_arch
  case "$os" in
  darwin) ld_os="Darwin" ;;
  linux) ld_os="Linux" ;;
  *)
    radp_log_error "Unsupported OS: $os"
    return 1
    ;;
  esac

  case "$arch" in
  amd64) ld_arch="x86_64" ;;
  arm64) ld_arch="arm64" ;;
  *) ld_arch="$arch" ;;
  esac

  local filename="lazydocker_${version}_${ld_os}_${ld_arch}.tar.gz"
  local url="https://github.com/jesseduffield/lazydocker/releases/download/v${version}/${filename}"

  local tmpdir
  tmpdir=$(_setup_mktemp_dir)
  trap 'rm -rf "$tmpdir"; trap - RETURN' RETURN

  radp_log_info "Downloading lazydocker $version..."
  radp_io_download "$url" "$tmpdir/$filename" || return 1

  _setup_extract_archive "$tmpdir/$filename" "$tmpdir" || return 1
  _setup_install_binary "$tmpdir/lazydocker" || return 1
}
