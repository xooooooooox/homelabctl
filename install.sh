#!/usr/bin/env bash
set -euo pipefail

REPO_OWNER="xooooooooox"
REPO_NAME="homelabctl"
tmp_dir=""

# Defaults (overridable by CLI args, then env vars)
OPT_MODE="${HOMELABCTL_INSTALL_MODE:-auto}"
OPT_REF="${HOMELABCTL_REF:-}"
OPT_VERSION="${HOMELABCTL_VERSION:-}"
OPT_INSTALL_DIR="${HOMELABCTL_INSTALL_DIR:-}"
OPT_BIN_DIR="${HOMELABCTL_BIN_DIR:-}"

# ============================================================================
# Logging
# ============================================================================

log() {
  printf "%s\n" "$*"
}

err() {
  printf "homelabctl install: %s\n" "$*" >&2
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
homelabctl installer

Usage:
  install.sh [OPTIONS]
  curl -fsSL .../install.sh | bash -s -- [OPTIONS]

Options:
  --ref <ref>           Install from a git ref (branch, tag, or SHA).
                        Implies manual installation. If a package-manager
                        version is already installed, it is removed first.
  --mode <mode>         Installation mode (default: auto)
                        auto     - use package manager if available, else manual
                        manual   - always download from GitHub
                        homebrew - force Homebrew
                        dnf      - force dnf
                        yum      - force yum
                        apt      - force apt
                        zypper   - force zypper
  --install-dir <dir>   Manual install location
                        (default: $HOME/.local/lib/homelabctl)
  --bin-dir <dir>       Symlink location (default: $HOME/.local/bin)
  -h, --help            Show this help

Environment variables:
  HOMELABCTL_REF            Same as --ref
  HOMELABCTL_VERSION        Pin to a release version (e.g. v0.1.3)
  HOMELABCTL_INSTALL_MODE   Same as --mode
  HOMELABCTL_INSTALL_DIR    Same as --install-dir
  HOMELABCTL_BIN_DIR        Same as --bin-dir

Examples:
  # Default: auto-detect package manager
  bash install.sh

  # Install latest from main branch (removes pkm version if present)
  bash install.sh --ref main

  # Install a specific tag via manual download
  bash install.sh --ref v0.2.0-rc1

  # Force manual mode (latest release)
  bash install.sh --mode manual
EOF
}

# ============================================================================
# Argument Parsing
# ============================================================================

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
    --ref)
      [[ $# -lt 2 ]] && die "--ref requires a value"
      OPT_REF="$2"
      shift 2
      ;;
    --mode)
      [[ $# -lt 2 ]] && die "--mode requires a value"
      OPT_MODE="$2"
      shift 2
      ;;
    --install-dir)
      [[ $# -lt 2 ]] && die "--install-dir requires a value"
      OPT_INSTALL_DIR="$2"
      shift 2
      ;;
    --bin-dir)
      [[ $# -lt 2 ]] && die "--bin-dir requires a value"
      OPT_BIN_DIR="$2"
      shift 2
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
# Package Manager Detection and Installation
# ============================================================================

detect_os() {
  local os=""
  if [[ "${OSTYPE:-}" == darwin* ]]; then
    os="macos"
  elif [[ -f /etc/os-release ]]; then
    # shellcheck disable=SC1091
    source /etc/os-release
    case "${ID:-}" in
    fedora | centos | rhel | rocky | almalinux | ol)
      os="rhel"
      ;;
    debian | ubuntu | linuxmint | pop)
      os="debian"
      ;;
    opensuse* | sles)
      os="suse"
      ;;
    *)
      os="linux"
      ;;
    esac
  else
    os="unknown"
  fi
  echo "${os}"
}

# Detect available package manager
# Returns: homebrew, dnf, yum, apt, zypper, or empty string
detect_package_manager() {
  local os
  os="$(detect_os)"

  # Homebrew (macOS and Linux)
  if have brew; then
    echo "homebrew"
    return 0
  fi

  # Linux package managers
  case "${os}" in
  rhel)
    if have dnf; then
      echo "dnf"
      return 0
    elif have yum; then
      echo "yum"
      return 0
    fi
    ;;
  debian)
    if have apt-get; then
      echo "apt"
      return 0
    fi
    ;;
  suse)
    if have zypper; then
      echo "zypper"
      return 0
    fi
    ;;
  esac

  echo ""
}

