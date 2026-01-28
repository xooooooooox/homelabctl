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
    local npm_cmd=""

    # First check if npm is in PATH
    if _setup_is_installed npm; then
      npm_cmd=$(command -v npm)
    else
      # Try to find npm in vfox directories
      local vfox_home="${VFOX_HOME:-$HOME/.version-fox}"
      [[ ! -d "$vfox_home" ]] && vfox_home="$HOME/.vfox"
      npm_cmd=$(find "$vfox_home" -name "npm" \( -type f -o -type l \) -perm -111 2>/dev/null | head -1)
      if [[ -z "$npm_cmd" ]]; then
        radp_log_error "npm is required to install markdownlint-cli. Install nodejs first."
        return 1
      fi
      radp_log_info "Found npm at $npm_cmd"
    fi

    radp_log_info "Installing markdownlint-cli via npm..."

    # Check if npm is from vfox (user-space, no sudo needed)
    if [[ "$npm_cmd" == *".version-fox"* ]] || [[ "$npm_cmd" == *".vfox"* ]]; then
      # vfox-managed npm: install globally to npm prefix (no sudo needed)
      "$npm_cmd" install -g markdownlint-cli || return 1
    else
      # System npm: may need sudo
      $gr_sudo "$npm_cmd" install -g markdownlint-cli || return 1
    fi
    ;;
  esac
}
