#!/usr/bin/env bash
# docker-compose installer

# Default version if not specified
declare -g _DOCKER_COMPOSE_DEFAULT_VERSION="2.30.3"

#######################################
# Install Docker Compose
# Arguments:
#   1 - version: Version to install (default: 2.30.3)
# Returns:
#   0 - Success
#   1 - Failure
#######################################
_setup_install_docker_compose() {
  local version="${1:-latest}"

  # Resolve version
  if [[ "$version" == "latest" ]]; then
    version=$(_setup_docker_compose_get_latest_version)
  fi

  # Check if already installed with same version
  if _setup_is_installed docker-compose; then
    local installed_ver
    installed_ver=$(_setup_get_installed_version docker-compose)
    if [[ "$installed_ver" == "$version" ]]; then
      radp_log_info "docker-compose $version is already installed"
      return 0
    fi
  fi

  local pm
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

  radp_log_info "Installing docker-compose v${version}..."

  case "$pm" in
  brew)
    radp_log_info "Installing docker-compose via Homebrew..."
    radp_exec "Install docker-compose via Homebrew" brew install docker-compose || return 1
    ;;
  *)
    # Install from GitHub releases (binary)
    _setup_docker_compose_from_github "$version" || return 1
    ;;
  esac

  # Verify installation
  if _setup_is_installed docker-compose; then
    radp_log_info "docker-compose installed successfully"
    docker-compose --version
    return 0
  else
    radp_log_error "docker-compose installation verification failed"
    return 1
  fi
}

#######################################
# Uninstall Docker Compose
# Arguments:
#   1 - purge: If non-empty, also remove configuration files (unused for docker-compose)
# Returns:
#   0 - Success
#   1 - Failure
#######################################
_setup_uninstall_docker_compose() {
  local purge="${1:-}"

  if ! _setup_is_installed docker-compose; then
    radp_log_info "docker-compose is not installed"
    return 0
  fi

  local pm
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

  radp_log_info "Uninstalling docker-compose..."

  case "$pm" in
  brew)
    radp_exec "Uninstall docker-compose via Homebrew" brew uninstall docker-compose || return 1
    ;;
  *)
    # Remove binary
    local binary_path
    binary_path=$(command -v docker-compose 2>/dev/null)
    if [[ -n "$binary_path" ]]; then
      radp_exec_sudo "Remove $binary_path" rm -f "$binary_path" || {
        radp_log_error "Failed to remove $binary_path"
        return 1
      }
    fi
    ;;
  esac

  radp_log_info "docker-compose uninstalled successfully"
  return 0
}

#######################################
# Install Docker Compose from GitHub releases
# Arguments:
#   1 - version: Version to install
# Returns:
#   0 - Success
#   1 - Failure
#######################################
_setup_docker_compose_from_github() {
  local version="${1:?'Version required'}"

  # Detect OS and architecture
  local os arch
  os=$(_common_get_os)
  arch=$(_common_get_arch)

  # Map architecture names for docker-compose download URL
  case "$arch" in
  amd64)
    arch="x86_64"
    ;;
  arm64)
    arch="aarch64"
    ;;
  armv7)
    arch="armv7"
    ;;
  *)
    radp_log_error "Unsupported architecture: $arch"
    return 1
    ;;
  esac

  # Map OS names
  case "$os" in
  linux)
    os="linux"
    ;;
  darwin)
    os="darwin"
    ;;
  *)
    radp_log_error "Unsupported OS: $os"
    return 1
    ;;
  esac

  local binary_name="docker-compose-${os}-${arch}"
  local download_url="https://github.com/docker/compose/releases/download/v${version}/${binary_name}"
  local install_path="/usr/local/bin/docker-compose"

  # Create temp directory
  local tmpdir
  tmpdir=$(_setup_mktemp_dir) || {
    radp_log_error "Failed to create temp directory"
    return 1
  }
  trap 'rm -rf "$tmpdir"; trap - RETURN' RETURN

  radp_log_info "Downloading docker-compose from GitHub..."
  radp_log_debug "URL: $download_url"

  # Download binary
  radp_io_download "$download_url" "$tmpdir/docker-compose" || {
    radp_log_error "Failed to download docker-compose"
    return 1
  }

  # Install binary
  radp_exec_sudo "Create $(dirname "$install_path")" mkdir -p "$(dirname "$install_path")" || return 1
  radp_exec_sudo "Install docker-compose to $install_path" cp "$tmpdir/docker-compose" "$install_path" || {
    radp_log_error "Failed to install docker-compose to $install_path"
    return 1
  }
  radp_exec_sudo "Set execute permission on docker-compose" chmod +x "$install_path" || return 1

  radp_log_info "Installed docker-compose to $install_path"
  return 0
}

#######################################
# Get latest Docker Compose version from GitHub
# Returns:
#   Prints version string (without 'v' prefix)
#######################################
_setup_docker_compose_get_latest_version() {
  local version
  version=$(radp_net_github_latest_release "docker/compose" 2>/dev/null)

  if [[ -n "$version" ]]; then
    # Remove 'v' prefix if present
    echo "${version#v}"
  else
    # Fallback to default version
    echo "$_DOCKER_COMPOSE_DEFAULT_VERSION"
  fi
}