# Detect if homelabctl is installed via a package manager
# Returns: the pkm name (homebrew, dnf, apt, ...) or empty string
detect_pkm_installed() {
  # Homebrew
  if have brew && brew list --formula homelabctl &>/dev/null; then
    echo "homebrew"
    return 0
  fi

  # RPM-based (dnf/yum)
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

  # Debian-based
  if have dpkg && dpkg -s homelabctl &>/dev/null; then
    echo "apt"
    return 0
  fi

  # zypper
  if have zypper && zypper se -i homelabctl &>/dev/null; then
    echo "zypper"
    return 0
  fi

  echo ""
}

# Uninstall package-manager-installed version
uninstall_pkm() {
  local pkm="$1"

  log "Removing package-manager version (${pkm}) to avoid conflicts..."

  case "${pkm}" in
  homebrew)
    brew uninstall homelabctl || return 1
    ;;
  dnf)
    sudo dnf remove -y homelabctl || return 1
    ;;
  yum)
    sudo yum remove -y homelabctl || return 1
    ;;
  rpm)
    sudo rpm -e homelabctl || return 1
    ;;
  apt)
    sudo apt-get remove -y homelabctl || return 1
    ;;
  zypper)
    sudo zypper remove -y homelabctl || return 1
    ;;
  *)
    err "Don't know how to uninstall via: ${pkm}"
    return 1
    ;;
  esac

  log "Package-manager version removed"
}

# Check if package manager repository is configured
check_repo_configured() {
  local pkm="$1"

  case "${pkm}" in
  homebrew)
    # Check if tap is configured
    if brew tap 2>/dev/null | grep -q "xooooooooox/radp"; then
      return 0
    fi
    return 1
    ;;
  dnf | yum)
    # Check if COPR repo is enabled
    if [[ -f /etc/yum.repos.d/_copr:copr.fedorainfracloud.org:xooooooooox:radp.repo ]] ||
      [[ -f /etc/yum.repos.d/radp.repo ]]; then
      return 0
    fi
    return 1
    ;;
  apt)
    # Check if OBS repo is configured
    if [[ -f /etc/apt/sources.list.d/home:xooooooooox:radp.list ]]; then
      return 0
    fi
    return 1
    ;;
  zypper)
    # Check if OBS repo is configured
    if zypper repos 2>/dev/null | grep -q "xooooooooox"; then
      return 0
    fi
    return 1
    ;;
  esac

  return 1
}

# Setup repository for package manager
setup_repo() {
  local pkm="$1"

  log "Setting up repository for ${pkm}..."

  case "${pkm}" in
  homebrew)
    log "Adding Homebrew tap..."
    brew tap xooooooooox/radp
    ;;
  dnf)
    log "Enabling COPR repository..."
    sudo dnf install -y dnf-plugins-core >/dev/null 2>&1 || true
    sudo dnf copr enable -y xooooooooox/radp
    ;;
  yum)
    log "Enabling COPR repository..."
    sudo yum install -y yum-plugin-copr >/dev/null 2>&1 || true
    sudo yum copr enable -y xooooooooox/radp
    ;;
  apt)
    log "Adding OBS repository..."
    # Detect distro for OBS
    local distro=""
    if [[ -f /etc/os-release ]]; then
      # shellcheck disable=SC1091
      source /etc/os-release
      case "${ID:-}" in
      ubuntu)
        distro="xUbuntu_${VERSION_ID}"
        ;;
      debian)
        distro="Debian_${VERSION_ID}"
        ;;
      *)
        err "Unsupported distribution for apt: ${ID:-unknown}"
        return 1
        ;;
      esac
    fi
    if [[ -z "${distro}" ]]; then
      err "Cannot detect distribution for OBS repository"
      return 1
    fi
    echo "deb http://download.opensuse.org/repositories/home:/xooooooooox:/radp/${distro}/ /" |
      sudo tee /etc/apt/sources.list.d/home:xooooooooox:radp.list >/dev/null
    curl -fsSL "https://download.opensuse.org/repositories/home:xooooooooox:radp/${distro}/Release.key" |
      gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/home_xooooooooox_radp.gpg >/dev/null
    sudo apt-get update >/dev/null
    ;;
  zypper)
    log "Adding OBS repository..."
    # Detect distro for OBS
    local distro=""
    if [[ -f /etc/os-release ]]; then
      # shellcheck disable=SC1091
      source /etc/os-release
      case "${ID:-}" in
      opensuse-tumbleweed)
        distro="openSUSE_Tumbleweed"
        ;;
      opensuse-leap)
        distro="openSUSE_Leap_${VERSION_ID}"
        ;;
      sles)
        distro="SLE_${VERSION_ID}"
        ;;
      *)
        err "Unsupported distribution for zypper: ${ID:-unknown}"
        return 1
        ;;
      esac
    fi
    if [[ -z "${distro}" ]]; then
      err "Cannot detect distribution for OBS repository"
      return 1
    fi
    sudo zypper addrepo -f "https://download.opensuse.org/repositories/home:/xooooooooox:/radp/${distro}/home:xooooooooox:radp.repo"
    ;;
  *)
    err "Unknown package manager: ${pkm}"
    return 1
    ;;
  esac
}

