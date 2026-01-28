#!/usr/bin/env bash
# terraform installer

_setup_install_terraform() {
  local version="${1:-latest}"

  if _setup_is_installed terraform && [[ "$version" == "latest" ]]; then
    radp_log_info "terraform is already installed"
    return 0
  fi

  local pm
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

  case "$pm" in
  brew)
    radp_log_info "Installing terraform via Homebrew..."
    brew tap hashicorp/tap 2>/dev/null || true
    brew install hashicorp/tap/terraform || return 1
    ;;
  dnf | yum)
    _setup_terraform_from_hashicorp_repo "$pm"
    ;;
  apt | apt-get)
    _setup_terraform_from_hashicorp_repo "apt"
    ;;
  *)
    _setup_terraform_from_release "$version"
    ;;
  esac
}

_setup_terraform_from_hashicorp_repo() {
  local pm="$1"

  case "$pm" in
  dnf | yum)
    radp_log_info "Installing terraform via HashiCorp repo..."
    $gr_sudo "$pm" install -y yum-utils 2>/dev/null || true
    $gr_sudo "$pm" config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo 2>/dev/null || true
    $gr_sudo "$pm" install -y terraform || return 1
    ;;
  apt)
    radp_log_info "Installing terraform via HashiCorp repo..."
    radp_os_install_pkgs gnupg software-properties-common || return 1

    local tmpdir
    tmpdir=$(_setup_mktemp_dir)
    trap 'rm -rf "$tmpdir"; trap - RETURN' RETURN

    radp_io_download "https://apt.releases.hashicorp.com/gpg" "$tmpdir/hashicorp.gpg" || return 1
    $gr_sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg "$tmpdir/hashicorp.gpg" || return 1

    # shellcheck disable=SC1091
    source /etc/os-release
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com ${VERSION_CODENAME} main" |
      $gr_sudo tee /etc/apt/sources.list.d/hashicorp.list >/dev/null
    $gr_sudo apt-get update
    $gr_sudo apt-get install -y terraform || return 1
    ;;
  esac
}

_setup_terraform_from_release() {
  local version="$1"

  if [[ "$version" == "latest" ]]; then
    version=$(_setup_github_latest_version "hashicorp/terraform")
    [[ -z "$version" ]] && version="1.10.4"
  fi

  local arch os
  arch=$(_setup_get_arch)
  os=$(_setup_get_os)

  local filename="terraform_${version}_${os}_${arch}.zip"
  local url="https://releases.hashicorp.com/terraform/${version}/${filename}"

  local tmpdir
  tmpdir=$(_setup_mktemp_dir)
  trap 'rm -rf "$tmpdir"; trap - RETURN' RETURN

  radp_log_info "Downloading terraform $version..."
  radp_io_download "$url" "$tmpdir/$filename" || return 1

  _setup_extract_archive "$tmpdir/$filename" "$tmpdir" || return 1
  _setup_install_binary "$tmpdir/terraform" || return 1
}
