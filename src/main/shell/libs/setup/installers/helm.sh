#!/usr/bin/env bash
# helm installer

_setup_install_helm() {
  local version="${1:-latest}"

  if _setup_is_installed helm && [[ "$version" == "latest" ]]; then
    radp_log_info "helm is already installed"
    return 0
  fi

  local pm
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

  case "$pm" in
  brew)
    radp_log_info "Installing helm via Homebrew..."
    brew install helm || return 1
    ;;
  dnf | yum | apt | apt-get | pacman)
    _setup_helm_from_script "$version"
    ;;
  *)
    _setup_helm_from_script "$version"
    ;;
  esac
}

_setup_helm_from_script() {
  local version="$1"

  local tmpdir
  tmpdir=$(_setup_mktemp_dir)
  trap 'rm -rf "$tmpdir"' RETURN

  radp_log_info "Installing helm via official install script..."
  radp_io_download "https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3" "$tmpdir/get_helm.sh" || return 1

  chmod +x "$tmpdir/get_helm.sh"

  if [[ "$version" != "latest" ]]; then
    [[ "$version" != v* ]] && version="v$version"
    DESIRED_VERSION="$version" bash "$tmpdir/get_helm.sh" || return 1
  else
    bash "$tmpdir/get_helm.sh" || return 1
  fi
}