# Refresh package manager cache
refresh_cache() {
  local pkm="$1"

  log "Refreshing package cache..."

  case "${pkm}" in
  homebrew)
    brew update >/dev/null 2>&1 || true
    ;;
  dnf)
    sudo dnf clean all >/dev/null 2>&1 || true
    sudo dnf makecache >/dev/null 2>&1 || true
    ;;
  yum)
    sudo yum clean all >/dev/null 2>&1 || true
    sudo yum makecache >/dev/null 2>&1 || true
    ;;
  apt)
    sudo apt-get update >/dev/null 2>&1 || true
    ;;
  zypper)
    sudo zypper refresh >/dev/null 2>&1 || true
    ;;
  esac
}

# Install radp-bash-framework dependency by delegating to its install.sh
# Arguments:
#   $1 - mode: homebrew, dnf, yum, apt, zypper, or manual
install_radp_bf() {
  local mode="$1"

  if have radp-bf; then
    log "radp-bash-framework is already installed"
    return 0
  fi

  log "Installing radp-bash-framework dependency..."

  local install_url="https://raw.githubusercontent.com/xooooooooox/radp-bash-framework/main/install.sh"
  local bin_dir="${OPT_BIN_DIR:-$HOME/.local/bin}"

  # Delegate to radp-bash-framework's install.sh with the same mode
  if have curl; then
    curl -fsSL "${install_url}" | bash -s -- --mode "${mode}" --bin-dir "${bin_dir}"
  elif have wget; then
    wget -qO- "${install_url}" | bash -s -- --mode "${mode}" --bin-dir "${bin_dir}"
  else
    die "curl or wget required to install radp-bash-framework"
  fi
}

# Install using package manager
install_via_pkm() {
  local pkm="$1"

  # Refresh cache to ensure we get the latest version
  refresh_cache "${pkm}"

  # Install radp-bash-framework first
  install_radp_bf "${pkm}" || die "Failed to install radp-bash-framework"

  log "Installing ${REPO_NAME} via ${pkm}..."

  case "${pkm}" in
  homebrew)
    brew install homelabctl
    ;;
  dnf)
    sudo dnf install -y homelabctl
    ;;
  yum)
    sudo yum install -y homelabctl
    ;;
  apt)
    sudo apt-get install -y homelabctl
    ;;
  zypper)
    sudo zypper install -y homelabctl
    ;;
  *)
    err "Unknown package manager: ${pkm}"
    return 1
    ;;
  esac
}

# ============================================================================
# Manual Installation
# ============================================================================

detect_fetcher() {
  if have curl; then
    echo "curl"
    return 0
  fi
  if have wget; then
    echo "wget"
    return 0
  fi
  if have fetch; then
    echo "fetch"
    return 0
  fi
  return 1
}

fetch_url() {
  local tool="$1"
  local url="$2"
  local out="$3"

  case "${tool}" in
  curl)
    curl -fsSL "${url}" -o "${out}"
    ;;
  wget)
    wget -qO "${out}" "${url}"
    ;;
  fetch)
    fetch -qo "${out}" "${url}"
    ;;
  *)
    return 1
    ;;
  esac
}

