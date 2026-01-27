#!/usr/bin/env bash
# yadm installer

_setup_install_yadm() {
  local version="${1:-latest}"

  if _setup_is_installed yadm && [[ "$version" == "latest" ]]; then
    radp_log_info "yadm is already installed"
    return 0
  fi

  local pm
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

  case "$pm" in
  brew)
    radp_log_info "Installing yadm via Homebrew..."
    brew install yadm || return 1
    ;;
  apt | apt-get)
    radp_log_info "Installing yadm via apt..."
    radp_os_install_pkgs yadm || return 1
    ;;
  pacman)
    radp_log_info "Installing yadm via pacman..."
    radp_os_install_pkgs yadm || return 1
    ;;
  dnf | yum)
    # yadm is not in default RHEL/CentOS repos; download directly
    _setup_yadm_from_github "$version"
    ;;
  *)
    _setup_yadm_from_github "$version"
    ;;
  esac
}

_setup_yadm_from_github() {
  local version="$1"

  if [[ "$version" == "latest" ]]; then
    version=$(_setup_github_latest_version "yadm-dev/yadm")
    [[ -z "$version" ]] && version="3.3.0"
  fi

  local tmpdir
  tmpdir=$(_setup_mktemp_dir)
  trap 'rm -rf "$tmpdir"; trap - RETURN' RETURN

  radp_log_info "Downloading yadm $version..."
  radp_io_download "https://github.com/yadm-dev/yadm/raw/${version}/yadm" "$tmpdir/yadm" || return 1

  chmod +x "$tmpdir/yadm"
  _setup_install_binary "$tmpdir/yadm" || return 1
}
