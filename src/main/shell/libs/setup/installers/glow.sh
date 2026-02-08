#!/usr/bin/env bash
# glow installer

_setup_install_glow() {
  local version="${1:-latest}"

  if _setup_is_installed glow && [[ "$version" == "latest" ]]; then
    radp_log_info "glow is already installed"
    return 0
  fi

  local pm
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

  case "$pm" in
  brew)
    radp_log_info "Installing glow via Homebrew..."
    brew install glow || return 1
    ;;
  dnf | yum)
    radp_log_info "Installing glow via dnf..."
    if ! radp_os_install_pkgs glow 2>/dev/null; then
      radp_log_info "glow not available in repos, falling back to binary release..."
      _setup_glow_from_release "$version"
    fi
    ;;
  apt | apt-get)
    radp_log_info "Installing glow via apt..."
    if radp_os_install_pkgs glow 2>/dev/null; then
      return 0
    fi
    _setup_glow_from_release "$version"
    ;;
  pacman)
    radp_log_info "Installing glow via pacman..."
    radp_os_install_pkgs glow || return 1
    ;;
  *)
    _setup_glow_from_release "$version"
    ;;
  esac
}

_setup_glow_from_release() {
  local version="$1"

  if [[ "$version" == "latest" ]]; then
    version=$(_setup_github_latest_version "charmbracelet/glow")
    [[ -z "$version" ]] && version="2.1.1"
  fi

  local arch os
  arch=$(_setup_get_arch)
  os=$(_setup_get_os)

  local os_name arch_name
  case "$os" in
  darwin)
    os_name="Darwin"
    case "$arch" in
    amd64) arch_name="x86_64" ;;
    arm64) arch_name="arm64" ;;
    *)
      radp_log_error "Unsupported architecture: $arch"
      return 1
      ;;
    esac
    ;;
  linux)
    os_name="Linux"
    case "$arch" in
    amd64) arch_name="x86_64" ;;
    arm64) arch_name="arm64" ;;
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

  local filename="glow_${version}_${os_name}_${arch_name}.tar.gz"
  local url="https://github.com/charmbracelet/glow/releases/download/v${version}/${filename}"

  local tmpdir
  tmpdir=$(_setup_mktemp_dir)
  trap 'rm -rf "$tmpdir"; trap - RETURN' RETURN

  radp_log_info "Downloading glow $version..."
  radp_io_download "$url" "$tmpdir/$filename" || return 1

  _setup_extract_archive "$tmpdir/$filename" "$tmpdir" || return 1
  _setup_install_binary "$tmpdir/glow" || return 1
}