fetch_text() {
  local tool="$1"
  local url="$2"

  case "${tool}" in
  curl)
    curl -fsSL "${url}"
    ;;
  wget)
    wget -qO- "${url}"
    ;;
  fetch)
    fetch -qo- "${url}"
    ;;
  *)
    return 1
    ;;
  esac
}

resolve_ref() {
  if [[ -n "${OPT_REF}" ]]; then
    echo "${OPT_REF}"
    return 0
  fi

  if [[ -n "${OPT_VERSION}" ]]; then
    echo "${OPT_VERSION}"
    return 0
  fi

  local api_url="https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/releases/latest"
  local json
  json="$(fetch_text "${FETCH_TOOL}" "${api_url}" || true)"
  if [[ -z "${json}" ]]; then
    die "Failed to fetch latest release; use --ref <branch|tag> to specify."
  fi

  local tag
  tag="$(sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' <<<"${json}")"
  tag="${tag%%$'\n'*}"
  if [[ -z "${tag}" ]]; then
    die "Failed to parse latest tag; use --ref <branch|tag> to specify."
  fi
  echo "${tag}"
}

cleanup() {
  if [[ -n "${tmp_dir:-}" ]]; then
    rm -rf "${tmp_dir}"
  fi
}

install_manual() {
  FETCH_TOOL="$(detect_fetcher)" || die "Requires curl, wget, or fetch."

  local install_dir="${OPT_INSTALL_DIR:-$HOME/.local/lib/${REPO_NAME}}"
  local bin_dir="${OPT_BIN_DIR:-$HOME/.local/bin}"
  local ref
  ref="$(resolve_ref)"

  # Install radp-bash-framework first
  install_radp_bf "manual" || die "Failed to install radp-bash-framework"

  if [[ -z "${install_dir}" || "${install_dir}" == "/" ]]; then
    die "Unsafe install dir: ${install_dir}"
  fi
  if [[ "${HOMELABCTL_ALLOW_ANY_DIR:-0}" != "1" ]]; then
    if [[ "$(basename "${install_dir}")" != "${REPO_NAME}" ]]; then
      die "Install dir must end with ${REPO_NAME} (set HOMELABCTL_ALLOW_ANY_DIR=1 to override)."
    fi
  fi

  local tar_url="https://github.com/${REPO_OWNER}/${REPO_NAME}/archive/${ref}.tar.gz"
  tmp_dir="$(mktemp -d 2>/dev/null || mktemp -d -t "${REPO_NAME}")"
  local tarball="${tmp_dir}/${REPO_NAME}.tar.gz"
  trap cleanup EXIT

  log "Downloading ${tar_url}"
  if ! fetch_url "${FETCH_TOOL}" "${tar_url}" "${tarball}"; then
    die "Failed to download ${tar_url}"
  fi

  local tar_listing
  tar_listing="$(tar -tzf "${tarball}")"
  local root_dir="${tar_listing%%/*}"
  if [[ -z "${root_dir}" ]]; then
    die "Unable to read archive structure."
  fi

  tar -xzf "${tarball}" -C "${tmp_dir}"
  local src_root="${tmp_dir}/${root_dir}"
  if [[ ! -d "${src_root}/bin" || ! -d "${src_root}/src" ]]; then
    die "Archive layout unexpected; missing bin/ or src/."
  fi

  rm -rf "${install_dir}"
  mkdir -p "${install_dir}"
  cp -R "${src_root}/bin" "${install_dir}/"
  cp -R "${src_root}/src" "${install_dir}/"

  # Remove IDE support files (development only, not needed at runtime)
  find "${install_dir}/src" -name "_ide*.sh" -delete 2>/dev/null || true

  chmod 0755 "${install_dir}/bin/homelabctl"
  find "${install_dir}/src" -type f -name "*.sh" -exec chmod 0755 {} \;

  # Write install method marker for uninstall.sh
  echo "manual" >"${install_dir}/.install-method"
  echo "${ref}" >"${install_dir}/.install-ref"

  # Write actual installed version for banner display
  local installed_version
  if [[ "${ref}" =~ ^v[0-9]+\.[0-9]+ ]]; then
    # ref is a version tag, use it directly
    installed_version="${ref}"
  else
    # ref is branch/SHA, append to base version from source
    local base_version
    base_version=$(grep -oE 'version:[[:space:]]*v[0-9]+\.[0-9]+\.[0-9]+' \
      "${install_dir}/src/main/shell/config/config.yaml" 2>/dev/null \
      | head -1 | sed 's/.*version:[[:space:]]*//' || echo "v0.0.0")
    installed_version="${base_version}+${ref}"
  fi
  echo "${installed_version}" >"${install_dir}/.install-version"

  mkdir -p "${bin_dir}"
  local target="${install_dir}/bin/homelabctl"
  local link_path="${bin_dir}/homelabctl"
  if [[ -e "${link_path}" && ! -L "${link_path}" ]]; then
    die "Refusing to overwrite existing file: ${link_path}"
  fi
  ln -sf "${target}" "${link_path}"

  log ""
  log "Installed ${REPO_NAME} (ref: ${ref}) to ${install_dir}"
  log "Symlinked to ${link_path}"
  log "Ensure ${bin_dir} is in your PATH."
}

