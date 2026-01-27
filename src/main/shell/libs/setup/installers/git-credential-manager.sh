#!/usr/bin/env bash
# git-credential-manager installer

_setup_install_git_credential_manager() {
  local version="${1:-latest}"

  if _setup_is_installed git-credential-manager && [[ "$version" == "latest" ]]; then
    radp_log_info "git-credential-manager is already installed"
    return 0
  fi

  local pm
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

  case "$pm" in
  brew)
    radp_log_info "Installing git-credential-manager via Homebrew..."
    brew install --cask git-credential-manager || return 1
    ;;
  *)
    _setup_gcm_from_release "$version"
    ;;
  esac
}

_setup_gcm_from_release() {
  local version="$1"

  if [[ "$version" == "latest" ]]; then
    version=$(_setup_github_latest_version "git-ecosystem/git-credential-manager")
    [[ -z "$version" ]] && version="2.6.1"
  fi

  local arch os
  arch=$(_setup_get_arch)
  os=$(_setup_get_os)

  if [[ "$os" != "linux" ]]; then
    radp_log_error "Binary release install only supported on Linux (use brew on macOS)"
    return 1
  fi

  # GCM only provides amd64 Linux tarballs
  if [[ "$arch" != "amd64" ]]; then
    radp_log_info "No prebuilt binary for $arch, installing from source script..."
    _setup_gcm_from_source
    return $?
  fi

  local filename="gcm-linux_amd64.${version}.tar.gz"
  local url="https://github.com/git-ecosystem/git-credential-manager/releases/download/v${version}/${filename}"

  local tmpdir
  tmpdir=$(_setup_mktemp_dir)
  trap 'rm -rf "$tmpdir"; trap - RETURN' RETURN

  radp_log_info "Downloading git-credential-manager $version..."
  radp_io_download "$url" "$tmpdir/$filename" || return 1

  $gr_sudo tar -xzf "$tmpdir/$filename" -C /usr/local/bin || return 1
  radp_log_info "git-credential-manager installed to /usr/local/bin"
}

_setup_gcm_from_source() {
  local tmpdir
  tmpdir=$(_setup_mktemp_dir)
  trap 'rm -rf "$tmpdir"; trap - RETURN' RETURN

  radp_log_info "Installing git-credential-manager from source script..."
  radp_io_download "https://aka.ms/gcm/linux-install-source.sh" "$tmpdir/install.sh" || return 1
  bash "$tmpdir/install.sh" -y || return 1
}
