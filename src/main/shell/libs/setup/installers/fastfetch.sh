#!/usr/bin/env bash
# fastfetch installer

_setup_install_fastfetch() {
  local version="${1:-latest}"

  if _setup_is_installed fastfetch && [[ "$version" == "latest" ]]; then
    radp_log_info "fastfetch is already installed"
    return 0
  fi

  local pm
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

  case "$pm" in
  brew)
    radp_log_info "Installing fastfetch via Homebrew..."
    brew install fastfetch || return 1
    ;;
  dnf | yum)
    radp_log_info "Installing fastfetch via dnf..."
    if ! radp_os_install_pkgs fastfetch 2>/dev/null; then
      radp_log_info "fastfetch not available in repos, falling back to binary release..."
      _setup_fastfetch_from_release "$version"
    fi
    ;;
  apt | apt-get)
    radp_log_info "Installing fastfetch via apt..."
    # fastfetch is available in Ubuntu 24.04+ and Debian 13+
    if radp_os_install_pkgs fastfetch 2>/dev/null; then
      return 0
    fi
    # Fallback to GitHub release
    _setup_fastfetch_from_release "$version"
    ;;
  pacman)
    radp_log_info "Installing fastfetch via pacman..."
    radp_os_install_pkgs fastfetch || return 1
    ;;
  *)
    _setup_fastfetch_from_release "$version"
    ;;
  esac
}

_setup_fastfetch_from_release() {
  local version="$1"

  if [[ "$version" == "latest" ]]; then
    version=$(_setup_github_latest_version "fastfetch-cli/fastfetch")
    [[ -z "$version" ]] && version="2.30.1"
  fi

  local arch os
  arch=$(_setup_get_arch)
  os=$(_setup_get_os)

  local filename
  case "$os" in
  darwin)
    filename="fastfetch-macos-universal.tar.gz"
    ;;
  linux)
    case "$arch" in
    amd64) filename="fastfetch-linux-amd64.tar.gz" ;;
    arm64) filename="fastfetch-linux-aarch64.tar.gz" ;;
    *)
      radp_log_error "Unsupported architecture: $arch"
      return 1
      ;;
    esac
    ;;
  *)
    radp_log_error "Unsupported OS: $os"
    return 1
    ;;
  esac

  local url="https://github.com/fastfetch-cli/fastfetch/releases/download/${version}/${filename}"

  local tmpdir
  tmpdir=$(_setup_mktemp_dir)
  trap 'rm -rf "$tmpdir"; trap - RETURN' RETURN

  radp_log_info "Downloading fastfetch $version..."
  radp_io_download "$url" "$tmpdir/$filename" || return 1

  _setup_extract_archive "$tmpdir/$filename" "$tmpdir" || return 1

  # Find the extracted binary (glob must be unquoted to expand)
  local bin_path
  bin_path=$(find "$tmpdir" -name "fastfetch" -type f -path "*/usr/bin/fastfetch" | head -1)
  if [[ -z "$bin_path" ]]; then
    radp_log_error "Could not find fastfetch binary in extracted archive"
    return 1
  fi
  _setup_install_binary "$bin_path" "fastfetch" || return 1
}
