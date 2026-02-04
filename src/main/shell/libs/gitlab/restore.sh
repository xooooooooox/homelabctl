#!/usr/bin/env bash
# GitLab restore functions

#######################################
# Restore GitLab data from backup
# Arguments:
#   1 - backup_file: Path to backup file (optional, uses latest if not specified)
#   --source <path>  Source directory to search for backups
#   --force          Skip confirmation prompts
# Returns:
#   0 on success, 1 on failure
#######################################
_gitlab_restore_data() {
  local backup_file="" source_dir="" force=""

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --source) source_dir="$2"; shift 2 ;;
      --force) force="true"; shift ;;
      -*) shift ;;
      *)
        if [[ -z "$backup_file" ]]; then
          backup_file="$1"
        fi
        shift
        ;;
    esac
  done

  _gitlab_is_installed || {
    radp_log_error "GitLab is not installed"
    return 1
  }

  # Find backup file if not specified
  if [[ -z "$backup_file" ]]; then
    local backup_home remote_home
    backup_home=$(_gitlab_get_backup_home)
    remote_home=$(_gitlab_get_backup_home_remote)

    # Search in specified source, local backup dir, and remote dir
    local search_dirs=()
    [[ -n "$source_dir" && -d "$source_dir" ]] && search_dirs+=("$source_dir")
    [[ -d "$backup_home" ]] && search_dirs+=("$backup_home")
    [[ -n "$remote_home" && -d "$remote_home" ]] && search_dirs+=("$remote_home")

    for dir in "${search_dirs[@]}"; do
      local found
      found=$(_gitlab_find_latest_data_backup --source "$dir")
      if [[ -n "$found" ]]; then
        if [[ -z "$backup_file" ]] || [[ "$found" -nt "$backup_file" ]]; then
          backup_file="$found"
        fi
      fi
    done
  fi

  if [[ -z "$backup_file" ]]; then
    radp_log_error "No data backup file found"
    return 1
  fi

  if [[ ! -f "$backup_file" ]]; then
    radp_log_error "Backup file not found: $backup_file"
    return 1
  fi

  # Confirm restore
  if [[ -z "$force" ]]; then
    radp_log_warn "This will restore GitLab data from: $backup_file"
    radp_log_warn "WARNING: This will remove all current data!"
    if ! radp_io_prompt_confirm --msg "Continue? (y/N)" --default N --level warn --timeout 600; then
      radp_log_info "Restore cancelled"
      return 1
    fi
  fi

  # Skip in dry-run mode after confirmation
  if radp_dry_run_skip "Restore GitLab data from $backup_file"; then
    return 0
  fi

  # Extract BACKUP parameter from filename
  local backup_name restore_param
  backup_name=$(basename "$backup_file")
  restore_param=${backup_name%%_gitlab_*}

  radp_log_info "Restore parameter: BACKUP=$restore_param"

  # Copy backup to local backup directory if needed
  local backup_home
  backup_home=$(_gitlab_get_backup_home)
  local local_backup_path="${backup_home}/$(basename "$backup_file")"

  if [[ "$backup_file" != "$local_backup_path" ]]; then
    radp_log_info "Copying backup to local backup directory..."
    $gr_sudo cp -v "$backup_file" "$backup_home/" || return 1
  fi

  # Set proper permissions
  $gr_sudo chown git:git "$local_backup_path" || return 1
  $gr_sudo chmod 644 "$local_backup_path" || return 1

  # Stop database services
  radp_log_info "Stopping puma and sidekiq..."
  _gitlab_stop puma || return 1
  _gitlab_stop sidekiq || return 1

  # Restore (auto-confirm with printf)
  radp_log_info "Restoring GitLab data (this may take a while)..."
  radp_log_info "Note: You may see 'ERROR: must be owner of extension pg_trgm' - this can be ignored"

  printf 'yes\nyes\n' | $gr_sudo gitlab-backup restore BACKUP="$restore_param" || {
    radp_log_error "Failed to restore GitLab data"
    return 1
  }

  radp_log_info "GitLab data restored successfully"
  return 0
}

