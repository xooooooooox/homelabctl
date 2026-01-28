#!/usr/bin/env bash
# rust installer

_setup_install_rust() {
  local version="${1:-latest}"

  if _setup_is_installed rustc && [[ "$version" == "latest" ]]; then
    radp_log_info "rust is already installed"
    return 0
  fi

  local pm
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

  case "$pm" in
  brew)
    radp_log_info "Installing rust via Homebrew..."
    brew install rustup || return 1
    rustup-init -y --no-modify-path || return 1
    ;;
  *)
    _setup_rust_via_rustup "$version"
    ;;
  esac
}

_setup_rust_via_rustup() {
  local version="$1"

  radp_log_info "Installing rust via rustup..."

  local tmpdir
  tmpdir=$(_setup_mktemp_dir)
  trap 'rm -rf "$tmpdir"; trap - RETURN' RETURN

  radp_io_download "https://sh.rustup.rs" "$tmpdir/rustup-init.sh" || return 1

  local install_args=("-y" "--no-modify-path")
  if [[ "$version" != "latest" ]]; then
    install_args+=("--default-toolchain" "$version")
  fi

  bash "$tmpdir/rustup-init.sh" "${install_args[@]}" || return 1

  # Make cargo/rustc available in current session
  if [[ -f "$HOME/.cargo/env" ]]; then
    # shellcheck source=/dev/null
    source "$HOME/.cargo/env"
  fi
}
