#!/usr/bin/env bash
# bat installer

_setup_install_bat() {
  local version="${1:-latest}"

  if _setup_is_installed bat && [[ "$version" == "latest" ]]; then
    radp_log_info "bat is already installed"
    return 0
  fi

  local pm
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

  case "$pm" in
  brew)
    radp_log_info "Installing bat via Homebrew..."
    brew install bat || return 1
    ;;
  dnf | yum)
    radp_log_info "Installing bat via dnf..."
    radp_os_install_pkgs bat || return 1
    ;;
  apt | apt-get)
    radp_log_info "Installing bat via apt..."
    # bat is called 'bat' but the binary might be 'batcat' on Debian/Ubuntu
    radp_os_install_pkgs bat || return 1
    # Create symlink if needed
    if _setup_is_installed batcat && ! _setup_is_installed bat; then
      mkdir -p "$HOME/.local/bin"
      ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
      radp_log_info "Created symlink: bat -> batcat"
    fi
    ;;
  pacman)
    radp_log_info "Installing bat via pacman..."
    radp_os_install_pkgs bat || return 1
    ;;
  *)
    _setup_bat_from_release "$version"
    ;;
  esac
}

_setup_bat_from_release() {
  local version="$1"

  # Get latest version if needed
  if [[ "$version" == "latest" ]]; then
    version=$(_setup_github_latest_version "sharkdp/bat")
    [[ -z "$version" ]] && version="0.24.0"
  fi

  local arch os
  arch=$(_setup_get_arch)
  os=$(_setup_get_os)

  # Map OS/arch to release naming
  local target
  case "$os" in
  darwin)
    target="bat-v${version}-x86_64-apple-darwin"
    [[ "$arch" == "arm64" ]] && target="bat-v${version}-aarch64-apple-darwin"
    ;;
  linux)
    target="bat-v${version}-x86_64-unknown-linux-musl"
    [[ "$arch" == "arm64" ]] && target="bat-v${version}-aarch64-unknown-linux-gnu"
    ;;
  *)
    radp_log_error "Unsupported OS: $os"
    return 1
    ;;
  esac

  local filename="${target}.tar.gz"
  local url="https://github.com/sharkdp/bat/releases/download/v${version}/${filename}"

  local tmpdir
  tmpdir=$(_setup_mktemp_dir)
  trap 'rm -rf "$tmpdir"' RETURN

  radp_log_info "Downloading bat $version..."
  radp_io_download "$url" "$tmpdir/$filename" || return 1

  _setup_extract_archive "$tmpdir/$filename" "$tmpdir" || return 1
  _setup_install_binary "$tmpdir/$target/bat" || return 1
}
