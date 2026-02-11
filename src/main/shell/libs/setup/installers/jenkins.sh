#!/usr/bin/env bash
# jenkins installer

#######################################
# Install Jenkins LTS
# Arguments:
#   1 - version: Version to install (default: latest)
# Returns:
#   0 - Success
#   1 - Failure
#######################################
_setup_install_jenkins() {
  local version="${1:-latest}"

  if _setup_is_installed jenkins || _setup_is_installed jenkins-lts; then
    if [[ "$version" == "latest" ]]; then
      radp_log_info "jenkins is already installed"
      return 0
    fi
  fi

  local pm
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

  case "$pm" in
  brew)
    radp_log_info "Installing Jenkins LTS via Homebrew..."
    radp_exec "Install Jenkins LTS via Homebrew" brew install jenkins-lts || return 1
    ;;
  dnf | yum)
    _setup_jenkins_from_official_repo "$pm"
    ;;
  apt | apt-get)
    _setup_jenkins_from_official_repo "apt"
    ;;
  *)
    _setup_jenkins_from_war "$version"
    ;;
  esac

  # Post-install: enable and start the service on Linux
  if _common_is_command_available systemctl; then
    radp_exec_sudo "Enable Jenkins service" systemctl enable jenkins 2>/dev/null || true
    radp_exec_sudo "Start Jenkins service" systemctl start jenkins 2>/dev/null || true
  fi

  radp_log_info "Jenkins installed successfully"
  radp_log_info "Jenkins UI: http://localhost:8080"
  if [[ -f /var/lib/jenkins/secrets/initialAdminPassword ]]; then
    radp_log_info "Initial admin password: /var/lib/jenkins/secrets/initialAdminPassword"
  fi
}

#######################################
# Uninstall Jenkins
# Arguments:
#   1 - purge: If non-empty, also remove configuration files
# Returns:
#   0 - Success
#   1 - Failure
#######################################
_setup_uninstall_jenkins() {
  local purge="${1:-}"

  if ! _setup_is_installed jenkins && ! _setup_is_installed jenkins-lts; then
    radp_log_info "jenkins is not installed"
    return 0
  fi

  local pm
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

  radp_log_info "Uninstalling Jenkins..."

  # Stop services first
  if _common_is_command_available systemctl; then
    radp_exec_sudo "Stop Jenkins service" systemctl stop jenkins 2>/dev/null || true
    radp_exec_sudo "Disable Jenkins service" systemctl disable jenkins 2>/dev/null || true
  fi

  case "$pm" in
  brew)
    radp_log_info "Uninstalling Jenkins LTS via Homebrew..."
    radp_exec "Uninstall Jenkins LTS via Homebrew" brew uninstall jenkins-lts 2>/dev/null || true
    ;;
  dnf)
    radp_exec_sudo "Remove Jenkins via dnf" dnf remove -y jenkins 2>/dev/null || true
    ;;
  yum)
    radp_exec_sudo "Remove Jenkins via yum" yum remove -y jenkins 2>/dev/null || true
    ;;
  apt | apt-get)
    if [[ -n "$purge" ]]; then
      radp_exec_sudo "Purge Jenkins via apt" apt-get purge -y jenkins 2>/dev/null || true
    else
      radp_exec_sudo "Remove Jenkins via apt" apt-get remove -y jenkins 2>/dev/null || true
    fi
    radp_exec_sudo "Autoremove unused packages" apt-get autoremove -y 2>/dev/null || true
    ;;
  *)
    # WAR file fallback cleanup
    radp_exec_sudo "Remove /usr/local/bin/jenkins" rm -f /usr/local/bin/jenkins 2>/dev/null || true
    radp_exec_sudo "Remove /opt/jenkins" rm -rf /opt/jenkins 2>/dev/null || true
    ;;
  esac

  # Remove configuration files if purge is requested
  if [[ -n "$purge" ]]; then
    radp_log_info "Removing Jenkins configuration and data..."
    radp_exec_sudo "Remove /var/lib/jenkins" rm -rf /var/lib/jenkins 2>/dev/null || true
    radp_exec_sudo "Remove /var/log/jenkins" rm -rf /var/log/jenkins 2>/dev/null || true
    radp_exec_sudo "Remove /var/cache/jenkins" rm -rf /var/cache/jenkins 2>/dev/null || true
    radp_exec_sudo "Remove /opt/jenkins" rm -rf /opt/jenkins 2>/dev/null || true

    # Remove repo files and GPG keys
    radp_exec_sudo "Remove Jenkins apt source" rm -f /etc/apt/sources.list.d/jenkins.list 2>/dev/null || true
    radp_exec_sudo "Remove Jenkins GPG keyring" rm -f /usr/share/keyrings/jenkins-keyring.asc 2>/dev/null || true
    radp_exec_sudo "Remove Jenkins yum repo" rm -f /etc/yum.repos.d/jenkins.repo 2>/dev/null || true

    # Reload systemd if service files were removed
    if _common_is_command_available systemctl; then
      radp_exec_sudo "Reload systemd daemon" systemctl daemon-reload 2>/dev/null || true
    fi
  fi

  radp_log_info "Jenkins uninstalled successfully"
  return 0
}

