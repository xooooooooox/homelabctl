#!/usr/bin/env bash
# eza installer

_setup_install_eza() {
  local version="${1:-latest}"

  if _setup_is_installed eza && [[ "$version" == "latest" ]]; then
    radp_log_info "eza is already installed"
    return 0
  fi

  local pm
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

  case "$pm" in
  brew)
    radp_log_info "Installing eza via Homebrew..."
    brew install eza || return 1
    ;;
  dnf | yum)
    radp_log_info "Installing eza via dnf..."
    if ! radp_os_install_pkgs eza 2>/dev/null; then
      radp_log_info "eza not available in repos, falling back to binary release..."
      _setup_eza_from_release "$version"
    fi
    ;;
  apt | apt-get)
    radp_log_info "Installing eza via apt..."
    if ! radp_os_install_pkgs eza 2>/dev/null; then
      radp_log_info "eza not available in repos, falling back to binary release..."
      _setup_eza_from_release "$version"
    fi
    ;;
  pacman)
    radp_log_info "Installing eza via pacman..."
    radp_os_install_pkgs eza || return 1
    ;;
  *)
    _setup_eza_from_release "$version"
    ;;
  esac
}

_setup_eza_from_release() {
  local version="$1"

  if [[ "$version" == "latest" ]]; then
    version=$(_setup_github_latest_version "eza-community/eza")
    [[ -z "$version" ]] && version="0.20.14"
  fi

  local arch os
  arch=$(_setup_get_arch)
  os=$(_setup_get_os)

  local target
  case "$os" in
  darwin)
    target="eza-x86_64-apple-darwin"
    [[ "$arch" == "arm64" ]] && target="eza-aarch64-apple-darwin"
    ;;
  linux)
    target="eza-x86_64-unknown-linux-musl"
    [[ "$arch" == "arm64" ]] && target="eza-aarch64-unknown-linux-gnu"
    ;;
  *)
    radp_log_error "Unsupported OS: $os"
    return 1
    ;;
  esac

  local filename="${target}.tar.gz"
  local url="https://github.com/eza-community/eza/releases/download/v${version}/${filename}"

  local tmpdir
  tmpdir=$(_setup_mktemp_dir)
  trap 'rm -rf "$tmpdir"; trap - RETURN' RETURN

  radp_log_info "Downloading eza $version..."
  radp_io_download "$url" "$tmpdir/$filename" || return 1

  _setup_extract_archive "$tmpdir/$filename" "$tmpdir" || return 1
  _setup_install_binary "$tmpdir/eza" || return 1
}
