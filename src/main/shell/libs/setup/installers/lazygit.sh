#!/usr/bin/env bash
# lazygit installer

_setup_install_lazygit() {
  local version="${1:-latest}"

  if _setup_is_installed lazygit && [[ "$version" == "latest" ]]; then
    radp_log_info "lazygit is already installed"
    return 0
  fi

  local pm
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

  case "$pm" in
  brew)
    radp_log_info "Installing lazygit via Homebrew..."
    brew install lazygit || return 1
    ;;
  dnf | yum)
    radp_log_info "Installing lazygit via dnf copr..."
    $gr_sudo dnf copr enable atim/lazygit -y 2>/dev/null
    if ! radp_os_install_pkgs lazygit 2>/dev/null; then
      radp_log_info "lazygit not available via copr, falling back to binary release..."
      _setup_lazygit_from_release "$version"
    fi
    ;;
  pacman)
    radp_log_info "Installing lazygit via pacman..."
    radp_os_install_pkgs lazygit || return 1
    ;;
  *)
    _setup_lazygit_from_release "$version"
    ;;
  esac
}

_setup_lazygit_from_release() {
  local version="$1"

  if [[ "$version" == "latest" ]]; then
    version=$(_setup_github_latest_version "jesseduffield/lazygit")
    [[ -z "$version" ]] && version="0.44.1"
  fi

  local arch os
  arch=$(_setup_get_arch)
  os=$(_setup_get_os)

  # Map to lazygit release naming
  local lg_os lg_arch
  case "$os" in
  darwin) lg_os="Darwin" ;;
  linux) lg_os="Linux" ;;
  *)
    radp_log_error "Unsupported OS: $os"
    return 1
    ;;
  esac

  case "$arch" in
  amd64) lg_arch="x86_64" ;;
  arm64) lg_arch="arm64" ;;
  *) lg_arch="$arch" ;;
  esac

  local filename="lazygit_${version}_${lg_os}_${lg_arch}.tar.gz"
  local url="https://github.com/jesseduffield/lazygit/releases/download/v${version}/${filename}"

  local tmpdir
  tmpdir=$(_setup_mktemp_dir)
  trap 'rm -rf "$tmpdir"; trap - RETURN' RETURN

  radp_log_info "Downloading lazygit $version..."
  radp_io_download "$url" "$tmpdir/$filename" || return 1

  _setup_extract_archive "$tmpdir/$filename" "$tmpdir" || return 1
  _setup_install_binary "$tmpdir/lazygit" || return 1
}
