#!/usr/bin/env bash
# containerd installer

#######################################
# Install containerd
# Arguments:
#   1 - version: Version to install (default: latest)
# Returns:
#   0 - Success
#   1 - Failure
#######################################
_setup_install_containerd() {
  local version="${1:-latest}"

  if _setup_is_installed containerd && [[ "$version" == "latest" ]]; then
    radp_log_info "containerd is already installed"
    return 0
  fi

  local pm
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

  radp_log_info "Installing containerd..."

  case "$pm" in
  brew)
    radp_log_info "Installing containerd via Homebrew..."
    radp_exec "Install containerd via Homebrew" brew install containerd || return 1
    ;;
  dnf | yum)
    _setup_containerd_from_docker_repo "$pm" || return 1
    ;;
  apt | apt-get)
    _setup_containerd_from_docker_repo "apt" || return 1
    ;;
  *)
    radp_log_error "Unsupported package manager: $pm"
    return 1
    ;;
  esac

  # Configure containerd with systemd cgroup driver
  _setup_containerd_configure_cgroup || return 1

  # Enable and start service
  if _common_is_command_available systemctl; then
    radp_exec_sudo "Enable containerd service" systemctl enable containerd 2>/dev/null || true
    radp_exec_sudo "Restart containerd service" systemctl restart containerd || {
      radp_log_error "Failed to start containerd service"
      return 1
    }
  fi

  radp_log_info "containerd installed successfully"
  return 0
}

#######################################
# Uninstall containerd
# Arguments:
#   1 - purge: If non-empty, also remove configuration files
# Returns:
#   0 - Success
#   1 - Failure
#######################################
_setup_uninstall_containerd() {
  local purge="${1:-}"

  if ! _setup_is_installed containerd; then
    radp_log_info "containerd is not installed"
    return 0
  fi

  local pm
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

  radp_log_info "Uninstalling containerd..."

  # Stop service first
  if _common_is_command_available systemctl; then
    radp_exec_sudo "Stop containerd service" systemctl stop containerd.service 2>/dev/null || true
  fi

  case "$pm" in
  brew)
    radp_exec "Uninstall containerd via Homebrew" brew uninstall containerd || return 1
    ;;
  dnf)
    radp_exec_sudo "Remove containerd.io via dnf" dnf remove -y containerd.io 2>/dev/null || true
    ;;
  yum)
    radp_exec_sudo "Remove containerd.io via yum" yum remove -y containerd.io 2>/dev/null || true
    ;;
  apt | apt-get)
    if [[ -n "$purge" ]]; then
      radp_exec_sudo "Purge containerd.io via apt" apt-get purge -y containerd.io 2>/dev/null || true
    else
      radp_exec_sudo "Remove containerd.io via apt" apt-get remove -y containerd.io 2>/dev/null || true
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
    radp_log_info "Removing containerd configuration and data..."
    radp_exec_sudo "Remove /var/lib/containerd" rm -rf /var/lib/containerd 2>/dev/null || true
    radp_exec_sudo "Remove /etc/containerd" rm -rf /etc/containerd 2>/dev/null || true
    radp_exec_sudo "Remove containerd.service.d" rm -rf /etc/systemd/system/containerd.service.d 2>/dev/null || true
    if _common_is_command_available systemctl; then
      radp_exec_sudo "Reload systemd daemon" systemctl daemon-reload 2>/dev/null || true
    fi
  fi

  radp_log_info "containerd uninstalled successfully"
  return 0
}

#######################################
# Install containerd from Docker repository
# Arguments:
#   1 - pm: Package manager (dnf, yum, apt)
# Returns:
#   0 - Success
#   1 - Failure
#######################################
_setup_containerd_from_docker_repo() {
  local pm="$1"

  case "$pm" in
  dnf | yum)
    # Add Docker repository if not exists
    if [[ ! -f /etc/yum.repos.d/docker-ce.repo ]]; then
      radp_exec_sudo "Install yum-utils" "$pm" install -y yum-utils 2>/dev/null || true
      radp_exec_sudo "Add Docker repository" yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo || {
        radp_log_error "Failed to add Docker repository"
        return 1
      }
    fi
    radp_exec_sudo "Install containerd.io" "$pm" install -y containerd.io || return 1
    ;;
  apt)
    # Add Docker repository if not exists
    if [[ ! -f /etc/apt/sources.list.d/docker.list ]]; then
      radp_os_install_pkgs ca-certificates curl || return 1
      radp_exec_sudo "Create keyrings directory" install -m 0755 -d /etc/apt/keyrings
      radp_exec_sudo "Download Docker GPG key" curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
      radp_exec_sudo "Set permissions on GPG key" chmod a+r /etc/apt/keyrings/docker.asc

      # shellcheck disable=SC1091
      source /etc/os-release
      if radp_dry_run_skip "Add Docker apt repository"; then
        : # skip
      else
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/${ID} ${VERSION_CODENAME} stable" |
          $gr_sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
      fi
    fi
    radp_exec_sudo "Update apt cache" apt-get update || return 1
    radp_exec_sudo "Install containerd.io" apt-get install -y containerd.io || return 1
    ;;
  *)
    return 1
    ;;
  esac

  return 0
}

#######################################
# Configure containerd with systemd cgroup driver
# This is required for Kubernetes compatibility
# Returns:
#   0 - Success
#   1 - Failure
#######################################
_setup_containerd_configure_cgroup() {
  radp_log_info "Configuring containerd with systemd cgroup driver..."

  if radp_dry_run_skip "Configure containerd cgroup driver"; then
    return 0
  fi

  # Create config directory
  $gr_sudo mkdir -p /etc/containerd || return 1

  # Generate default config and modify it
  containerd config default | $gr_sudo tee /etc/containerd/config.toml >/dev/null || {
    radp_log_error "Failed to generate containerd config"
    return 1
  }

  # Enable systemd cgroup driver
  $gr_sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml || {
    radp_log_warn "Could not enable SystemdCgroup in config"
  }

  return 0
}
