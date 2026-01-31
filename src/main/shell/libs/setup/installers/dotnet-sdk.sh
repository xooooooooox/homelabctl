#!/usr/bin/env bash
# dotnet-sdk installer
# .NET SDK for building and running .NET applications

_setup_install_dotnet_sdk() {
  local version="${1:-latest}"

  if _setup_is_installed dotnet && [[ "$version" == "latest" ]]; then
    radp_log_info "dotnet-sdk is already installed"
    return 0
  fi

  local pm
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

  case "$pm" in
  brew)
    radp_log_info "Installing dotnet-sdk via Homebrew..."
    brew install --cask dotnet-sdk || return 1
    ;;
  apt)
    # Ubuntu 22.04+ has .NET in official repos (supports ARM64)
    # For older versions or other Debian-based, use Microsoft's script
    if _setup_dotnet_apt_available; then
      _setup_dotnet_via_apt "$version"
    else
      _setup_dotnet_via_script "$version"
    fi
    ;;
  dnf | yum)
    # RHEL/Fedora: use Microsoft packages or install script
    _setup_dotnet_via_script "$version"
    ;;
  *)
    _setup_dotnet_via_script "$version"
    ;;
  esac
}

# Check if .NET SDK is available in apt repos
_setup_dotnet_apt_available() {
  apt-cache search --names-only '^dotnet-sdk-[0-9]' 2>/dev/null | grep -q dotnet-sdk
}

# Install via apt (Ubuntu 22.04+)
_setup_dotnet_via_apt() {
  local version="$1"
  local pkg="dotnet-sdk-8.0"

  # Map version to package name
  if [[ "$version" != "latest" ]]; then
    local major="${version%%.*}"
    pkg="dotnet-sdk-${major}.0"
  fi

  radp_log_info "Installing $pkg via apt..."
  $gr_sudo apt-get update || return 1
  $gr_sudo apt-get install -y "$pkg" || return 1
}

# Install via Microsoft's install script (fallback)
_setup_dotnet_via_script() {
  local version="$1"
  local channel="LTS"

  if [[ "$version" != "latest" ]]; then
    channel="${version%%.*}.0"
  fi

  radp_log_info "Installing .NET SDK via Microsoft install script..."

  local tmpdir
  tmpdir=$(_setup_mktemp_dir)
  trap 'rm -rf "$tmpdir"; trap - RETURN' RETURN

  # Download install script
  local script_url="https://dot.net/v1/dotnet-install.sh"
  radp_io_download "$script_url" "$tmpdir/dotnet-install.sh" || return 1
  chmod +x "$tmpdir/dotnet-install.sh"

  # Install to ~/.dotnet (user-local)
  "$tmpdir/dotnet-install.sh" --channel "$channel" --install-dir "$HOME/.dotnet" || return 1

  # Add to PATH hint
  if [[ ":$PATH:" != *":$HOME/.dotnet:"* ]]; then
    radp_log_info "Add to your shell profile: export PATH=\"\$HOME/.dotnet:\$PATH\""
  fi

  radp_log_info ".NET SDK installed to ~/.dotnet"
}
