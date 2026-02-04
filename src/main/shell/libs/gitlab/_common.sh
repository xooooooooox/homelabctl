#!/usr/bin/env bash
# GitLab common helper functions
# Sourced by all gitlab commands and libs

#######################################
# Check if GitLab is installed
# Returns:
#   0 if installed, 1 if not
#######################################
_gitlab_is_installed() {
  command -v gitlab-ctl &>/dev/null
}

#######################################
# Check if GitLab services are running
# Returns:
#   0 if running, 1 if not
#######################################
_gitlab_is_running() {
  _gitlab_is_installed || return 1
  $gr_sudo gitlab-ctl status &>/dev/null
}

#######################################
# Get current GitLab version
# Outputs:
#   Version string (e.g., "17.0.0-ce.0")
# Returns:
#   0 on success, 1 if not installed
#######################################
_gitlab_get_version() {
  _gitlab_is_installed || return 1

  # Try gitlab-rake first
  if command -v gitlab-rake &>/dev/null; then
    local version
    version=$($gr_sudo gitlab-rake gitlab:env:info 2>/dev/null | grep -E '^GitLab:' | awk '{print $2}')
    if [[ -n "$version" ]]; then
      echo "$version"
      return 0
    fi
  fi

  # Fallback to package version
  local pm
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

  case "$pm" in
    dnf|yum)
      rpm -q gitlab-ce 2>/dev/null | sed 's/gitlab-ce-//' | sed 's/\.el[0-9]$//' || \
      rpm -q gitlab-ee 2>/dev/null | sed 's/gitlab-ee-//' | sed 's/\.el[0-9]$//'
      ;;
    apt|apt-get)
      dpkg -l gitlab-ce 2>/dev/null | grep '^ii' | awk '{print $3}' || \
      dpkg -l gitlab-ee 2>/dev/null | grep '^ii' | awk '{print $3}'
      ;;
    *)
      return 1
      ;;
  esac
}

#######################################
# Get GitLab type (ce or ee)
# Outputs:
#   "gitlab-ce" or "gitlab-ee"
# Returns:
#   0 on success, 1 if not detected
#######################################
_gitlab_get_type() {
  local pm
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

  case "$pm" in
    dnf|yum)
      if rpm -q gitlab-ee &>/dev/null; then
        echo "gitlab-ee"
      elif rpm -q gitlab-ce &>/dev/null; then
        echo "gitlab-ce"
      else
        return 1
      fi
      ;;
    apt|apt-get)
      if dpkg -l gitlab-ee 2>/dev/null | grep -q '^ii'; then
        echo "gitlab-ee"
      elif dpkg -l gitlab-ce 2>/dev/null | grep -q '^ii'; then
        echo "gitlab-ce"
      else
        return 1
      fi
      ;;
    *)
      return 1
      ;;
  esac
}

#######################################
# Get GitLab config home directory
# Globals:
#   gr_radp_extend_homelabctl_gitlab_config_home
# Outputs:
#   Config directory path
#######################################
_gitlab_get_config_home() {
  echo "${gr_radp_extend_homelabctl_gitlab_config_home:-/etc/gitlab}"
}

#######################################
# Get GitLab data home directory
# Globals:
#   gr_radp_extend_homelabctl_gitlab_data_home
# Outputs:
#   Data directory path
#######################################
_gitlab_get_data_home() {
  echo "${gr_radp_extend_homelabctl_gitlab_data_home:-/var/opt/gitlab}"
}

#######################################
# Get GitLab backup home directory
# Globals:
#   gr_radp_extend_homelabctl_gitlab_backup_home
# Outputs:
#   Backup directory path
#######################################
_gitlab_get_backup_home() {
  echo "${gr_radp_extend_homelabctl_gitlab_backup_home:-/var/opt/gitlab/backups}"
}

#######################################
# Get GitLab config backup home directory
# Globals:
#   gr_radp_extend_homelabctl_gitlab_config_backup_home
# Outputs:
#   Config backup directory path
#######################################
_gitlab_get_config_backup_home() {
  echo "${gr_radp_extend_homelabctl_gitlab_config_backup_home:-/etc/gitlab/config_backup}"
}

