#!/usr/bin/env bash
# pet installer

_setup_install_pet() {
  local version="${1:-latest}"

  if _setup_is_installed pet && [[ "$version" == "latest" ]]; then
    radp_log_info "pet is already installed"
    return 0
  fi

  local pm
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

  case "$pm" in
  brew)
    radp_log_info "Installing pet via Homebrew..."
    brew install pet || return 1
    ;;
  dnf | yum)
    radp_log_info "Installing pet via rpm release..."
    _setup_pet_from_rpm "$version"
    ;;
  apt | apt-get)
    radp_log_info "Installing pet via deb release..."
    _setup_pet_from_deb "$version"
    ;;
  *)
    _setup_pet_from_release "$version"
    ;;
  esac
}

_setup_pet_resolve_version() {
  local version="$1"

  if [[ "$version" == "latest" ]]; then
    version=$(_setup_github_latest_version "knqyf263/pet")
    [[ -z "$version" ]] && version="1.0.1"
  fi

  echo "$version"
}

_setup_pet_from_rpm() {
  local version
  version=$(_setup_pet_resolve_version "$1")

  local arch
  arch=$(_setup_get_arch)

  local filename="pet_${version}_linux_${arch}.rpm"
  local url="https://github.com/knqyf263/pet/releases/download/v${version}/${filename}"

  local tmpdir
  tmpdir=$(_setup_mktemp_dir)
  trap 'rm -rf "$tmpdir"; trap - RETURN' RETURN

  radp_log_info "Downloading pet $version rpm..."
  radp_io_download "$url" "$tmpdir/$filename" || return 1
  $gr_sudo rpm -i "$tmpdir/$filename" || return 1
}

_setup_pet_from_deb() {
  local version
  version=$(_setup_pet_resolve_version "$1")

  local arch
  arch=$(_setup_get_arch)

  local filename="pet_${version}_linux_${arch}.deb"
  local url="https://github.com/knqyf263/pet/releases/download/v${version}/${filename}"

  local tmpdir
  tmpdir=$(_setup_mktemp_dir)
  trap 'rm -rf "$tmpdir"; trap - RETURN' RETURN

  radp_log_info "Downloading pet $version deb..."
  radp_io_download "$url" "$tmpdir/$filename" || return 1
  $gr_sudo dpkg -i "$tmpdir/$filename" || return 1
}

_setup_pet_from_release() {
  local version
  version=$(_setup_pet_resolve_version "$1")

  local arch os
  arch=$(_setup_get_arch)
  os=$(_setup_get_os)

  local filename="pet_${version}_${os}_${arch}.tar.gz"
  local url="https://github.com/knqyf263/pet/releases/download/v${version}/${filename}"

  local tmpdir
  tmpdir=$(_setup_mktemp_dir)
  trap 'rm -rf "$tmpdir"; trap - RETURN' RETURN

  radp_log_info "Downloading pet $version..."
  radp_io_download "$url" "$tmpdir/$filename" || return 1

  _setup_extract_archive "$tmpdir/$filename" "$tmpdir" || return 1
  _setup_install_binary "$tmpdir/pet" || return 1
}
