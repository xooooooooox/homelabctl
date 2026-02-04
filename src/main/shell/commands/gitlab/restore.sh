#!/usr/bin/env bash
# @cmd
# @desc Restore GitLab data and/or configuration from backup
# @arg backup_file Backup file path (optional, uses latest if not specified)
# @option --type <type> Restore type: all, data, config (default: all)
# @option --source <path> Source directory to search for backups
# @flag --force Skip confirmation prompts
# @flag --dry-run Show what would be done
# @example gitlab restore
# @example gitlab restore --type data
# @example gitlab restore --type config
# @example gitlab restore /path/to/backup.tar --force
# @example gitlab restore --source /mnt/nas/backups

cmd_gitlab_restore() {
  local backup_file="${1:-}"
  local restore_type="${opt_type:-all}"
  local source_dir="${opt_source:-}"
  local force="${opt_force:-}"

  # Enable dry-run mode if flag is set
  radp_set_dry_run "${opt_dry_run:-}"

  # Check if GitLab is installed
  if ! _gitlab_is_installed; then
    radp_log_error "GitLab is not installed"
    return 1
  fi

  # Prepare common args
  local args=()
  [[ -n "$source_dir" ]] && args+=(--source "$source_dir")
  [[ -n "$force" ]] && args+=(--force)

  radp_log_info "Restoring GitLab..."
  radp_log_info "  Type: $restore_type"

  # Execute restore based on type
  case "$restore_type" in
    all)
      _gitlab_restore_all \
        ${backup_file:+--data-file "$backup_file"} \
        "${args[@]}" || return 1
      ;;
    data)
      _gitlab_restore_data "$backup_file" "${args[@]}" || return 1

      # Restart after data restore
      radp_log_info "Restarting GitLab..."
      _gitlab_restart || return 1
      ;;
    config)
      _gitlab_restore_config "$backup_file" "${args[@]}" || return 1
      ;;
    *)
      radp_log_error "Invalid restore type: $restore_type (use: all, data, config)"
      return 1
      ;;
  esac

  radp_log_info ""
  radp_log_info "Restore completed!"
  radp_log_info ""
  radp_log_info "Run 'homelabctl gitlab healthcheck --verbose' to verify"

  return 0
}
