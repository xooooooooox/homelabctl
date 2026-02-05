#!/usr/bin/env bash
# GitLab package management functions

# Package repository script URLs (module-internal constants)
declare -gr __gitlab_ce_repo_script_rpm="https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.rpm.sh"
declare -gr __gitlab_ee_repo_script_rpm="https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.rpm.sh"
declare -gr __gitlab_ce_repo_script_deb="https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh"
declare -gr __gitlab_ee_repo_script_deb="https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.deb.sh"

# Backup file patterns (module-internal constants)
declare -gr __gitlab_data_backup_pattern='*_gitlab_backup.tar'
declare -gr __gitlab_config_backup_pattern='gitlab_config_*.tar'

#######################################
# Get GitLab package repository script URL
# Arguments:
#   1 - gitlab_type: gitlab-ce or gitlab-ee
# Outputs:
#   Repository script URL
# Returns:
#   0 on success, 1 on invalid type
#######################################
_gitlab_get_repo_script() {
  local gitlab_type="${1:?'GitLab type required'}"
  local pm
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

  case "$gitlab_type" in
    gitlab-ce)
      case "$pm" in
        dnf|yum) echo "$__gitlab_ce_repo_script_rpm" ;;
        apt|apt-get) echo "$__gitlab_ce_repo_script_deb" ;;
        *)
          radp_log_error "Unsupported package manager: $pm"
          return 1
          ;;
      esac
      ;;
    gitlab-ee)
      case "$pm" in
        dnf|yum) echo "$__gitlab_ee_repo_script_rpm" ;;
        apt|apt-get) echo "$__gitlab_ee_repo_script_deb" ;;
        *)
          radp_log_error "Unsupported package manager: $pm"
          return 1
          ;;
      esac
      ;;
    *)
      radp_log_error "Invalid GitLab type: $gitlab_type (use gitlab-ce or gitlab-ee)"
      return 1
      ;;
  esac
}

#######################################
# Get latest available GitLab package version
# Arguments:
#   1 - gitlab_type: gitlab-ce or gitlab-ee
# Outputs:
#   Version string (e.g., "17.0.0-ce.0.el9")
# Returns:
#   0 on success, 1 on failure
#######################################
_gitlab_get_latest_version() {
  local gitlab_type="${1:?'GitLab type required'}"
  local pm result
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

  case "$pm" in
    dnf|yum)
      result=$(yum -y --showduplicates list "$gitlab_type" 2>/dev/null | tail -1 | awk '{print $2}')
      ;;
    apt|apt-get)
      result=$(apt-cache madison "$gitlab_type" 2>/dev/null | head -1 | awk '{print $3}')
      ;;
    *)
      radp_log_error "Unsupported package manager: $pm"
      return 1
      ;;
  esac

  if [[ -z "$result" ]]; then
    radp_log_error "Failed to get latest version for $gitlab_type"
    return 1
  fi

  echo "$result"
}

#######################################
# Get full package version matching a pattern
# Arguments:
#   1 - gitlab_type: gitlab-ce or gitlab-ee
#   2 - version_pattern: Version pattern to match (e.g., "17.0")
# Outputs:
#   Full version string
# Returns:
#   0 on success, 1 on failure
#######################################
_gitlab_get_full_version() {
  local gitlab_type="${1:?'GitLab type required'}"
  local version_pattern="${2:?'Version pattern required'}"
  local pm result
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

  case "$pm" in
    dnf|yum)
      result=$(yum -y --showduplicates list "$gitlab_type" 2>/dev/null | grep -v '@' | grep "$version_pattern" | tail -1 | awk '{print $2}')
      ;;
    apt|apt-get)
      result=$(apt-cache madison "$gitlab_type" 2>/dev/null | grep "$version_pattern" | head -1 | awk '{print $3}')
      ;;
    *)
      radp_log_error "Unsupported package manager: $pm"
      return 1
      ;;
  esac

  if [[ -z "$result" ]]; then
    radp_log_error "No version matching '$version_pattern' found for $gitlab_type"
    return 1
  fi

  echo "$result"
}

#######################################
# Check if a specific GitLab version exists in repository
# Arguments:
#   1 - gitlab_type: gitlab-ce or gitlab-ee
#   2 - version: Version to check
# Returns:
#   0 if exists, 1 if not
#######################################
_gitlab_version_exists() {
  local gitlab_type="${1:?'GitLab type required'}"
  local version="${2:?'Version required'}"
  local pm
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

  case "$pm" in
    dnf|yum)
      yum -y --showduplicates list "$gitlab_type" 2>/dev/null | grep -q "$version"
      ;;
    apt|apt-get)
      apt-cache madison "$gitlab_type" 2>/dev/null | grep -q "$version"
      ;;
    *)
      return 1
      ;;
  esac
}

