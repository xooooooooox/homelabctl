#!/usr/bin/env bash
# shellcheck installer

_setup_install_shellcheck() {
  local version="${1:-latest}"

  if _setup_is_installed shellcheck && [[ "$version" == "latest" ]]; then
    radp_log_info "shellcheck is already installed"
    return 0
  fi

  local pm
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

  case "$pm" in
  brew)
    radp_log_info "Installing shellcheck via Homebrew..."
    brew install shellcheck || return 1
    ;;
  dnf | yum)
    radp_log_info "Installing shellcheck via dnf..."
    if ! radp_os_install_pkgs ShellCheck 2>/dev/null; then
      radp_log_info "ShellCheck not available in repos, falling back to binary release..."
      _setup_shellcheck_from_release "$version"
    fi
    ;;
  apt | apt-get)
    radp_log_info "Installing shellcheck via apt..."
    radp_os_install_pkgs shellcheck || return 1
    ;;
  pacman)
    radp_log_info "Installing shellcheck via pacman..."
    radp_os_install_pkgs shellcheck || return 1
    ;;
  *)
    _setup_shellcheck_from_release "$version"
    ;;
  esac
}

_setup_shellcheck_from_release() {
  local version="$1"

  if [[ "$version" == "latest" ]]; then
    version=$(_setup_github_latest_version "koalaman/shellcheck")
    [[ -z "$version" ]] && version="0.10.0"
  fi

  local arch os
  arch=$(_setup_get_arch)
  os=$(_setup_get_os)

  local sc_arch
  case "$arch" in
  amd64) sc_arch="x86_64" ;;
  arm64) sc_arch="aarch64" ;;
  *) sc_arch="$arch" ;;
  esac

  local filename="shellcheck-v${version}.${os}.${sc_arch}.tar.xz"
  local url="https://github.com/koalaman/shellcheck/releases/download/v${version}/${filename}"

  local tmpdir
  tmpdir=$(_setup_mktemp_dir)
  trap 'rm -rf "$tmpdir"; trap - RETURN' RETURN

  radp_log_info "Downloading shellcheck $version..."
  radp_io_download "$url" "$tmpdir/$filename" || return 1

  _setup_extract_archive "$tmpdir/$filename" "$tmpdir" || return 1
  _setup_install_binary "$tmpdir/shellcheck-v${version}/shellcheck" || return 1
}
