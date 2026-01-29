#!/usr/bin/env bash
set -euo pipefail

REPO_NAME="homelabctl"
OPT_DEPS=false
OPT_YES=false

# ============================================================================
# Logging
# ============================================================================

log() {
  printf "%s\n" "$*"
}

err() {
  printf "homelabctl uninstall: %s\n" "$*" >&2
}

die() {
  err "$@"
  exit 1
}

have() {
  command -v "$1" >/dev/null 2>&1
}

# ============================================================================
# Usage
# ============================================================================

usage() {
  cat <<'EOF'
homelabctl uninstaller

Usage:
  uninstall.sh [OPTIONS]
  curl -fsSL .../uninstall.sh | bash -s -- [OPTIONS]

Options:
  --deps          Also uninstall radp-bash-framework
  --yes           Skip confirmation prompt
  -h, --help      Show this help

Examples:
  bash uninstall.sh
  bash uninstall.sh --yes
  bash uninstall.sh --deps --yes
EOF
}

# ============================================================================
# Argument Parsing
# ============================================================================

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
    --deps)
      OPT_DEPS=true
      shift
      ;;
    --yes | -y)
      OPT_YES=true
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      die "Unknown option: $1 (use --help for usage)"
      ;;
    esac
  done
}

# ============================================================================
# Detection
# ============================================================================

# Detect if homelabctl is installed via a package manager
# Returns: homebrew, dnf, yum, rpm, apt, zypper, or empty string
detect_pkm_installed() {
  if have brew && brew list --formula homelabctl &>/dev/null; then
    echo "homebrew"
    return 0
  fi

  if have rpm && rpm -q homelabctl &>/dev/null; then
    if have dnf; then
      echo "dnf"
    elif have yum; then
      echo "yum"
    else
      echo "rpm"
    fi
    return 0
  fi

  if have dpkg && dpkg -s homelabctl &>/dev/null; then
    echo "apt"
    return 0
  fi

  if have zypper && zypper se -i homelabctl &>/dev/null; then
    echo "zypper"
    return 0
  fi

  echo ""
}

# Detect manual installation
# Returns: install directory path, or empty string
detect_manual_installed() {
  local default_dir="$HOME/.local/lib/${REPO_NAME}"

  if [[ -d "${default_dir}" && -f "${default_dir}/.install-method" ]]; then
    echo "${default_dir}"
    return 0
  fi

  # Also check if the symlink points to a manual install
  local link_path="$HOME/.local/bin/homelabctl"
  if [[ -L "${link_path}" ]]; then
    local target
    target="$(readlink -f "${link_path}" 2>/dev/null || readlink "${link_path}")"
    local target_dir
    target_dir="$(dirname "$(dirname "${target}")")"
    if [[ -d "${target_dir}" && "$(basename "${target_dir}")" == "${REPO_NAME}" ]]; then
      echo "${target_dir}"
      return 0
    fi
  fi

  echo ""
}

# ============================================================================
# Uninstall
# ============================================================================

uninstall_pkm() {
  local pkm="$1"

  log "Uninstalling ${REPO_NAME} via ${pkm}..."

  case "${pkm}" in
  homebrew)
    brew uninstall homelabctl
    ;;
  dnf)
    sudo dnf remove -y homelabctl
    ;;
  yum)
    sudo yum remove -y homelabctl
    ;;
  rpm)
    sudo rpm -e homelabctl
    ;;
  apt)
    sudo apt-get remove -y homelabctl
    ;;
  zypper)
    sudo zypper remove -y homelabctl
    ;;
  *)
    err "Don't know how to uninstall via: ${pkm}"
    return 1
    ;;
  esac

  # Remove shell completion files (user-local, not managed by package manager)
  local bash_comp="$HOME/.local/share/bash-completion/completions/homelabctl"
  local zsh_comp="$HOME/.zfunc/_homelabctl"
  if [[ -f "${bash_comp}" ]]; then
    rm -f "${bash_comp}"
    log "Removed bash completion ${bash_comp}"
  fi
  if [[ -f "${zsh_comp}" ]]; then
    rm -f "${zsh_comp}"
    log "Removed zsh completion ${zsh_comp}"
  fi
}

uninstall_manual() {
  local install_dir="$1"

  log "Removing manual installation at ${install_dir}..."

  # Remove symlink
  local bin_dir="$HOME/.local/bin"
  local link_path="${bin_dir}/homelabctl"
  if [[ -L "${link_path}" ]]; then
    rm -f "${link_path}"
    log "Removed symlink ${link_path}"
  fi

  # Remove shell completion files
  local bash_comp="$HOME/.local/share/bash-completion/completions/homelabctl"
  local zsh_comp="$HOME/.zfunc/_homelabctl"
  if [[ -f "${bash_comp}" ]]; then
    rm -f "${bash_comp}"
    log "Removed bash completion ${bash_comp}"
  fi
  if [[ -f "${zsh_comp}" ]]; then
    rm -f "${zsh_comp}"
    log "Removed zsh completion ${zsh_comp}"
  fi

  # Remove install directory
  rm -rf "${install_dir}"
  log "Removed ${install_dir}"
}