setup_completion() {
  local bin_dir="${OPT_BIN_DIR:-$HOME/.local/bin}"
  local install_dir="${OPT_INSTALL_DIR:-$HOME/.local/lib/${REPO_NAME}}"
  local homelabctl_cmd=""

  # Find homelabctl command - prefer system path, then bin_dir, then install_dir
  if have homelabctl; then
    homelabctl_cmd="homelabctl"
  elif [[ -x "${bin_dir}/homelabctl" ]]; then
    homelabctl_cmd="${bin_dir}/homelabctl"
  elif [[ -x "${install_dir}/bin/homelabctl" ]]; then
    homelabctl_cmd="${install_dir}/bin/homelabctl"
  fi

  # For package manager installs, try system paths
  if [[ -z "${homelabctl_cmd}" ]]; then
    for path in /usr/bin/homelabctl /usr/local/bin/homelabctl /opt/homebrew/bin/homelabctl; do
      if [[ -x "${path}" ]]; then
        homelabctl_cmd="${path}"
        break
      fi
    done
  fi

  if [[ -z "${homelabctl_cmd}" ]]; then
    log "Warning: homelabctl not found, skipping completion setup"
    return 0
  fi

  local cmd="${homelabctl_cmd}"

  # Detect user's shell
  local user_shell
  user_shell="$(basename "${SHELL:-/bin/bash}")"

  case "${user_shell}" in
  bash)
    setup_bash_completion "${cmd}"
    ;;
  zsh)
    setup_zsh_completion "${cmd}"
    ;;
  *)
    log "Unknown shell: ${user_shell}, skipping completion setup"
    log "Run 'homelabctl completion bash' or 'homelabctl completion zsh' manually"
    ;;
  esac
}

setup_bash_completion() {
  local cmd="$1"
  local comp_dir="$HOME/.local/share/bash-completion/completions"
  local comp_file="${comp_dir}/homelabctl"

  log "Setting up bash completion..."

  # Create completions directory
  mkdir -p "${comp_dir}"

  # Generate completion script
  if "${cmd}" completion bash >"${comp_file}" 2>/dev/null; then
    log "Bash completion installed to ${comp_file}"
  else
    log "Warning: Failed to generate bash completion"
    return 0
  fi

  # Check if bash-completion is installed
  if ! have bash; then
    return 0
  fi

  # Hint about bash-completion package
  local bash_completion_loaded=false
  if [[ -f /usr/share/bash-completion/bash_completion ]] ||
    [[ -f /etc/bash_completion ]] ||
    [[ -f /opt/homebrew/etc/profile.d/bash_completion.sh ]] ||
    [[ -f /usr/local/etc/profile.d/bash_completion.sh ]]; then
    bash_completion_loaded=true
  fi

  if [[ "${bash_completion_loaded}" != "true" ]]; then
    log ""
    log "Note: bash-completion package may not be installed."
    log "Install it for completion to work:"
    local os
    os="$(detect_os)"
    case "${os}" in
    macos)
      log "  brew install bash-completion@2"
      ;;
    rhel)
      log "  sudo dnf install bash-completion"
      ;;
    debian)
      log "  sudo apt install bash-completion"
      ;;
    esac
  fi
}

