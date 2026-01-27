#!/usr/bin/env bash
# vagrant installer

_setup_install_vagrant() {
  local version="${1:-latest}"

  if _setup_is_installed vagrant && [[ "$version" == "latest" ]]; then
    radp_log_info "vagrant is already installed"
    return 0
  fi

  local pm
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

  case "$pm" in
  brew)
    radp_log_info "Installing vagrant via Homebrew..."
    brew install --cask hashicorp-vagrant || return 1
    ;;
  dnf | yum)
    radp_log_info "Installing vagrant via dnf..."
    _setup_vagrant_hashicorp_repo_rpm
    radp_os_install_pkgs vagrant || return 1
    ;;
  apt | apt-get)
    radp_log_info "Installing vagrant via apt..."
    _setup_vagrant_hashicorp_repo_deb
    radp_os_install_pkgs vagrant || return 1
    ;;
  pacman)
    radp_log_info "Installing vagrant via pacman..."
    radp_os_install_pkgs vagrant || return 1
    ;;
  *)
    radp_log_error "Cannot install vagrant: unsupported package manager"
    return 1
    ;;
  esac
}

_setup_vagrant_hashicorp_repo_rpm() {
  local repo_file="/etc/yum.repos.d/hashicorp.repo"
  if [[ ! -f "$repo_file" ]]; then
    radp_log_info "Adding HashiCorp RPM repository..."
    ${gr_sudo:-sudo} tee "$repo_file" >/dev/null <<'REPO'
[hashicorp]
name=HashiCorp Stable - $basearch
baseurl=https://rpm.releases.hashicorp.com/fedora/$releasever/$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://rpm.releases.hashicorp.com/gpg
REPO
  fi
}

_setup_vagrant_hashicorp_repo_deb() {
  local list_file="/etc/apt/sources.list.d/hashicorp.list"
  if [[ ! -f "$list_file" ]]; then
    radp_log_info "Adding HashiCorp APT repository..."
    curl -fsSL https://apt.releases.hashicorp.com/gpg | ${gr_sudo:-sudo} gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg || return 1
    local codename
    codename=$(lsb_release -cs 2>/dev/null || echo "jammy")
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $codename main" | \
      ${gr_sudo:-sudo} tee "$list_file" >/dev/null || return 1
    ${gr_sudo:-sudo} apt-get update -qq || return 1
  fi
}