#######################################
# Restore GitLab config from backup
# Arguments:
#   1 - backup_file: Path to backup file (optional, uses latest if not specified)
#   --source <path>  Source directory to search for backups
#   --force          Skip confirmation prompts
# Returns:
#   0 on success, 1 on failure
#######################################
_gitlab_restore_config() {
  local backup_file="" source_dir="" force=""

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --source) source_dir="$2"; shift 2 ;;
      --force) force="true"; shift ;;
      -*) shift ;;
      *)
        if [[ -z "$backup_file" ]]; then
          backup_file="$1"
        fi
        shift
        ;;
    esac
  done

  _gitlab_is_installed || {
    radp_log_error "GitLab is not installed"
    return 1
  }

  # Find backup file if not specified
  if [[ -z "$backup_file" ]]; then
    local config_backup_home remote_home
    config_backup_home=$(_gitlab_get_config_backup_home)
    remote_home=$(_gitlab_get_backup_home_remote)

    local search_dirs=()
    [[ -n "$source_dir" && -d "$source_dir" ]] && search_dirs+=("$source_dir")
    [[ -d "$config_backup_home" ]] && search_dirs+=("$config_backup_home")
    [[ -n "$remote_home" && -d "$remote_home" ]] && search_dirs+=("$remote_home")

    for dir in "${search_dirs[@]}"; do
      local found
      found=$(_gitlab_find_latest_config_backup --source "$dir")
      if [[ -n "$found" ]]; then
        if [[ -z "$backup_file" ]] || [[ "$found" -nt "$backup_file" ]]; then
          backup_file="$found"
        fi
      fi
    done
  fi

  if [[ -z "$backup_file" ]]; then
    radp_log_error "No config backup file found"
    return 1
  fi

  if [[ ! -f "$backup_file" ]]; then
    radp_log_error "Backup file not found: $backup_file"
    return 1
  fi

  # Confirm restore
  if [[ -z "$force" ]]; then
    radp_log_warn "This will restore GitLab config from: $backup_file"
    if ! radp_io_prompt_confirm --msg "Continue? (y/N)" --default N --level warn --timeout 600; then
      radp_log_info "Restore cancelled"
      return 1
    fi
  fi

  # Skip in dry-run mode after confirmation
  if radp_dry_run_skip "Restore GitLab config from $backup_file"; then
    return 0
  fi

  # Extract to temp directory
  local tmp_dir
  tmp_dir=$(mktemp -d)
  radp_log_info "Extracting config backup to $tmp_dir..."

  $gr_sudo tar -xvf "$backup_file" -C "$tmp_dir" || {
    rm -rf "$tmp_dir"
    radp_log_error "Failed to extract config backup"
    return 1
  }

  local config_home today
  config_home=$(_gitlab_get_config_home)
  today=$(_gitlab_get_today)

  # Restore individual config items with confirmation
  _gitlab_restore_config_item "$tmp_dir" "gitlab-secrets.json" "$force" || true
  _gitlab_restore_config_item "$tmp_dir" "gitlab.rb" "$force" || true
  _gitlab_restore_config_item "$tmp_dir" "trusted-certs" "$force" || true

  # Cleanup
  rm -rf "$tmp_dir"

  # Reconfigure and restart
  radp_log_info "Reconfiguring GitLab..."
  _gitlab_reconfigure || return 1

  radp_log_info "Restarting GitLab..."
  _gitlab_restart || return 1

  # Wait for services to start
  radp_log_info "Waiting for GitLab to start (sleeping 300 seconds)..."
  sleep 300

  # Run health check
  radp_log_info "Running health check..."
  _gitlab_healthcheck --verbose --secrets || {
    radp_log_warn "Health check found issues - please review"
  }

  radp_log_info "GitLab config restored successfully"
  return 0
}

#######################################
# Restore a single config item
# Arguments:
#   1 - tmp_dir: Temporary directory with extracted backup
#   2 - item: Config item name (gitlab-secrets.json, gitlab.rb, trusted-certs)
#   3 - force: Skip confirmation if "true"
# Returns:
#   0 on success, 1 on skip or failure
#######################################
_gitlab_restore_config_item() {
  local tmp_dir="${1:?}"
  local item="${2:?}"
  local force="${3:-}"

  local config_home today
  config_home=$(_gitlab_get_config_home)
  today=$(_gitlab_get_today)

  local src_path="${tmp_dir}${config_home}/${item}"
  local dst_path="${config_home}/${item}"

  # Check if source exists
  if [[ ! -e "$src_path" ]]; then
    radp_log_debug "Config item not found in backup: $item"
    return 1
  fi

  # Confirm unless forced
  if [[ -z "$force" ]]; then
    if ! radp_io_prompt_confirm --msg "Restore $item? (y/N)" --default N --level warn --timeout 300; then
      radp_log_info "Skipped $item"
      return 1
    fi
  fi

  # Backup current config
  if [[ -e "$dst_path" ]]; then
    if [[ -d "$dst_path" ]]; then
      $gr_sudo mkdir -p "${config_home}/${item}.backup/$today"
      $gr_sudo cp -rv "$dst_path" "${config_home}/${item}.backup/$today/" || return 1
    else
      $gr_sudo cp -v "$dst_path" "${dst_path}.bak_$today" || return 1
    fi
  fi

  # Restore
  if [[ -d "$src_path" ]]; then
    $gr_sudo cp -rv "$src_path" "$config_home/" || return 1
  else
    $gr_sudo cp -v "$src_path" "$config_home/" || return 1
  fi

  radp_log_info "Restored $item"
  return 0
}

#######################################
# Full restore (data + config)
# Arguments:
#   --data-file <path>    Data backup file
#   --config-file <path>  Config backup file
#   --source <path>       Source directory
#   --force               Skip confirmations
# Returns:
#   0 on success, 1 on failure
#######################################
_gitlab_restore_all() {
  local data_file="" config_file="" source_dir="" force=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --data-file) data_file="$2"; shift 2 ;;
      --config-file) config_file="$2"; shift 2 ;;
      --source) source_dir="$2"; shift 2 ;;
      --force) force="--force"; shift ;;
      *) shift ;;
    esac
  done

  local args=()
  [[ -n "$source_dir" ]] && args+=(--source "$source_dir")
  [[ -n "$force" ]] && args+=("$force")

  # Restore data first
  radp_log_info "=== Restoring Data ==="
  _gitlab_restore_data "$data_file" "${args[@]}" || return 1

  # Then restore config
  radp_log_info "=== Restoring Config ==="
  _gitlab_restore_config "$config_file" "${args[@]}" || return 1

  radp_log_info "Full restore completed"
  return 0
}