setup_zsh_completion() {
  local cmd="$1"
  local comp_dir="$HOME/.zfunc"
  local comp_file="${comp_dir}/_homelabctl"

  log "Setting up zsh completion..."

  # Create completions directory
  mkdir -p "${comp_dir}"

  # Generate completion script
  if "${cmd}" completion zsh >"${comp_file}" 2>/dev/null; then
    log "Zsh completion installed to ${comp_file}"
  else
    log "Warning: Failed to generate zsh completion"
    return 0
  fi

  # Check if fpath includes the directory
  log ""
  log "Ensure ~/.zfunc is in your fpath. Add to ~/.zshrc:"
  log '  fpath=(~/.zfunc $fpath)'
  log '  autoload -Uz compinit && compinit'
}

print_post_install() {
  local bin_dir="${OPT_BIN_DIR:-$HOME/.local/bin}"

  log ""

  # Setup completion
  setup_completion

  log ""
  log "Installation complete!"

  # Check if bin_dir is in PATH
  if [[ ":$PATH:" != *":${bin_dir}:"* ]]; then
    log ""
    log "Note: ${bin_dir} is not in your PATH."
    log "Add it to your shell profile:"
    log "  export PATH=\"${bin_dir}:\$PATH\""
  fi

  log ""
  log "Run: hash -r && homelabctl --help"
}

# ============================================================================
# Main
# ============================================================================

main() {
  parse_args "$@"

  local mode="${OPT_MODE}"

  # --ref implies manual installation with pkm conflict resolution
  if [[ -n "${OPT_REF}" ]]; then
    log "Installing from ref: ${OPT_REF}"

    # Check for existing package-manager installation and remove it
    local existing_pkm
    existing_pkm="$(detect_pkm_installed)"
    if [[ -n "${existing_pkm}" ]]; then
      log "Detected existing package-manager installation (${existing_pkm})"
      uninstall_pkm "${existing_pkm}" || die "Failed to remove package-manager version"
    fi

    install_manual
    print_post_install
    return 0
  fi

  local pkm=""

  # Determine installation method
  case "${mode}" in
  manual)
    log "Using manual installation (--mode manual)"
    install_manual
    print_post_install
    return 0
    ;;
  homebrew | dnf | yum | apt | zypper)
    # Force specific package manager
    pkm="${mode}"
    if ! have "${pkm}" && [[ "${pkm}" != "homebrew" ]]; then
      die "Package manager '${pkm}' not found"
    fi
    if [[ "${pkm}" == "homebrew" ]] && ! have brew; then
      die "Homebrew not found"
    fi
    ;;
  auto | "")
    # Auto-detect package manager
    pkm="$(detect_package_manager)"
    if [[ -z "${pkm}" ]]; then
      log "No supported package manager detected, using manual installation"
      install_manual
      print_post_install
      return 0
    fi
    log "Detected package manager: ${pkm}"
    ;;
  *)
    die "Unknown install mode: ${mode}. Use: auto, manual, homebrew, dnf, yum, apt, zypper"
    ;;
  esac

  # Check for existing manual installation and remove it
  local manual_install_dir="${OPT_INSTALL_DIR:-$HOME/.local/lib/${REPO_NAME}}"
  if [[ -f "${manual_install_dir}/.install-method" ]] &&
    [[ "$(cat "${manual_install_dir}/.install-method")" == "manual" ]]; then
    log "Detected existing manual installation at ${manual_install_dir}"
    log "Removing manual installation to avoid conflicts..."
    local manual_bin_dir="${OPT_BIN_DIR:-$HOME/.local/bin}"
    local manual_link="${manual_bin_dir}/homelabctl"
    if [[ -L "${manual_link}" ]]; then
      rm -f "${manual_link}"
    fi
    rm -rf "${manual_install_dir}"
    log "Manual installation removed"
  fi

  # Setup repository if needed
  if ! check_repo_configured "${pkm}"; then
    log "Repository not configured for ${pkm}"
    setup_repo "${pkm}" || {
      err "Failed to setup repository, falling back to manual installation"
      install_manual
      print_post_install
      return 0
    }
  fi

  # Install via package manager
  install_via_pkm "${pkm}" || {
    err "Package manager installation failed, falling back to manual installation"
    install_manual
    print_post_install
    return 0
  }

  log "Successfully installed ${REPO_NAME} via ${pkm}"
  print_post_install
}

main "$@"
