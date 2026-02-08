#!/usr/bin/env bash
# @cmd
# @desc Install GitLab Runner
# @option -v, --version <ver> GitLab Runner version (default: latest)
# @flag --dry-run Show what would be done
# @example gitlab runner install
# @example gitlab runner install -v 17.0.0
# @example gitlab runner install --dry-run

cmd_gitlab_runner_install() {
  local version="${opt_version:-latest}"

  # Enable dry-run mode if flag is set
  radp_set_dry_run "${opt_dry_run:-false}"

  # Check if already installed
  if _gitlab_runner_is_installed; then
    local runner_version
    runner_version=$(_gitlab_runner_get_version)
    radp_log_info "GitLab Runner is already installed"
    radp_log_info "  Version: $runner_version"

    # If user requested latest, nothing more to do
    if [[ "$version" == "latest" ]]; then
      gitlab-runner status 2>/dev/null || true
      return 0
    fi

    # Specific version requested — proceed to install/upgrade
    radp_log_info "Requested version: $version (proceeding with install)"
  fi

  radp_log_info "Installing GitLab Runner..."

  # Add repository (idempotent — skips if already present)
  _gitlab_runner_add_repo || return 1

  # Install package (auto-detects PM, falls back to binary)
  _gitlab_runner_install_package "$version" || return 1

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
