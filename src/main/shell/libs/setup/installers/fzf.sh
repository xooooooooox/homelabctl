#!/usr/bin/env bash
# fzf installer

_setup_install_fzf() {
  local version="${1:-latest}"

  if _setup_is_installed fzf && [[ "$version" == "latest" ]]; then
    radp_log_info "fzf is already installed"
    return 0
  fi

  local pm
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

  case "$pm" in
  brew)
    radp_log_info "Installing fzf via Homebrew..."
    brew install fzf || return 1
    # Run fzf install script for shell integration
    "$(brew --prefix)/opt/fzf/install" --key-bindings --completion --no-update-rc --no-bash --no-fish 2>/dev/null || true
    ;;
  dnf | yum)
    radp_log_info "Installing fzf via dnf..."
    if ! radp_os_install_pkgs fzf 2>/dev/null; then
      radp_log_info "fzf not available in repos, falling back to binary release..."
      _setup_fzf_from_release "$version" || _setup_fzf_from_git
    fi
    ;;
  apt | apt-get)
    # apt version is often outdated, prefer binary release
    _setup_fzf_from_release "$version" || _setup_fzf_from_git
    ;;
  pacman)
    radp_log_info "Installing fzf via pacman..."
    radp_os_install_pkgs fzf || return 1
    ;;
  *)
    _setup_fzf_from_release "$version"
    ;;
  esac
}

_setup_fzf_from_git() {
  local fzf_home="$HOME/.fzf"

  if ! command -v git >/dev/null 2>&1; then
    radp_log_error "git is required for fzf git install but not found"
    return 1
  fi

  radp_log_info "Installing fzf from git..."

  if [[ -d "$fzf_home" ]]; then
    radp_log_warn "$fzf_home exists, updating..."
    cd "$fzf_home" && git pull || return 1
  else
    git clone --depth 1 https://github.com/junegunn/fzf.git "$fzf_home" || return 1
  fi

  "$fzf_home/install" --key-bindings --completion --no-update-rc || return 1
}

_setup_fzf_from_release() {
  local version="$1"

  # Get latest version if needed
  if [[ "$version" == "latest" ]]; then
    version=$(_setup_github_latest_version "junegunn/fzf")
    [[ -z "$version" ]] && version="0.55.0"
  fi

  local arch os
  arch=$(_setup_get_arch)
  os=$(_setup_get_os)

  local filename="fzf-${version}-${os}_${arch}.tar.gz"
  local url="https://github.com/junegunn/fzf/releases/download/v${version}/${filename}"

  local tmpdir
  tmpdir=$(_setup_mktemp_dir)
  trap 'rm -rf "$tmpdir"; trap - RETURN' RETURN

  radp_log_info "Downloading fzf $version..."
  radp_io_download "$url" "$tmpdir/$filename" || return 1

  _setup_extract_archive "$tmpdir/$filename" "$tmpdir" || return 1
  _setup_install_binary "$tmpdir/fzf" || return 1
}
