#!/usr/bin/env bash
# docker installer

_setup_install_docker() {
  local version="${1:-latest}"

  if _setup_is_installed docker && [[ "$version" == "latest" ]]; then
    radp_log_info "docker is already installed"
    return 0
  fi

  local pm
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

  case "$pm" in
  brew)
    radp_log_info "Installing Docker Desktop via Homebrew..."
    brew install --cask docker || return 1
    ;;
  dnf | yum)
    _setup_docker_from_official "$pm"
    ;;
  apt | apt-get)
    _setup_docker_from_official "apt"
    ;;
  *)
    _setup_docker_from_script
    ;;
  esac
}

_setup_docker_from_official() {
  local pm="$1"

  case "$pm" in
  dnf | yum)
    radp_log_info "Installing Docker via official dnf repo..."
    $gr_sudo "$pm" install -y yum-utils 2>/dev/null || true
    $gr_sudo "$pm" config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo 2>/dev/null ||
      $gr_sudo "$pm" -y install dnf-plugins-core && $gr_sudo "$pm" config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    $gr_sudo "$pm" install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || return 1
    ;;
  apt)
    radp_log_info "Installing Docker via official apt repo..."
    radp_os_install_pkgs ca-certificates curl || return 1

    # Add Docker GPG key
    $gr_sudo install -m 0755 -d /etc/apt/keyrings
    $gr_sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    $gr_sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add apt repo
    # shellcheck disable=SC1091
    source /etc/os-release
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/${ID} ${VERSION_CODENAME} stable" |
      $gr_sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
    $gr_sudo apt-get update
    $gr_sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || return 1
    ;;
  esac

  $gr_sudo systemctl enable docker 2>/dev/null || true
  $gr_sudo systemctl start docker 2>/dev/null || true
}

_setup_docker_from_script() {
  radp_log_info "Installing Docker via official install script..."

  local tmpdir
  tmpdir=$(_setup_mktemp_dir)
  trap 'rm -rf "$tmpdir"; trap - RETURN' RETURN

  radp_io_download "https://get.docker.com" "$tmpdir/get-docker.sh" || return 1
  $gr_sudo bash "$tmpdir/get-docker.sh" || return 1
}
