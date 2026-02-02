#!/usr/bin/env bash
# tealdeer installer

_setup_install_tealdeer() {
  local version="${1:-latest}"

  if _setup_is_installed tldr && [[ "$version" == "latest" ]]; then
    radp_log_info "tealdeer is already installed"
    return 0
  fi

  local pm
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

  case "$pm" in
  brew)
    radp_log_info "Installing tealdeer via Homebrew..."
    brew install tealdeer || return 1
    ;;
  dnf | yum)
    radp_log_info "Installing tealdeer via dnf..."
    if ! radp_os_install_pkgs tealdeer 2>/dev/null; then
      radp_log_info "tealdeer not available in repos, falling back to binary release..."
      _setup_tealdeer_from_release "$version"
    fi
    ;;
  apt | apt-get)
    radp_log_info "Installing tealdeer via apt..."
    if ! radp_os_install_pkgs tealdeer 2>/dev/null; then
      radp_log_info "tealdeer not available in repos, falling back to binary release..."
      _setup_tealdeer_from_release "$version"
    fi
    ;;
  pacman)
    radp_log_info "Installing tealdeer via pacman..."
    radp_os_install_pkgs tealdeer || return 1
    ;;
  *)
    _setup_tealdeer_from_release "$version"
    ;;
  esac

  # Update tldr cache after installation
  if _setup_is_installed tldr; then
    radp_log_info "Updating tldr cache..."
    tldr --update 2>/dev/null || true
  fi
}

_setup_tealdeer_from_release() {
  local version="$1"

  # Get latest version if needed
  if [[ "$version" == "latest" ]]; then
    version=$(_setup_github_latest_version "dbrgn/tealdeer")
    [[ -z "$version" ]] && version="1.6.1"
  fi

  local arch os
  arch=$(_setup_get_arch)
  os=$(_setup_get_os)

  # Map OS/arch to release naming
  local target
  case "$os" in
  darwin)
    target="tealdeer-macos-x86_64"
    [[ "$arch" == "arm64" ]] && target="tealdeer-macos-arm64"
    ;;
  linux)
    target="tealdeer-linux-x86_64-musl"
    [[ "$arch" == "arm64" ]] && target="tealdeer-linux-arm64-musleabi"
    ;;
  *)
    radp_log_error "Unsupported OS: $os"
    return 1
    ;;
  esac

  local url="https://github.com/dbrgn/tealdeer/releases/download/v${version}/${target}"

  local tmpdir
  tmpdir=$(_setup_mktemp_dir)
  trap 'rm -rf "$tmpdir"; trap - RETURN' RETURN

  radp_log_info "Downloading tealdeer $version..."
  radp_io_download "$url" "$tmpdir/tldr" || return 1

  chmod +x "$tmpdir/tldr"
  _setup_install_binary "$tmpdir/tldr" || return 1
}
