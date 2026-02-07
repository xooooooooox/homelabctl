#!/usr/bin/env bash
# @cmd
# @desc Install GitLab (gitlab-ce or gitlab-ee) via linux_package
# @option -t, --type <type> GitLab type: gitlab-ce or gitlab-ee (default: gitlab-ce)
# @option -v, --version <ver> GitLab version (default: latest)
# @option --data-dir <path> Custom data directory (symlink target)
# @flag --skip-postfix Skip postfix installation
# @flag --dry-run Show what would be done
# @example gitlab install
# @example gitlab install -t gitlab-ee
# @example gitlab install -t gitlab-ce -v 17.0

cmd_gitlab_install() {
  local gitlab_type="${opt_type:-$(_gitlab_get_default_type)}"
  local version="${opt_version:-$(_gitlab_get_default_version)}"
  local data_dir="${opt_data_dir:-}"
  local skip_postfix="${opt_skip_postfix:-}"

  # Enable dry-run mode if flag is set
  radp_set_dry_run "${opt_dry_run:-}"

  # Check if already installed
  if _gitlab_is_installed; then
    local current_version current_type
    current_version=$(_gitlab_get_version)
    current_type=$(_gitlab_get_type)
    radp_log_info "GitLab is already installed"
    radp_log_info "  Type: $current_type"
    radp_log_info "  Version: $current_version"
    return 0
  fi

  radp_log_info "Installing GitLab..."
  radp_log_info "  Type: $gitlab_type"
  radp_log_info "  Version: $version"

  # Step 1: Check system requirements
  _gitlab_check_requirements || return 1

  # Step 2: Disable SELinux and firewalld
  radp_log_info "Configuring system security..."
  radp_os_disable_selinux || return 1
  radp_os_disable_firewalld || return 1

  # Step 3: Install postfix
  if [[ -z "$skip_postfix" ]]; then
    _gitlab_install_postfix || {
      radp_log_warn "Failed to install postfix, continuing anyway..."
    }
  fi

  # Step 4: Add GitLab repository
  _gitlab_add_repo "$gitlab_type" || return 1

  # Step 5: Setup data directory symlink
  # Priority: command line --data-dir > config external_data_dir
  local external_data_dir="${data_dir:-$(_gitlab_get_external_data_dir)}"
  if [[ -n "$external_data_dir" ]]; then
    local default_data_path
    default_data_path=$(_gitlab_get_data_home)
    radp_log_info "Setting up external data directory..."
    radp_exec_sudo "Create data directory" mkdir -p "$external_data_dir/gitlab"
    radp_exec_sudo "Create symlink for data directory" ln -snf "$external_data_dir/gitlab" "$default_data_path"
    radp_log_info "Data directory symlinked: $default_data_path -> $external_data_dir/gitlab"
  fi

  # Step 6: Install GitLab package
  _gitlab_install_package "$gitlab_type" "$version" || return 1

  radp_log_info ""
  radp_log_info "GitLab installed successfully!"
  radp_log_info ""
  radp_log_info "Next steps:"
  radp_log_info "  1. Edit $(_gitlab_get_config_home)/gitlab.rb to configure GitLab"
  radp_log_info "  2. Run 'homelabctl gitlab init' to initialize"
  radp_log_info ""
  radp_log_info "To get initial root password (valid for 24h):"
  radp_log_info "  sudo cat $(_gitlab_get_config_home)/initial_root_password"

  return 0
}
