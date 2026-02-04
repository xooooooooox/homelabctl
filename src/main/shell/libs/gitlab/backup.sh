#!/usr/bin/env bash
# GitLab backup functions

#######################################
# Create GitLab data backup
# Returns:
#   0 on success, 1 on failure
#######################################
_gitlab_backup_data() {
  _gitlab_is_installed || {
    radp_log_error "GitLab is not installed"
    return 1
  }

  radp_log_info "Creating GitLab data backup..."
  radp_exec_sudo "Create GitLab data backup" gitlab-backup create || {
    radp_log_error "Failed to create GitLab data backup"
    return 1
  }

  radp_log_info "GitLab data backup created"
  return 0
}

#######################################
# Create GitLab config backup
# Returns:
#   0 on success, 1 on failure
#######################################
_gitlab_backup_config() {
  _gitlab_is_installed || {
    radp_log_error "GitLab is not installed"
    return 1
  }

  radp_log_info "Creating GitLab config backup..."
  radp_exec_sudo "Create GitLab config backup" gitlab-ctl backup-etc || {
    radp_log_error "Failed to create GitLab config backup"
    return 1
  }

  radp_log_info "GitLab config backup created"
  return 0
}

#######################################
# Find latest data backup file
# Arguments:
#   --source <path>  Directory to search (optional)
# Outputs:
#   Path to latest backup file
# Returns:
#   0 if found, 1 if not
#######################################
_gitlab_find_latest_data_backup() {
  local source_dir=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --source) source_dir="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  # Default to local backup directory
  source_dir="${source_dir:-$(_gitlab_get_backup_home)}"

  local pattern latest_file
  pattern=$(_gitlab_get_data_backup_pattern)

  latest_file=$($gr_sudo find -L "$source_dir" -type f -name "$pattern" 2>/dev/null | sort | tail -1)

  if [[ -z "$latest_file" ]]; then
    radp_log_debug "No data backup found in $source_dir"
    return 1
  fi

  echo "$latest_file"
}

#######################################
# Find latest config backup file
# Arguments:
#   --source <path>  Directory to search (optional)
# Outputs:
#   Path to latest backup file
# Returns:
#   0 if found, 1 if not
#######################################
_gitlab_find_latest_config_backup() {
  local source_dir=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --source) source_dir="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  # Default to config backup directory
  source_dir="${source_dir:-$(_gitlab_get_config_backup_home)}"

  local pattern latest_file
  pattern=$(_gitlab_get_config_backup_pattern)

  latest_file=$($gr_sudo find -L "$source_dir" -type f -name "$pattern" 2>/dev/null | sort | tail -1)

  if [[ -z "$latest_file" ]]; then
    radp_log_debug "No config backup found in $source_dir"
    return 1
  fi

  echo "$latest_file"
}

#######################################
# Copy backup files to remote location
# Arguments:
#   --data <path>    Data backup file to copy
#   --config <path>  Config backup file to copy
# Returns:
#   0 on success, 1 on failure
#######################################
_gitlab_backup_copy_to_remote() {
  local data_file="" config_file=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --data) data_file="$2"; shift 2 ;;
      --config) config_file="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  local remote_dir
  remote_dir=$(_gitlab_get_backup_home_remote)

  if [[ -z "$remote_dir" ]]; then
    radp_log_debug "No remote backup directory configured, skipping remote copy"
    return 0
  fi

  if [[ ! -d "$remote_dir" ]]; then
    radp_log_warn "Remote backup directory does not exist: $remote_dir"
    return 1
  fi

  local result=0

  if [[ -n "$data_file" && -f "$data_file" ]]; then
    radp_log_info "Copying data backup to remote: $remote_dir"
    radp_exec_sudo "Copy data backup to $remote_dir" cp -v "$data_file" "$remote_dir/" || {
      radp_log_error "Failed to copy data backup to remote"
      result=1
    }
  fi

  if [[ -n "$config_file" && -f "$config_file" ]]; then
    radp_log_info "Copying config backup to remote: $remote_dir"
    radp_exec_sudo "Copy config backup to $remote_dir" cp -v "$config_file" "$remote_dir/" || {
      radp_log_error "Failed to copy config backup to remote"
      result=1
    }
  fi

  return $result
}

#######################################
# Clean old backup files
# Arguments:
#   --keep-days <n>  Number of days to keep (default: from config)
# Returns:
#   0 on success
#######################################
_gitlab_backup_cleanup() {
  local keep_days=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --keep-days) keep_days="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  keep_days="${keep_days:-$(_gitlab_get_backup_keep_days)}"

  local backup_home config_backup_home remote_home
  backup_home=$(_gitlab_get_backup_home)
  config_backup_home=$(_gitlab_get_config_backup_home)
  remote_home=$(_gitlab_get_backup_home_remote)

  radp_log_info "Cleaning backups older than $keep_days days..."

  local data_pattern config_pattern
  data_pattern=$(_gitlab_get_data_backup_pattern)
  config_pattern=$(_gitlab_get_config_backup_pattern)

  # Clean local data backups
  if [[ -d "$backup_home" ]]; then
    radp_exec_sudo "Clean old data backups in $backup_home" \
      find "$backup_home" -type f -name "$data_pattern" -mtime "+$keep_days" -delete
  fi

  # Clean local config backups
  if [[ -d "$config_backup_home" ]]; then
    radp_exec_sudo "Clean old config backups in $config_backup_home" \
      find "$config_backup_home" -type f -name "$config_pattern" -mtime "+$keep_days" -delete
  fi

  # Clean remote backups
  if [[ -n "$remote_home" && -d "$remote_home" ]]; then
    radp_exec "Clean old backups in remote $remote_home" \
      find "$remote_home" -type f \( -name "$data_pattern" -o -name "$config_pattern" \) -mtime "+$keep_days" -delete
  fi

  radp_log_info "Backup cleanup completed"
  return 0
}

#######################################
# List all backup files
# Arguments:
#   --type <all|data|config>  Type of backups to list
# Outputs:
#   List of backup files with sizes and dates
#######################################
_gitlab_backup_list() {
  local type="all"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --type) type="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  local backup_home config_backup_home remote_home
  backup_home=$(_gitlab_get_backup_home)
  config_backup_home=$(_gitlab_get_config_backup_home)
  remote_home=$(_gitlab_get_backup_home_remote)

  local data_pattern config_pattern
  data_pattern=$(_gitlab_get_data_backup_pattern)
  config_pattern=$(_gitlab_get_config_backup_pattern)

  if [[ "$type" == "all" || "$type" == "data" ]]; then
    echo "=== Data Backups ==="
    if [[ -d "$backup_home" ]]; then
      echo "Local ($backup_home):"
      $gr_sudo ls -lh "$backup_home"/$data_pattern 2>/dev/null || echo "  (none)"
    fi
    if [[ -n "$remote_home" && -d "$remote_home" ]]; then
      echo "Remote ($remote_home):"
      ls -lh "$remote_home"/$data_pattern 2>/dev/null || echo "  (none)"
    fi
    echo
  fi

  if [[ "$type" == "all" || "$type" == "config" ]]; then
    echo "=== Config Backups ==="
    if [[ -d "$config_backup_home" ]]; then
      echo "Local ($config_backup_home):"
      $gr_sudo ls -lh "$config_backup_home"/$config_pattern 2>/dev/null || echo "  (none)"
    fi
    if [[ -n "$remote_home" && -d "$remote_home" ]]; then
      echo "Remote ($remote_home):"
      ls -lh "$remote_home"/$config_pattern 2>/dev/null || echo "  (none)"
    fi
  fi
}
