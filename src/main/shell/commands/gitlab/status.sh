#!/usr/bin/env bash
# @cmd
# @desc Show GitLab status and version info
# @flag --services Show all service status details
# @example gitlab status
# @example gitlab status --services

cmd_gitlab_status() {
  local show_services="${opt_services:-}"

  # Check if GitLab is installed
  if ! _gitlab_is_installed; then
    radp_log_info "GitLab Status: NOT INSTALLED"
    radp_log_info ""
    radp_log_info "Run 'homelabctl gitlab install' to install GitLab"
    return 0
  fi

  # Get version and type
  local version type
  version=$(_gitlab_get_version 2>/dev/null || echo "unknown")
  type=$(_gitlab_get_type 2>/dev/null || echo "unknown")

  # Get paths
  local config_home data_home backup_home
  config_home=$(_gitlab_get_config_home)
  data_home=$(_gitlab_get_data_home)
  backup_home=$(_gitlab_get_backup_home)

  echo "=== GitLab Status ==="
  echo ""
  echo "Installation:"
  echo "  Type:    $type"
  echo "  Version: $version"
  echo ""
  echo "Directories:"
  echo "  Config:  $config_home"
  echo "  Data:    $data_home"
  echo "  Backup:  $backup_home"

  # Show remote backup location if configured
  local remote_home
  remote_home=$(_gitlab_get_backup_home_remote)
  if [[ -n "$remote_home" ]]; then
    echo "  Remote:  $remote_home"
  fi

  echo ""

  # Check service status
  if _gitlab_is_running; then
    echo "Services: RUNNING"
  else
    echo "Services: STOPPED"
  fi

  # Show detailed service status if requested
  if [[ -n "$show_services" ]]; then
    echo ""
    echo "=== Service Details ==="
    _gitlab_status 2>/dev/null || true
  fi

  echo ""

  # Show initial password hint for new installations
  local password_file="${config_home}/initial_root_password"
  if [[ -f "$password_file" ]]; then
    echo "Note: Initial root password file exists (valid for 24h after install)"
    echo "  View with: sudo cat $password_file"
    echo ""
  fi

  # Show recent backup info
  echo "=== Recent Backups ==="
  local latest_data latest_config
  latest_data=$(_gitlab_find_latest_data_backup 2>/dev/null)
  latest_config=$(_gitlab_find_latest_config_backup 2>/dev/null)

  if [[ -n "$latest_data" ]]; then
    local data_size data_date
    data_size=$($gr_sudo ls -lh "$latest_data" 2>/dev/null | awk '{print $5}')
    data_date=$($gr_sudo stat -c %y "$latest_data" 2>/dev/null | cut -d'.' -f1 || \
                $gr_sudo stat -f %Sm "$latest_data" 2>/dev/null)
    echo "  Latest data:   $(basename "$latest_data") ($data_size, $data_date)"
  else
    echo "  Latest data:   (none)"
  fi

  if [[ -n "$latest_config" ]]; then
    local config_size config_date
    config_size=$($gr_sudo ls -lh "$latest_config" 2>/dev/null | awk '{print $5}')
    config_date=$($gr_sudo stat -c %y "$latest_config" 2>/dev/null | cut -d'.' -f1 || \
                  $gr_sudo stat -f %Sm "$latest_config" 2>/dev/null)
    echo "  Latest config: $(basename "$latest_config") ($config_size, $config_date)"
  else
    echo "  Latest config: (none)"
  fi

  return 0
}
