#!/usr/bin/env bash
# markdownlint-cli installer

_setup_install_markdownlint_cli() {
  local version="${1:-latest}"

  if _setup_is_installed markdownlint && [[ "$version" == "latest" ]]; then
    radp_log_info "markdownlint-cli is already installed"
    return 0
  fi

  local pm
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

  case "$pm" in
  brew)
    radp_log_info "Installing markdownlint-cli via Homebrew..."
    brew install markdownlint-cli || return 1
    ;;
  *)
    # markdownlint-cli is an npm package
    if ! _setup_is_installed npm; then
      # Debug: try to find npm in vfox directories
      local vfox_home="${VFOX_HOME:-$HOME/.version-fox}"
      [[ ! -d "$vfox_home" ]] && vfox_home="$HOME/.vfox"
      local npm_path
      npm_path=$(find "$vfox_home" -name "npm" -type f -o -name "npm" -type l 2>/dev/null | head -1)
      if [[ -n "$npm_path" && -x "$npm_path" ]]; then
        radp_log_info "Found npm at $npm_path, adding to PATH"
        export PATH="$(dirname "$npm_path"):$PATH"
        hash -r 2>/dev/null || true
      else
        radp_log_error "npm is required to install markdownlint-cli. Install nodejs first."
        radp_log_error "Debug: PATH=$PATH"
        radp_log_error "Debug: vfox_home=$vfox_home"
        return 1
      fi
    fi
    radp_log_info "Installing markdownlint-cli via npm..."
    # Use npm from vfox without sudo (user-space installation)
    local npm_cmd
    npm_cmd=$(command -v npm)
    if [[ "$npm_cmd" == *".version-fox"* ]]; then
      # vfox-managed npm: install globally to npm prefix (no sudo needed)
      npm install -g markdownlint-cli || return 1
    else
      # System npm: may need sudo
      $gr_sudo npm install -g markdownlint-cli || return 1
    fi
    ;;
  esac
}