uninstall_deps_pkm() {
  local pkm="$1"

  log "Uninstalling radp-bash-framework via ${pkm}..."

  case "${pkm}" in
  homebrew)
    brew uninstall radp-bash-framework 2>/dev/null || true
    ;;
  dnf)
    sudo dnf remove -y radp-bash-framework 2>/dev/null || true
    ;;
  yum)
    sudo yum remove -y radp-bash-framework 2>/dev/null || true
    ;;
  rpm)
    sudo rpm -e radp-bash-framework 2>/dev/null || true
    ;;
  apt)
    sudo apt-get remove -y radp-bash-framework 2>/dev/null || true
    ;;
  zypper)
    sudo zypper remove -y radp-bash-framework 2>/dev/null || true
    ;;
  esac
}

# Detect manual radp-bash-framework installation
# Returns: install directory path, or empty string
detect_radp_bf_manual_installed() {
  local default_dir="$HOME/.local/lib/radp-bash-framework"

  if [[ -d "${default_dir}" && -f "${default_dir}/.install-method" ]]; then
    echo "${default_dir}"
    return 0
  fi

  echo ""
}

uninstall_deps_manual() {
  local install_dir="$1"

  log "Uninstalling radp-bash-framework manual installation..."

  # Remove symlinks
  local bin_dir="$HOME/.local/bin"
  local link_name
  for link_name in radp-bf radp-bash-framework; do
    local link_path="${bin_dir}/${link_name}"
    if [[ -L "${link_path}" ]]; then
      rm -f "${link_path}"
      log "Removed symlink ${link_path}"
    fi
  done

  # Remove install directory
  rm -rf "${install_dir}"
  log "Removed ${install_dir}"
}

confirm() {
  local prompt="$1"
  if [[ "${OPT_YES}" == true ]]; then
    return 0
  fi

  printf "%s [y/N] " "${prompt}"
  local reply
  read -r reply
  case "${reply}" in
  y | Y | yes | YES) return 0 ;;
  *) return 1 ;;
  esac
}

# ============================================================================
# Main
# ============================================================================

main() {
  parse_args "$@"

  local pkm_installed manual_dir
  pkm_installed="$(detect_pkm_installed)"
  manual_dir="$(detect_manual_installed)"

  if [[ -z "${pkm_installed}" && -z "${manual_dir}" ]]; then
    log "${REPO_NAME} is not installed"
    exit 0
  fi

  # Show what will be removed
  log "Detected installations:"
  if [[ -n "${pkm_installed}" ]]; then
    log "  - Package manager: ${pkm_installed}"
  fi
  if [[ -n "${manual_dir}" ]]; then
    local ref_info=""
    if [[ -f "${manual_dir}/.install-ref" ]]; then
      ref_info=" (ref: $(cat "${manual_dir}/.install-ref"))"
    fi
    log "  - Manual: ${manual_dir}${ref_info}"
  fi
  if [[ "${OPT_DEPS}" == true ]]; then
    log "  - Dependency: radp-bash-framework (--deps)"
  fi
  log ""

  if ! confirm "Proceed with uninstall?"; then
    log "Cancelled"
    exit 0
  fi

  # Remove package-manager installation
  if [[ -n "${pkm_installed}" ]]; then
    uninstall_pkm "${pkm_installed}" || err "Failed to uninstall via ${pkm_installed}"
  fi

  # Remove manual installation
  if [[ -n "${manual_dir}" ]]; then
    uninstall_manual "${manual_dir}" || err "Failed to remove manual installation"
  fi

  # Remove dependency if requested
  if [[ "${OPT_DEPS}" == true ]]; then
    local dep_pkm=""
    local dep_manual_dir=""

    # Try to detect how radp-bash-framework was installed
    if have brew && brew list --formula radp-bash-framework &>/dev/null; then
      dep_pkm="homebrew"
    elif have rpm && rpm -q radp-bash-framework &>/dev/null; then
      if have dnf; then
        dep_pkm="dnf"
      elif have yum; then
        dep_pkm="yum"
      else
        dep_pkm="rpm"
      fi
    elif have dpkg && dpkg -s radp-bash-framework &>/dev/null; then
      dep_pkm="apt"
    elif have zypper && zypper se -i radp-bash-framework &>/dev/null; then
      dep_pkm="zypper"
    else
      # Check for manual installation
      dep_manual_dir="$(detect_radp_bf_manual_installed)"
    fi

    if [[ -n "${dep_pkm}" ]]; then
      uninstall_deps_pkm "${dep_pkm}"
    elif [[ -n "${dep_manual_dir}" ]]; then
      uninstall_deps_manual "${dep_manual_dir}"
    else
      log "radp-bash-framework: not installed, skipping"
    fi
  else
    if [[ -n "${pkm_installed}" || -n "${manual_dir}" ]]; then
      log ""
      log "Note: radp-bash-framework was not removed."
      log "  To also remove it, re-run with --deps"
    fi
  fi

  log ""
  log "${REPO_NAME} has been uninstalled"
  log ""
  log "Note: User configuration files may remain at:"
  log "  ~/.config/homelabctl/"
  log "Remove manually if no longer needed."
}

main "$@"
