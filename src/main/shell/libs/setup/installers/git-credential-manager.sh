#!/usr/bin/env bash
# git-credential-manager installer

_setup_install_git_credential_manager() {
  local version="${1:-latest}"

  if _setup_is_installed git-credential-manager && [[ "$version" == "latest" ]]; then
    radp_log_info "git-credential-manager is already installed"
    return 0
  fi

  local pm arch
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")
  arch=$(_setup_get_arch)

  case "$pm" in
  brew)
    radp_log_info "Installing git-credential-manager via Homebrew..."
    brew install --cask git-credential-manager || return 1
    ;;
  *)
    # GCM only provides amd64 Linux binaries
    # For ARM64, install via dotnet tool
    if [[ "$arch" != "amd64" ]]; then
      _setup_gcm_via_dotnet_tool "$version"
    else
      _setup_gcm_from_release "$version"
    fi
    ;;
  esac
}

_setup_gcm_from_release() {
  local version="$1"

  if [[ "$version" == "latest" ]]; then
    version=$(_setup_github_latest_version "git-ecosystem/git-credential-manager")
    [[ -z "$version" ]] && version="2.6.1"
  fi

  local os
  os=$(_setup_get_os)

  if [[ "$os" != "linux" ]]; then
    radp_log_error "Binary release install only supported on Linux (use brew on macOS)"
    return 1
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

# Install GCM via dotnet tool (for ARM64 and other non-amd64 architectures)
# Reference: https://github.com/git-ecosystem/git-credential-manager/discussions/1217
_setup_gcm_via_dotnet_tool() {
  local version="$1"

  # Check if dotnet is available
  if ! _setup_is_installed dotnet; then
    radp_log_info "dotnet-sdk is required for ARM64 installation, installing..."
    _setup_run_installer dotnet-sdk latest || {
      radp_log_error "Failed to install dotnet-sdk"
      radp_log_info "Install dotnet-sdk manually, then retry: homelabctl setup install dotnet-sdk"
      return 1
    }
    # Refresh PATH to find dotnet
    export PATH="$HOME/.dotnet:$PATH"
    hash -r 2>/dev/null || true
  fi

  radp_log_info "Installing git-credential-manager via dotnet tool..."

  # Install as global dotnet tool
  if [[ "$version" == "latest" ]]; then
    dotnet tool install -g git-credential-manager || return 1
  else
    dotnet tool install -g git-credential-manager --version "$version" || return 1
  fi

  # dotnet tools are installed to ~/.dotnet/tools
  local tools_path="$HOME/.dotnet/tools"
  if [[ ":$PATH:" != *":$tools_path:"* ]]; then
    radp_log_info "Add to your shell profile: export PATH=\"\$HOME/.dotnet/tools:\$PATH\""
  fi

  radp_log_info "git-credential-manager installed via dotnet tool"
}
