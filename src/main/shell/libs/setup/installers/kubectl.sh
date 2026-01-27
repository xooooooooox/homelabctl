#!/usr/bin/env bash
# kubectl installer

_setup_install_kubectl() {
  local version="${1:-latest}"

  if _setup_is_installed kubectl && [[ "$version" == "latest" ]]; then
    radp_log_info "kubectl is already installed"
    return 0
  fi

  local pm
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

  case "$pm" in
  brew)
    radp_log_info "Installing kubectl via Homebrew..."
    brew install kubernetes-cli || return 1
    ;;
  dnf | yum | apt | apt-get | pacman)
    _setup_kubectl_from_binary "$version"
    ;;
  *)
    _setup_kubectl_from_binary "$version"
    ;;
  esac
}

_setup_kubectl_from_binary() {
  local version="$1"

  if [[ "$version" == "latest" ]]; then
    version=$(curl -fsSL https://dl.k8s.io/release/stable.txt 2>/dev/null)
    [[ -z "$version" ]] && version="v1.31.0"
    # Ensure version starts with v
    [[ "$version" != v* ]] && version="v$version"
  else
    [[ "$version" != v* ]] && version="v$version"
  fi

  local arch os
  arch=$(_setup_get_arch)
  os=$(_setup_get_os)

  local url="https://dl.k8s.io/release/${version}/bin/${os}/${arch}/kubectl"

  local tmpdir
  tmpdir=$(_setup_mktemp_dir)
  trap 'rm -rf "$tmpdir"' EXIT

  radp_log_info "Downloading kubectl $version..."
  radp_io_download "$url" "$tmpdir/kubectl" || return 1

  chmod +x "$tmpdir/kubectl"
  _setup_install_binary "$tmpdir/kubectl" || return 1
}
