#!/usr/bin/env bash
# @cmd
# @desc Install GitLab Runner
# @flag --dry-run Show what would be done
# @example gitlab runner install

cmd_gitlab_runner_install() {
  # Enable dry-run mode if flag is set
  radp_set_dry_run "${opt_dry_run:-}"

  # Check if already installed
  if command -v gitlab-runner &>/dev/null; then
    local runner_version
    runner_version=$(gitlab-runner --version 2>/dev/null | head -1 || echo "unknown")
    radp_log_info "GitLab Runner is already installed"
    radp_log_info "  Version: $runner_version"

    # Show status
    gitlab-runner status 2>/dev/null || true
    return 0
  fi

  # Get package manager
  local pm
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

  radp_log_info "Installing GitLab Runner..."

  case "$pm" in
    dnf|yum)
      # Add repository
      radp_log_info "Adding GitLab Runner repository..."
      if radp_dry_run_skip "Add GitLab Runner repository"; then
        :
      else
        curl -fsSL "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.rpm.sh" | $gr_sudo bash || {
          radp_log_error "Failed to add GitLab Runner repository"
          return 1
        }
      fi

      # Install
      radp_log_info "Installing gitlab-runner package..."
      radp_exec_sudo "Install gitlab-runner" yum install -y gitlab-runner || {
        radp_log_error "Failed to install gitlab-runner"
        return 1
      }
      ;;

    apt|apt-get)
      # Add repository
      radp_log_info "Adding GitLab Runner repository..."
      if radp_dry_run_skip "Add GitLab Runner repository"; then
        :
      else
        curl -fsSL "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh" | $gr_sudo bash || {
          radp_log_error "Failed to add GitLab Runner repository"
          return 1
        }
      fi

      # Install
      radp_log_info "Installing gitlab-runner package..."
      radp_exec_sudo "Install gitlab-runner" apt-get install -y gitlab-runner || {
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
      # Binary fallback for unsupported package managers
      _gitlab_runner_install_from_binary || {
        radp_log_error "Unsupported package manager: $pm"
        radp_log_info "Please install GitLab Runner manually"
        radp_log_info "See: https://docs.gitlab.com/runner/install/"
        return 1
      }
      ;;
  esac

  # Verify installation (skip in dry-run)
  if ! radp_is_dry_run; then
    radp_log_info "Verifying installation..."
    gitlab-runner status || {
      radp_log_error "GitLab Runner installation verification failed"
      return 1
    }
  fi

  radp_log_info ""
  radp_log_info "GitLab Runner installed successfully!"
  radp_log_info ""
  radp_log_info "Next steps:"
  radp_log_info "  1. Register the runner with your GitLab instance:"
  radp_log_info "     sudo gitlab-runner register"
  radp_log_info ""
  radp_log_info "  2. For more information, see:"
  radp_log_info "     https://docs.gitlab.com/runner/register/"

  return 0
}

#######################################
# Install GitLab Runner from binary
# Downloads pre-built binary from GitLab
# Returns:
#   0 on success, 1 on failure
#######################################
_gitlab_runner_install_from_binary() {
  radp_log_info "Installing GitLab Runner from binary..."

  local arch os
  arch=$(radp_os_get_distro_arch 2>/dev/null || uname -m)
  os=$(radp_os_get_distro_os 2>/dev/null || uname -s)
  os="${os,,}"

  # Normalize architecture
  case "$arch" in
    x86_64|amd64) arch="amd64" ;;
    aarch64|arm64) arch="arm64" ;;
    *)
      radp_log_error "Unsupported architecture: $arch"
      return 1
      ;;
  esac

  local download_url="https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-${os}-${arch}"

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