#######################################
# Add GitLab package repository
# Arguments:
#   1 - gitlab_type: gitlab-ce or gitlab-ee
# Returns:
#   0 on success, 1 on failure
#######################################
_gitlab_add_repo() {
  local gitlab_type="${1:?'GitLab type required'}"
  local repo_script

  repo_script=$(_gitlab_get_repo_script "$gitlab_type") || return 1

  radp_log_info "Adding $gitlab_type package repository..."

  # Skip in dry-run mode
  if radp_dry_run_skip "Add $gitlab_type repository from $repo_script"; then
    return 0
  fi

  curl -fsSL "$repo_script" | $gr_sudo bash || {
    radp_log_error "Failed to add $gitlab_type package repository"
    return 1
  }

  radp_log_info "$gitlab_type package repository added"
  return 0
}

#######################################
# Install GitLab package
# Arguments:
#   1 - gitlab_type: gitlab-ce or gitlab-ee
#   2 - version: Version to install (or "latest")
# Returns:
#   0 on success, 1 on failure
#######################################
_gitlab_install_package() {
  local gitlab_type="${1:?'GitLab type required'}"
  local version="${2:-latest}"
  local pm full_version
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

  # Resolve version
  if [[ "$version" == "latest" ]]; then
    full_version=$(_gitlab_get_latest_version "$gitlab_type") || return 1
  else
    full_version=$(_gitlab_get_full_version "$gitlab_type" "$version") || {
      # Try using version directly
      full_version="$version"
    }
  fi

  # Verify version exists
  if ! _gitlab_version_exists "$gitlab_type" "$full_version"; then
    radp_log_error "Version $full_version not found for $gitlab_type"
    return 1
  fi

  radp_log_info "Installing $gitlab_type version $full_version..."

  case "$pm" in
    dnf)
      radp_exec_sudo "Install $gitlab_type-$full_version" dnf install -y "${gitlab_type}-${full_version}" || return 1
      ;;
    yum)
      radp_exec_sudo "Install $gitlab_type-$full_version" yum install -y "${gitlab_type}-${full_version}" || return 1
      ;;
    apt|apt-get)
      radp_exec_sudo "Install $gitlab_type=$full_version" apt-get install -y "${gitlab_type}=${full_version}" || return 1
      ;;
    *)
      radp_log_error "Unsupported package manager: $pm"
      return 1
      ;;
  esac

  radp_log_info "$gitlab_type $full_version installed"
  return 0
}

#######################################
# Install postfix mail server (required by GitLab)
# Returns:
#   0 on success, 1 on failure
#######################################
_gitlab_install_postfix() {
  local pm
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

  # Check if already installed and running
  if _common_is_command_available postfix && systemctl is-active postfix &>/dev/null; then
    radp_log_info "postfix is already installed and running"
    return 0
  fi

  radp_log_info "Installing postfix..."

  # Skip in dry-run mode
  if radp_dry_run_skip "Install and configure postfix"; then
    return 0
  fi

  case "$pm" in
    dnf|yum)
      radp_os_install_pkgs postfix || return 1
      ;;
    apt|apt-get)
      # Set default config to avoid interactive prompts
      echo "postfix postfix/main_mailer_type select Internet Site" | $gr_sudo debconf-set-selections 2>/dev/null || true
      echo "postfix postfix/mailname string $(hostname -f)" | $gr_sudo debconf-set-selections 2>/dev/null || true
      DEBIAN_FRONTEND=noninteractive radp_os_install_pkgs postfix || return 1
      ;;
    *)
      radp_log_warn "Skipping postfix installation on unsupported platform"
      return 0
      ;;
  esac

  # Fix inet_protocols issue on some systems (IPv6 not available)
  # CentOS 9 default postfix config differs from CentOS 7 - it listens on both
  # IPv4 and IPv6 (inet_protocols = all). On systems where IPv6 is not properly
  # configured, this causes "fatal: parameter inet_interfaces: no local interface
  # found for ::1" error. Setting inet_protocols to ipv4 only fixes this issue.
  local postfix_config="/etc/postfix/main.cf"
  if [[ -f "$postfix_config" ]]; then
    if ! grep -q '^inet_protocols = ipv4' "$postfix_config"; then
      if grep -q '^inet_protocols' "$postfix_config"; then
        $gr_sudo sed -i '/^inet_protocols[[:space:]]*=/ s/=.*/= ipv4/' "$postfix_config"
      else
        echo "inet_protocols = ipv4" | $gr_sudo tee -a "$postfix_config" > /dev/null
      fi
    fi
  fi

  # Enable and start postfix
  $gr_sudo systemctl enable postfix 2>/dev/null || true
  $gr_sudo systemctl start postfix || {
    radp_log_error "Failed to start postfix"
    return 1
  }

  radp_log_info "postfix installed and started"
  return 0
}

#######################################
# Get data backup file pattern
# Outputs:
#   Glob pattern for data backup files
#######################################
_gitlab_get_data_backup_pattern() {
  echo "$__gitlab_data_backup_pattern"
}

#######################################
# Get config backup file pattern
# Outputs:
#   Glob pattern for config backup files
#######################################
_gitlab_get_config_backup_pattern() {
  echo "$__gitlab_config_backup_pattern"
}
