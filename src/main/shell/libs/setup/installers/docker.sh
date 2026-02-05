#!/usr/bin/env bash
# docker installer

#######################################
# Install Docker
# Arguments:
#   1 - version: Version to install (default: latest)
# Returns:
#   0 - Success
#   1 - Failure
#######################################
_setup_install_docker() {
  local version="${1:-latest}"

  if _setup_is_installed docker && [[ "$version" == "latest" ]]; then
    radp_log_info "docker is already installed"
    return 0
  fi

  local pm
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

  case "$pm" in
  brew)
    radp_log_info "Installing Docker Desktop via Homebrew..."
    radp_exec "Install Docker Desktop via Homebrew" brew install --cask docker || return 1
    ;;
  dnf | yum)
    _setup_docker_from_official "$pm"
    ;;
  apt | apt-get)
    _setup_docker_from_official "apt"
    ;;
  *)
    _setup_docker_from_script
    ;;
  esac
}

#######################################
# Uninstall Docker
# Arguments:
#   1 - purge: If non-empty, also remove configuration files
# Returns:
#   0 - Success
#   1 - Failure
#######################################
_setup_uninstall_docker() {
  local purge="${1:-}"

  if ! _setup_is_installed docker; then
    radp_log_info "docker is not installed"
    return 0
  fi

  local pm
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

  radp_log_info "Uninstalling Docker..."

  # Stop services first
  if _common_is_command_available systemctl; then
    radp_exec_sudo "Stop docker.service" systemctl stop docker.service 2>/dev/null || true
    radp_exec_sudo "Stop docker.socket" systemctl stop docker.socket 2>/dev/null || true
    radp_exec_sudo "Stop containerd.service" systemctl stop containerd.service 2>/dev/null || true
  fi

  case "$pm" in
  brew)
    radp_log_info "Uninstalling Docker Desktop via Homebrew..."
    radp_exec "Uninstall Docker Desktop via Homebrew" brew uninstall --cask docker || return 1
    ;;
  dnf)
    radp_exec_sudo "Remove Docker packages via dnf" dnf remove -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras 2>/dev/null || true
    ;;
  yum)
    radp_exec_sudo "Remove Docker packages via yum" yum remove -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras 2>/dev/null || true
    ;;
  apt | apt-get)
    if [[ -n "$purge" ]]; then
      radp_exec_sudo "Purge Docker packages via apt" apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras 2>/dev/null || true
    else
      radp_exec_sudo "Remove Docker packages via apt" apt-get remove -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras 2>/dev/null || true
    fi
    radp_exec_sudo "Autoremove unused packages" apt-get autoremove -y 2>/dev/null || true
    ;;
  *)
    radp_log_error "Unsupported package manager: $pm"
    return 1
    ;;
  esac

  # Remove configuration files if purge is requested
  if [[ -n "$purge" ]]; then
    radp_log_info "Removing Docker configuration and data..."
    radp_exec_sudo "Remove /var/lib/docker" rm -rf /var/lib/docker 2>/dev/null || true
    radp_exec_sudo "Remove /var/lib/containerd" rm -rf /var/lib/containerd 2>/dev/null || true
    radp_exec_sudo "Remove /etc/docker" rm -rf /etc/docker 2>/dev/null || true
    radp_exec_sudo "Remove docker.service.d" rm -rf /etc/systemd/system/docker.service.d 2>/dev/null || true
    radp_exec_sudo "Remove containerd.service.d" rm -rf /etc/systemd/system/containerd.service.d 2>/dev/null || true
    # Reload systemd if drop-in files were removed
    if _common_is_command_available systemctl; then
      radp_exec_sudo "Reload systemd daemon" systemctl daemon-reload 2>/dev/null || true
    fi
  fi

  radp_log_info "Docker uninstalled successfully"
  return 0
}

#######################################
# Remove old Docker packages before fresh installation
# Arguments:
#   None
# Returns:
#   0 - Success (or no old packages found)
#   1 - Failure
#######################################
_setup_docker_remove_old_packages() {
  local pm
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

  radp_log_info "Removing old Docker packages..."

  case "$pm" in
  dnf | yum)
    local old_pkgs=(docker docker-client docker-client-latest docker-common
      docker-latest docker-latest-logrotate docker-logrotate docker-engine
      podman-docker containerd runc)
    for pkg in "${old_pkgs[@]}"; do
      radp_exec_sudo "Remove old package $pkg" "$pm" remove -y "$pkg" 2>/dev/null || true
    done
    ;;
  apt | apt-get)
    local old_pkgs=(docker docker-engine docker.io containerd runc)
    for pkg in "${old_pkgs[@]}"; do
      radp_exec_sudo "Remove old package $pkg" apt-get remove -y "$pkg" 2>/dev/null || true
    done
    ;;
  *)
    radp_log_debug "No old packages to remove for package manager: $pm"
    ;;
  esac

  return 0
}

_setup_docker_from_official() {
  local pm="$1"

  case "$pm" in
  dnf | yum)
    radp_log_info "Installing Docker via official dnf repo..."
    radp_exec_sudo "Install yum-utils" "$pm" install -y yum-utils 2>/dev/null || true
    radp_exec_sudo "Add Docker repo" "$pm" config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo 2>/dev/null ||
      radp_exec_sudo "Install dnf-plugins-core and add repo" "$pm" -y install dnf-plugins-core && radp_exec_sudo "Add Docker repo" "$pm" config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    radp_exec_sudo "Install Docker packages" "$pm" install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || return 1
    ;;
  apt)
    radp_log_info "Installing Docker via official apt repo..."
    radp_os_install_pkgs ca-certificates curl || return 1

    # Add Docker GPG key
    radp_exec_sudo "Create keyrings directory" install -m 0755 -d /etc/apt/keyrings
    radp_exec_sudo "Download Docker GPG key" curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    radp_exec_sudo "Set permissions on GPG key" chmod a+r /etc/apt/keyrings/docker.asc

    # Add apt repo
    # shellcheck disable=SC1091
    source /etc/os-release
    if radp_dry_run_skip "Add Docker apt repository"; then
      : # skip
    else
      echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/${ID} ${VERSION_CODENAME} stable" |
        $gr_sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
    fi
    radp_exec_sudo "Update apt cache" apt-get update
    radp_exec_sudo "Install Docker packages" apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || return 1
    ;;
  esac

  radp_exec_sudo "Enable Docker service" systemctl enable docker 2>/dev/null || true
  radp_exec_sudo "Start Docker service" systemctl start docker 2>/dev/null || true
}

_setup_docker_from_script() {
  radp_log_info "Installing Docker via official install script..."

  local tmpdir
  tmpdir=$(_setup_mktemp_dir)
  trap 'rm -rf "$tmpdir"; trap - RETURN' RETURN

  radp_io_download "https://get.docker.com" "$tmpdir/get-docker.sh" || return 1
  radp_exec_sudo "Run Docker install script" bash "$tmpdir/get-docker.sh" || return 1
}
