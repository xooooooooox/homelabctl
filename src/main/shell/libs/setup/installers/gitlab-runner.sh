#!/usr/bin/env bash
# gitlab-runner installer

_setup_install_gitlab_runner() {
  local version="${1:-latest}"

  if _setup_is_installed gitlab-runner && [[ "$version" == "latest" ]]; then
    radp_log_info "gitlab-runner is already installed"
    return 0
  fi

  local pm
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

  case "$pm" in
  brew)
    radp_log_info "Installing gitlab-runner via Homebrew..."
    brew install gitlab-runner || return 1
    ;;
  dnf | yum)
    _setup_gitlab_runner_from_official_repo "$pm"
    ;;
  apt | apt-get)
    _setup_gitlab_runner_from_official_repo "apt"
    ;;
  *)
    _setup_gitlab_runner_from_binary
    ;;
  esac
}

_setup_gitlab_runner_from_official_repo() {
  local pm="$1"

  case "$pm" in
  dnf | yum)
    radp_log_info "Installing gitlab-runner via official rpm repo..."
    curl -fsSL "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.rpm.sh" | $gr_sudo bash || {
      radp_log_error "Failed to add GitLab runner repository"
      return 1
    }
    $gr_sudo "$pm" install -y gitlab-runner || {
      radp_log_error "Failed to install gitlab-runner"
      return 1
    }
    ;;
  apt)
    radp_log_info "Installing gitlab-runner via official deb repo..."
    curl -fsSL "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh" | $gr_sudo bash || {
      radp_log_error "Failed to add GitLab runner repository"
      return 1
    }
    $gr_sudo apt-get install -y gitlab-runner || {
      radp_log_error "Failed to install gitlab-runner"
      return 1
    }
    ;;
  esac

  # Verify installation
  if ! gitlab-runner --version &>/dev/null; then
    radp_log_error "gitlab-runner installation verification failed"
    return 1
  fi

  radp_log_info "gitlab-runner installed successfully"
}

_setup_gitlab_runner_from_binary() {
  radp_log_info "Installing gitlab-runner from binary..."

  local arch os
  arch=$(_setup_get_arch)
  os=$(_setup_get_os)

  # Map architecture for GitLab runner
  case "$arch" in
  amd64) arch="amd64" ;;
  arm64) arch="arm64" ;;
  *)
    radp_log_error "Unsupported architecture: $arch"
    return 1
    ;;
  esac

  local download_url="https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-${os}-${arch}"
  local tmpdir
  tmpdir=$(_setup_mktemp_dir)
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

  radp_log_info "gitlab-runner installed successfully"
}
