#!/usr/bin/env bash
# GitLab Runner package management functions

# Runner repository script URLs (module-internal constants)
declare -gr __gitlab_runner_repo_script_rpm="https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.rpm.sh"
declare -gr __gitlab_runner_repo_script_deb="https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh"

#######################################
# Check if GitLab Runner is installed
# Returns:
#   0 if installed, 1 if not
#######################################
_gitlab_runner_is_installed() {
  _common_is_command_available gitlab-runner
}

#######################################
# Get installed GitLab Runner version
# Outputs:
#   Version string (e.g., "17.0.0")
# Returns:
#   0 on success, 1 if not installed
#######################################
_gitlab_runner_get_version() {
  _gitlab_runner_is_installed || return 1

  local version_line
  version_line=$(gitlab-runner --version 2>/dev/null | head -1 || echo "")
  if [[ -z "$version_line" ]]; then
    echo "unknown"
    return 0
  fi

  echo "$version_line"
}

#######################################
# Get GitLab Runner repository script URL
# Outputs:
#   Repository script URL
# Returns:
#   0 on success, 1 on unsupported PM
#######################################
_gitlab_runner_get_repo_script() {
  local pm
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

  case "$pm" in
    dnf|yum) echo "$__gitlab_runner_repo_script_rpm" ;;
    apt|apt-get) echo "$__gitlab_runner_repo_script_deb" ;;
    *)
      radp_log_error "Unsupported package manager for Runner repository: $pm"
      return 1
      ;;
  esac
}

#######################################
# Check if GitLab Runner repository is already configured
# Returns:
#   0 if repo exists, 1 if not
#######################################
_gitlab_runner_repo_exists() {
  local pm
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

  case "$pm" in
    dnf|yum)
      [[ -f /etc/yum.repos.d/runner_gitlab-runner.repo ]]
      ;;
    apt|apt-get)
      [[ -f /etc/apt/sources.list.d/runner_gitlab-runner.list ]]
      ;;
    *)
      return 1
      ;;
  esac
}

#######################################
# Add GitLab Runner package repository (idempotent)
# Only applies to dnf/yum/apt — skipped for brew and others
# Returns:
#   0 on success (or skipped), 1 on failure
#######################################
_gitlab_runner_add_repo() {
  local pm
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

  # Repository setup only applies to Linux package managers
  case "$pm" in
    dnf|yum|apt|apt-get) ;;
    *) return 0 ;;
  esac

  if _gitlab_runner_repo_exists; then
    radp_log_info "GitLab Runner repository already configured"
    return 0
  fi

  local repo_script
  repo_script=$(_gitlab_runner_get_repo_script) || return 1

  radp_log_info "Adding GitLab Runner repository..."

  if radp_dry_run_skip "Add GitLab Runner repository from $repo_script"; then
    return 0
  fi

  curl -fsSL "$repo_script" | $gr_sudo bash || {
    radp_log_error "Failed to add GitLab Runner repository"
    return 1
  }

  radp_log_info "GitLab Runner repository added"
  return 0
}

#######################################
# Install GitLab Runner package
# Arguments:
#   1 - version: Version to install (or "latest")
# Returns:
#   0 on success, 1 on failure
#######################################
_gitlab_runner_install_package() {
  local version="${1:-latest}"
  local pm
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

  radp_log_info "Installing GitLab Runner package..."

  case "$pm" in
    dnf|yum)
      local yum_pkg="gitlab-runner"
      [[ "$version" != "latest" ]] && yum_pkg="gitlab-runner-${version}"
      radp_log_info "Installing ${yum_pkg}..."
      radp_exec_sudo "Install $yum_pkg" "$pm" install -y "$yum_pkg" || {
        radp_log_error "Failed to install gitlab-runner"
        return 1
      }
      ;;
    apt|apt-get)
      local apt_pkg="gitlab-runner"
      [[ "$version" != "latest" ]] && apt_pkg="gitlab-runner=${version}"
      radp_log_info "Installing ${apt_pkg}..."
      radp_exec_sudo "Install $apt_pkg" apt-get install -y "$apt_pkg" || {
        radp_log_error "Failed to install gitlab-runner"
        return 1
      }
      ;;
    brew)
      radp_log_info "Installing via Homebrew..."
      radp_exec "Install gitlab-runner via Homebrew" brew install gitlab-runner || {
        radp_log_error "Failed to install gitlab-runner via Homebrew"
        return 1
      }
      ;;
    *)
      _gitlab_runner_install_from_binary "$version" || {
        radp_log_error "Unsupported package manager: $pm"
        radp_log_info "Please install GitLab Runner manually"
        radp_log_info "See: https://docs.gitlab.com/runner/install/"
        return 1
      }
      ;;
  esac

  return 0
}

#######################################
# Install GitLab Runner from binary
# Downloads pre-built binary from GitLab
# Arguments:
#   1 - version: Version to install (or "latest")
# Returns:
#   0 on success, 1 on failure
#######################################
_gitlab_runner_install_from_binary() {
  local version="${1:-latest}"

  radp_log_info "Installing GitLab Runner from binary..."

  local arch os
  arch=$(_common_get_arch)
  os=$(_common_get_os)

  # Validate architecture
  case "$arch" in
    amd64|arm64) ;;
    *)
      radp_log_error "Unsupported architecture: $arch"
      return 1
      ;;
  esac

  local version_path="latest"
  [[ "$version" != "latest" ]] && version_path="v${version}"
  local download_url="https://gitlab-runner-downloads.s3.amazonaws.com/${version_path}/binaries/gitlab-runner-${os}-${arch}"

  if radp_dry_run_skip "Download and install gitlab-runner binary"; then
    return 0
  fi

  local tmpdir
  tmpdir=$(radp_io_mktemp_dir "gitlab-runner")
  trap 'rm -rf "$tmpdir"; trap - RETURN' RETURN

  radp_io_download "$download_url" "$tmpdir/gitlab-runner" || {
    radp_log_error "Failed to download gitlab-runner binary"
    return 1
  }

  chmod +x "$tmpdir/gitlab-runner"
  $gr_sudo install -m 0755 "$tmpdir/gitlab-runner" /usr/local/bin/gitlab-runner || {
    radp_log_error "Failed to install gitlab-runner to /usr/local/bin"
    return 1
  }

  radp_log_info "GitLab Runner binary installed successfully"
  return 0
}
