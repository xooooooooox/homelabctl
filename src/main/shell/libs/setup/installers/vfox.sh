#!/usr/bin/env bash
# vfox installer

_setup_install_vfox() {
  local version="${1:-latest}"

  if _setup_is_installed vfox && [[ "$version" == "latest" ]]; then
    radp_log_info "vfox is already installed"
    return 0
  fi

  local pm
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

  case "$pm" in
  brew)
    radp_log_info "Installing vfox via Homebrew..."
    brew install vfox || return 1
    ;;
  dnf | yum)
    _setup_vfox_rpm_repo
    radp_log_info "Installing vfox via dnf..."
    radp_os_install_pkgs vfox || return 1
    ;;
  apt | apt-get)
    _setup_vfox_deb_repo
    radp_log_info "Installing vfox via apt..."
    radp_os_install_pkgs vfox || return 1
    ;;
  *)
    _setup_vfox_from_release "$version"
    ;;
  esac
}

_setup_vfox_rpm_repo() {
  local repo_file="/etc/yum.repos.d/vfox.repo"
  if [[ ! -f "$repo_file" ]]; then
    radp_log_info "Adding vfox YUM repository..."
    echo '[vfox]
name=vfox Repo
baseurl=https://yum.fury.io/versionfox/
enabled=1
gpgcheck=0' | $gr_sudo tee "$repo_file" >/dev/null
  fi
}

_setup_vfox_deb_repo() {
  local list_file="/etc/apt/sources.list.d/vfox.list"
  if [[ ! -f "$list_file" ]]; then
    radp_log_info "Adding vfox APT repository..."
    echo "deb [trusted=yes] https://apt.fury.io/versionfox/ /" | \
      $gr_sudo tee "$list_file" >/dev/null || return 1
    $gr_sudo apt-get update -qq || return 1
  fi
}

_setup_vfox_from_release() {
  local version="$1"

  if [[ "$version" == "latest" ]]; then
    version=$(_setup_github_latest_version "version-fox/vfox")
    [[ -z "$version" ]] && version="0.6.1"
  fi

  local arch os
  arch=$(_setup_get_arch)
  os=$(_setup_get_os)

  # Map to vfox release naming: vfox_linux_x86_64.tar.gz
  local vfox_os vfox_arch
  case "$os" in
  darwin) vfox_os="darwin" ;;
  linux) vfox_os="linux" ;;
  *)
    radp_log_error "Unsupported OS: $os"
    return 1
    ;;
  esac

  case "$arch" in
  amd64) vfox_arch="x86_64" ;;
  arm64) vfox_arch="aarch64" ;;
  *) vfox_arch="$arch" ;;
  esac

  local filename="vfox_${vfox_os}_${vfox_arch}.tar.gz"
  local url="https://github.com/version-fox/vfox/releases/download/v${version}/${filename}"

  local tmpdir
  tmpdir=$(_setup_mktemp_dir)
  trap 'rm -rf "$tmpdir"; trap - RETURN' RETURN

  radp_log_info "Downloading vfox $version..."
  radp_io_download "$url" "$tmpdir/$filename" || return 1

  _setup_extract_archive "$tmpdir/$filename" "$tmpdir" || return 1
  _setup_install_binary "$tmpdir/vfox" || return 1
}
