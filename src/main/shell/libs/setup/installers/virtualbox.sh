#!/usr/bin/env bash
# virtualbox installer
# Cross-platform virtualization software

_setup_install_virtualbox() {
  local version="${1:-latest}"

  if _setup_is_installed VBoxManage && [[ "$version" == "latest" ]]; then
    radp_log_info "VirtualBox is already installed"
    return 0
  fi

  local pm
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

  case "$pm" in
  brew)
    radp_log_info "Installing VirtualBox via Homebrew..."
    brew install --cask virtualbox || return 1
    ;;
  dnf)
    _setup_virtualbox_dnf "$version"
    ;;
  yum)
    _setup_virtualbox_yum "$version"
    ;;
  apt)
    _setup_virtualbox_apt "$version"
    ;;
  *)
    radp_log_error "Unsupported package manager: $pm"
    radp_log_info "Please install VirtualBox manually from: https://www.virtualbox.org/wiki/Downloads"
    return 1
    ;;
  esac
}

# Install VirtualBox on Fedora/RHEL 8+ using dnf
_setup_virtualbox_dnf() {
  local version="$1"

  # Check if running Fedora or RHEL-based
  local distro
  distro=$(radp_os_get_distro_id 2>/dev/null || echo "unknown")

  radp_log_info "Installing VirtualBox on $distro..."

  # Add Oracle VirtualBox repo
  local repo_url="https://download.virtualbox.org/virtualbox/rpm/el/virtualbox.repo"
  if [[ "$distro" == "fedora" ]]; then
    repo_url="https://download.virtualbox.org/virtualbox/rpm/fedora/virtualbox.repo"
  fi

  if [[ ! -f /etc/yum.repos.d/virtualbox.repo ]]; then
    radp_log_info "Adding VirtualBox repository..."
    $gr_sudo wget -q "$repo_url" -O /etc/yum.repos.d/virtualbox.repo || return 1
  fi

  # Install dependencies
  radp_log_info "Installing dependencies..."
  $gr_sudo dnf install -y kernel-devel kernel-headers dkms || return 1

  # Determine VirtualBox package version
  local pkg="VirtualBox-7.1"
  if [[ "$version" != "latest" ]]; then
    local major_minor="${version%.*}"
    pkg="VirtualBox-${major_minor}"
  fi

  radp_log_info "Installing $pkg..."
  $gr_sudo dnf install -y "$pkg" || return 1

  # Add user to vboxusers group
  _setup_virtualbox_add_user_to_group

  radp_log_info "VirtualBox installed successfully"
}

# Install VirtualBox on CentOS/RHEL 7 using yum
_setup_virtualbox_yum() {
  local version="$1"

  radp_log_info "Installing VirtualBox via yum..."

  # Add Oracle VirtualBox repo
  if [[ ! -f /etc/yum.repos.d/virtualbox.repo ]]; then
    radp_log_info "Adding VirtualBox repository..."
    $gr_sudo wget -q https://download.virtualbox.org/virtualbox/rpm/el/virtualbox.repo \
      -O /etc/yum.repos.d/virtualbox.repo || return 1
  fi

  # Install dependencies
  radp_log_info "Installing dependencies..."
  $gr_sudo yum install -y kernel-devel kernel-headers dkms || return 1

  # Determine VirtualBox package version
  local pkg="VirtualBox-7.1"
  if [[ "$version" != "latest" ]]; then
    local major_minor="${version%.*}"
    pkg="VirtualBox-${major_minor}"
  fi

  radp_log_info "Installing $pkg..."
  $gr_sudo yum install -y "$pkg" || return 1

  # Add user to vboxusers group
  _setup_virtualbox_add_user_to_group

  radp_log_info "VirtualBox installed successfully"
}

# Install VirtualBox on Debian/Ubuntu using apt
_setup_virtualbox_apt() {
  local version="$1"

  radp_log_info "Installing VirtualBox via apt..."

  # Get distribution codename
  local codename
  codename=$(lsb_release -cs 2>/dev/null || echo "")
  if [[ -z "$codename" ]]; then
    codename=$(grep VERSION_CODENAME /etc/os-release 2>/dev/null | cut -d= -f2)
  fi

  # Add Oracle GPG key and repository
  if [[ ! -f /etc/apt/sources.list.d/virtualbox.list ]]; then
    radp_log_info "Adding VirtualBox repository..."

    # Add Oracle GPG keys
    $gr_sudo mkdir -p /etc/apt/keyrings
    wget -qO- https://www.virtualbox.org/download/oracle_vbox_2016.asc | \
      $gr_sudo gpg --dearmor -o /etc/apt/keyrings/oracle-virtualbox-2016.gpg || return 1

    # Add repository
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/oracle-virtualbox-2016.gpg] https://download.virtualbox.org/virtualbox/debian $codename contrib" | \
      $gr_sudo tee /etc/apt/sources.list.d/virtualbox.list > /dev/null || return 1

    $gr_sudo apt-get update || return 1
  fi

  # Determine VirtualBox package version
  local pkg="virtualbox-7.1"
  if [[ "$version" != "latest" ]]; then
    local major_minor="${version%.*}"
    pkg="virtualbox-${major_minor}"
  fi

  radp_log_info "Installing $pkg..."
  $gr_sudo apt-get install -y "$pkg" || return 1

  # Add user to vboxusers group
  _setup_virtualbox_add_user_to_group

  radp_log_info "VirtualBox installed successfully"
}

# Add current user to vboxusers group
_setup_virtualbox_add_user_to_group() {
  local current_user
  current_user=$(whoami)

  if ! groups "$current_user" | grep -q vboxusers; then
    radp_log_info "Adding $current_user to vboxusers group..."
    $gr_sudo usermod -aG vboxusers "$current_user" || true
    radp_log_info "Please log out and log back in for group changes to take effect"
  fi
}