#######################################
# Get GitLab remote/NAS backup directory
# Globals:
#   gr_radp_extend_homelabctl_gitlab_backup_home_remote
# Outputs:
#   Remote backup directory path (empty if not configured)
#######################################
_gitlab_get_backup_home_remote() {
  echo "${gr_radp_extend_homelabctl_gitlab_backup_home_remote:-}"
}

#######################################
# Get GitLab default type for installation
# Globals:
#   gr_radp_extend_homelabctl_gitlab_default_type
# Outputs:
#   Default GitLab type (gitlab-ce or gitlab-ee)
#######################################
_gitlab_get_default_type() {
  echo "${gr_radp_extend_homelabctl_gitlab_default_type:-gitlab-ce}"
}

#######################################
# Get GitLab default version
# Globals:
#   gr_radp_extend_homelabctl_gitlab_default_version
# Outputs:
#   Default version string
#######################################
_gitlab_get_default_version() {
  echo "${gr_radp_extend_homelabctl_gitlab_default_version:-latest}"
}

#######################################
# Get backup retention days
# Globals:
#   gr_radp_extend_homelabctl_gitlab_backup_keep_days
# Outputs:
#   Number of days to keep backups
#######################################
_gitlab_get_backup_keep_days() {
  echo "${gr_radp_extend_homelabctl_gitlab_backup_keep_days:-15}"
}

#######################################
# Get backup schedule (cron expression)
# Globals:
#   gr_radp_extend_homelabctl_gitlab_backup_schedule
# Outputs:
#   Cron schedule expression
#######################################
_gitlab_get_backup_schedule() {
  echo "${gr_radp_extend_homelabctl_gitlab_backup_schedule:-0 4 * * *}"
}

#######################################
# Get user config file path
# Globals:
#   gr_radp_extend_homelabctl_gitlab_user_config_file
# Outputs:
#   User config file path (empty if not configured)
#######################################
_gitlab_get_user_config_file() {
  echo "${gr_radp_extend_homelabctl_gitlab_user_config_file:-}"
}

#######################################
# Get minimum CPU cores requirement
# Globals:
#   gr_radp_extend_homelabctl_gitlab_min_cpu_cores
# Outputs:
#   Minimum CPU cores
#######################################
_gitlab_get_min_cpu_cores() {
  echo "${gr_radp_extend_homelabctl_gitlab_min_cpu_cores:-4}"
}

#######################################
# Get minimum RAM requirement in GB
# Globals:
#   gr_radp_extend_homelabctl_gitlab_min_ram_gb
# Outputs:
#   Minimum RAM in GB
#######################################
_gitlab_get_min_ram_gb() {
  echo "${gr_radp_extend_homelabctl_gitlab_min_ram_gb:-4}"
}

#######################################
# Get external data directory (NAS mount point)
# If configured, install will create symlink:
#   {external_data_dir}/gitlab -> /var/opt/gitlab
# Globals:
#   gr_radp_extend_homelabctl_gitlab_external_data_dir
# Outputs:
#   External data directory path (empty if not configured)
#######################################
_gitlab_get_external_data_dir() {
  echo "${gr_radp_extend_homelabctl_gitlab_external_data_dir:-}"
}

#######################################
# Get current date in YYYYMMDD format
# Outputs:
#   Date string
#######################################
_gitlab_get_today() {
  date +%Y%m%d
}

#######################################
# Check system requirements for GitLab
# Arguments:
#   --skip-prompt  Skip confirmation prompt on failure
# Returns:
#   0 if requirements met, 1 if not
#######################################
_gitlab_check_requirements() {
  local skip_prompt=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --skip-prompt) skip_prompt="true"; shift ;;
      *) shift ;;
    esac
  done

  local min_cpu min_ram
  min_cpu=$(_gitlab_get_min_cpu_cores)
  min_ram=$(_gitlab_get_min_ram_gb)

  local failed=""

  if ! radp_os_check_min_cpu_cores "$min_cpu"; then
    failed="true"
  fi

  if ! radp_os_check_min_ram "${min_ram}GB"; then
    failed="true"
  fi

  if [[ -n "$failed" ]]; then
    if [[ -z "$skip_prompt" ]]; then
      radp_log_warn "System does not meet minimum requirements for GitLab"
      if ! radp_io_prompt_confirm --msg "Continue anyway? (y/N)" --default N --timeout 60; then
        return 1
      fi
    else
      return 1
    fi
  fi

  return 0
}
