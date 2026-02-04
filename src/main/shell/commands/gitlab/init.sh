#!/usr/bin/env bash
# @cmd
# @desc Initialize GitLab after installation
# @option --user-config <path> User's custom GitLab config file (e.g., /data/homelab_gitlab.rb)
# @option --backup-schedule <cron> Backup crontab schedule (default: "0 4 * * *")
# @flag --skip-crontab Skip automatic backup crontab setup
# @flag --skip-reconfigure Skip reconfigure and restart (only setup directories and crontab)
# @flag --dry-run Show what would be done
# @example gitlab init
# @example gitlab init --user-config /data/homelab_gitlab.rb
# @example gitlab init --skip-crontab

cmd_gitlab_init() {
  # user_config_file: User's custom config file path (e.g., /data/homelab_gitlab.rb)
  local user_config_file="${opt_user_config:-$(_gitlab_get_user_config_file)}"
  local backup_schedule="${opt_backup_schedule:-$(_gitlab_get_backup_schedule)}"
  local skip_crontab="${opt_skip_crontab:-}"
  local skip_reconfigure="${opt_skip_reconfigure:-}"

  # Enable dry-run mode if flag is set
  radp_set_dry_run "${opt_dry_run:-}"

  # Check if GitLab is installed
  if ! _gitlab_is_installed; then
    radp_log_error "GitLab is not installed"
    radp_log_info "Run 'homelabctl gitlab install' first"
    return 1
  fi

  local gitlab_config_home gitlab_config_backup_home
  gitlab_config_home=$(_gitlab_get_config_home)
  gitlab_config_backup_home=$(_gitlab_get_config_backup_home)

  radp_log_info "Initializing GitLab..."

  # Step 1: Create config backup directory
  radp_log_info "Creating config backup directory..."
  radp_exec_sudo "Create config backup directory" mkdir -pv "$gitlab_config_backup_home"
  radp_exec_sudo "Set permissions on config backup directory" chmod 700 "$gitlab_config_backup_home"

  # Step 2: Save original gitlab.rb as template (before applying user config)
  # gitlab_rb: GitLab default config file /etc/gitlab/gitlab.rb
  local gitlab_rb="${gitlab_config_home}/gitlab.rb"
  if ! radp_is_dry_run && [[ -f "$gitlab_rb" ]]; then
    local installed_version
    installed_version=$(_gitlab_get_version)
    local template_file="${gitlab_rb}.${installed_version}.template"
    if [[ ! -f "$template_file" ]]; then
      radp_log_info "Saving original gitlab.rb as template..."
      radp_exec_sudo "Save config template" cp -v "$gitlab_rb" "$template_file"
    fi
  fi

  # Step 3: Apply user config if specified (directly reference, no copy)
  if [[ -n "$user_config_file" ]]; then
    if [[ ! -f "$user_config_file" ]] && ! radp_is_dry_run; then
      radp_log_error "User config file not found: $user_config_file"
      return 1
    fi

    radp_log_info "Applying user config: $user_config_file"

    # Add from_file directive to gitlab.rb (directly reference user config path)
    local from_file_line="from_file \"$user_config_file\""
    if ! radp_is_dry_run; then
      if ! $gr_sudo grep -qF "from_file" "$gitlab_rb" 2>/dev/null; then
        radp_log_info "Adding from_file directive to gitlab.rb"
        radp_io_append_line_unique "$gitlab_rb" "$from_file_line"
      else
        radp_log_info "from_file directive already exists in gitlab.rb"
      fi
    else
      radp_log_info "[dry-run] Add from_file directive: $from_file_line"
    fi
  fi

  # Step 4: Reconfigure and restart (only if user_config_file specified and not skipped)
  if [[ -n "$user_config_file" ]] && [[ -z "$skip_reconfigure" ]]; then
    radp_log_info "Reconfiguring GitLab..."
    _gitlab_reconfigure || {
      radp_log_error "Failed to reconfigure GitLab"
      radp_log_error "Please check your user config file: $user_config_file"
      return 1
    }

    radp_log_info "Restarting GitLab..."
    _gitlab_restart || {
      radp_log_error "Failed to restart GitLab"
      return 1
    }
  elif [[ -z "$user_config_file" ]]; then
    radp_log_info "No user config file specified, skipping reconfigure/restart"
  fi

  # Step 5: Setup backup crontab
  if [[ -z "$skip_crontab" ]]; then
    radp_log_info "Setting up backup crontab..."
    _setup_backup_crontab "$backup_schedule"
  fi

  radp_log_info ""
  radp_log_info "GitLab initialized successfully!"

  return 0
}

#######################################
# Setup backup crontab
# Arguments:
#   1 - schedule: Cron schedule expression
#######################################
_setup_backup_crontab() {
  local schedule="${1:-0 4 * * *}"
  local keep_days
  keep_days=$(_gitlab_get_backup_keep_days)

  # Skip in dry-run mode
  if radp_dry_run_skip "Setup backup crontab with schedule: $schedule"; then
    return 0
  fi

  # Create crontab content
  local crontab_content
  crontab_content=$(cat <<EOF
# GitLab automatic backup - created by homelabctl gitlab init
# Schedule: $schedule
$schedule $(command -v homelabctl || echo "/usr/local/bin/homelabctl") gitlab backup create --skip-remote 2>&1 | logger -t gitlab-backup

# GitLab backup cleanup - remove backups older than $keep_days days
# Runs weekly on Saturday at 8 PM
0 20 * * 6 $(command -v homelabctl || echo "/usr/local/bin/homelabctl") gitlab backup cleanup --keep-days $keep_days 2>&1 | logger -t gitlab-backup-cleanup
EOF
)

  # Get current user
  local cron_user
  cron_user=$(whoami)

  # For root operations, use root crontab
  if [[ -n "${gr_sudo:-}" ]] || [[ "$EUID" -eq 0 ]]; then
    cron_user="root"
  fi

  radp_log_info "Adding backup crontab for user: $cron_user"
  radp_log_debug "Crontab content:"
  radp_log_debug "$crontab_content"

  # Create temp file with crontab
  local tmp_crontab
  tmp_crontab=$(mktemp)
  echo "$crontab_content" > "$tmp_crontab"

  # Add to crontab
  radp_os_crontab_add "$cron_user" "$tmp_crontab" || {
    rm -f "$tmp_crontab"
    radp_log_warn "Failed to setup backup crontab"
    return 1
  }

  rm -f "$tmp_crontab"
  radp_log_info "Backup crontab configured: $schedule"
  return 0
}
