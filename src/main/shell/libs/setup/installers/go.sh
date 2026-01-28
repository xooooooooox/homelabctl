#!/usr/bin/env bash
# go installer

_setup_install_go() {
  local version="${1:-latest}"

  if _setup_is_installed go && [[ "$version" == "latest" ]]; then
    radp_log_info "go is already installed"
    return 0
  fi

  local pm
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

  # Prefer vfox for version management
  if _setup_is_installed vfox; then
    _setup_go_via_vfox "$version"
    return $?
  fi

  case "$pm" in
  brew)
    radp_log_info "Installing go via Homebrew..."
    brew install go || return 1
    ;;
  *)
    _setup_go_from_official "$version"
    ;;
  esac
}

_setup_go_via_vfox() {
  local version="$1"

  radp_log_info "Installing go via vfox..."

  if ! vfox list golang &>/dev/null; then
    vfox add golang || return 1
  fi

  if [[ "$version" == "latest" ]]; then
    version=$(vfox search golang 2>/dev/null | head -1 | awk '{print $1}')
    [[ -z "$version" ]] && version="1.23"
  fi

  vfox install "golang@$version" || return 1
  vfox use --global "golang@$version" 2>/dev/null || true

  # Add go to PATH directly (vfox uses "golang" as SDK name)
  _setup_vfox_add_sdk_to_path "golang" "go"
  _setup_vfox_refresh_path
}

_setup_go_from_official() {
  local version="$1"

  if [[ "$version" == "latest" ]]; then
    version=$(_setup_github_latest_version "golang/go")
    # golang/go tags are "go1.23.5", strip "go" prefix
    version="${version#go}"
    [[ -z "$version" ]] && version="1.23.5"
  fi

  local arch os
  arch=$(_setup_get_arch)
  os=$(_setup_get_os)

  local filename="go${version}.${os}-${arch}.tar.gz"
  local url="https://go.dev/dl/${filename}"

  local tmpdir
  tmpdir=$(_setup_mktemp_dir)
  trap 'rm -rf "$tmpdir"; trap - RETURN' RETURN

  radp_log_info "Downloading go $version..."
  radp_io_download "$url" "$tmpdir/$filename" || return 1

  $gr_sudo rm -rf /usr/local/go
  $gr_sudo tar -C /usr/local -xzf "$tmpdir/$filename" || return 1

  # Ensure /usr/local/go/bin is in PATH
  if [[ ":$PATH:" != *":/usr/local/go/bin:"* ]]; then
    export PATH="/usr/local/go/bin:$PATH"
  fi

  radp_log_info "Go installed to /usr/local/go"
  radp_log_info "Ensure /usr/local/go/bin is in your PATH"
}
