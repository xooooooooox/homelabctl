#!/usr/bin/env bash
# @cmd
# @desc Create GitLab backup (data and/or configuration)
# @option --target <path> Target directory for backup
# @option --type <type> Backup type: all, data, config (default: all)
# @flag --skip-remote Skip copy to remote/NAS location
# @flag --dry-run Show what would be done
# @example gitlab backup create
# @example gitlab backup create --type data
# @example gitlab backup create --type config --skip-remote

cmd_gitlab_backup_create() {
  local target="${opt_target:-}"
  local backup_type="${opt_type:-all}"
  local skip_remote="${opt_skip_remote:-}"

  radp_set_dry_run "${opt_dry_run:-false}"

  if ! _gitlab_is_installed; then
    radp_log_error "GitLab is not installed"
    return 1
  fi

  radp_log_info "Creating GitLab backup..."
  radp_log_info "  Type: $backup_type"

  local data_backup_file="" config_backup_file=""

  case "$backup_type" in
    all)
      _gitlab_backup_data || return 1
      if ! radp_is_dry_run; then
        data_backup_file=$(_gitlab_find_latest_data_backup)
      fi
      _gitlab_backup_config || return 1
      if ! radp_is_dry_run; then
        config_backup_file=$(_gitlab_find_latest_config_backup)
      fi
      ;;
    data)
      _gitlab_backup_data || return 1
      if ! radp_is_dry_run; then
        data_backup_file=$(_gitlab_find_latest_data_backup)
      fi
      ;;
    config)
      _gitlab_backup_config || return 1
      if ! radp_is_dry_run; then
        config_backup_file=$(_gitlab_find_latest_config_backup)
      fi
      ;;
    *)
      radp_log_error "Invalid backup type: $backup_type (use: all, data, config)"
      return 1
      ;;
  esac

  # Copy to target directory if specified
  if [[ -n "$target" ]]; then
    radp_log_info "Copying backups to target: $target"
    radp_exec_sudo "Create target directory" mkdir -p "$target"
    [[ -n "$data_backup_file" ]] && radp_exec_sudo "Copy data backup to target" cp -v "$data_backup_file" "$target/"
    [[ -n "$config_backup_file" ]] && radp_exec_sudo "Copy config backup to target" cp -v "$config_backup_file" "$target/"
  fi

  # Copy to remote location
  if [[ -z "$skip_remote" ]]; then
    _gitlab_backup_copy_to_remote \
      ${data_backup_file:+--data "$data_backup_file"} \
      ${config_backup_file:+--config "$config_backup_file"}
  fi

  radp_log_info ""
  radp_log_info "Backup completed successfully!"
  [[ -n "$data_backup_file" ]] && radp_log_info "  Data backup: $data_backup_file"
  [[ -n "$config_backup_file" ]] && radp_log_info "  Config backup: $config_backup_file"

  return 0
}