#######################################
# Install Jenkins from official package repository
# Handles dnf/yum and apt repo setup
# Arguments:
#   1 - package manager (dnf, yum, or apt)
# Returns:
#   0 - Success
#   1 - Failure
#######################################
_setup_jenkins_from_official_repo() {
  local pm="$1"

  case "$pm" in
  dnf | yum)
    radp_log_info "Installing Jenkins LTS via official $pm repo..."
    radp_exec_sudo "Add Jenkins LTS repo" "$pm" config-manager --add-repo https://pkg.jenkins.io/redhat-stable/jenkins.repo 2>/dev/null ||
      {
        # Fallback: manually write the repo file
        if radp_dry_run_skip "Add Jenkins LTS yum repository"; then
          : # skip
        else
          cat <<'REPO' | $gr_sudo tee /etc/yum.repos.d/jenkins.repo >/dev/null
[jenkins]
name=Jenkins-stable
baseurl=https://pkg.jenkins.io/redhat-stable
gpgcheck=1
gpgkey=https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
REPO
        fi
      }
    radp_exec_sudo "Import Jenkins GPG key" rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key 2>/dev/null || true
    radp_exec_sudo "Install Jenkins" "$pm" install -y jenkins || return 1
    ;;
  apt)
    radp_log_info "Installing Jenkins LTS via official apt repo..."
    radp_os_install_pkgs ca-certificates curl gnupg || return 1

    # Add Jenkins GPG key
    radp_exec_sudo "Create keyrings directory" install -m 0755 -d /usr/share/keyrings
    radp_exec_sudo "Download Jenkins GPG key" curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key -o /usr/share/keyrings/jenkins-keyring.asc
    radp_exec_sudo "Set permissions on GPG key" chmod a+r /usr/share/keyrings/jenkins-keyring.asc

    # Add apt repo
    if radp_dry_run_skip "Add Jenkins apt repository"; then
      : # skip
    else
      echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" |
        $gr_sudo tee /etc/apt/sources.list.d/jenkins.list >/dev/null
    fi
    radp_exec_sudo "Update apt cache" apt-get update
    radp_exec_sudo "Install Jenkins" apt-get install -y jenkins || return 1
    ;;
  esac
}

#######################################
# Install Jenkins from WAR file (fallback)
# Downloads the LTS WAR file and creates a wrapper script
# Arguments:
#   1 - version (default: latest)
# Returns:
#   0 - Success
#   1 - Failure
#######################################
_setup_jenkins_from_war() {
  local version="${1:-latest}"

  radp_log_info "Installing Jenkins LTS via WAR file..."

  local war_url
  if [[ "$version" == "latest" ]]; then
    war_url="https://get.jenkins.io/war-stable/latest/jenkins.war"
  else
    war_url="https://get.jenkins.io/war-stable/${version}/jenkins.war"
  fi

  radp_exec_sudo "Create /opt/jenkins directory" mkdir -p /opt/jenkins || return 1

  local tmpdir
  tmpdir=$(_setup_mktemp_dir)
  trap 'rm -rf "$tmpdir"; trap - RETURN' RETURN

  radp_io_download "$war_url" "$tmpdir/jenkins.war" || return 1
  radp_exec_sudo "Install jenkins.war to /opt/jenkins" cp "$tmpdir/jenkins.war" /opt/jenkins/jenkins.war || return 1

  # Create wrapper script
  if radp_dry_run_skip "Create /usr/local/bin/jenkins wrapper"; then
    : # skip
  else
    cat <<'WRAPPER' | $gr_sudo tee /usr/local/bin/jenkins >/dev/null
#!/usr/bin/env bash
exec java -jar /opt/jenkins/jenkins.war "$@"
WRAPPER
    $gr_sudo chmod +x /usr/local/bin/jenkins
  fi

  radp_log_info "Jenkins WAR installed to /opt/jenkins/jenkins.war"
}
