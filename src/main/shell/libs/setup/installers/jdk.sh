#!/usr/bin/env bash
# JDK installer

_setup_install_jdk() {
  local version="${1:-latest}"

  if _setup_is_installed java && [[ "$version" == "latest" ]]; then
    radp_log_info "jdk is already installed"
    return 0
  fi

  local pm
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

  # Check if vfox is available for version management
  if _setup_is_installed vfox; then
    _setup_jdk_via_vfox "$version"
    return $?
  fi

  # Check if sdkman is available
  if [[ -n "${SDKMAN_DIR:-}" ]] && [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]]; then
    _setup_jdk_via_sdkman "$version"
    return $?
  fi

  # Fall back to system package manager or manual install
  case "$pm" in
  brew)
    radp_log_info "Installing JDK via Homebrew..."
    if [[ "$version" == "latest" ]]; then
      brew install openjdk || return 1
    else
      brew install "openjdk@${version}" || return 1
    fi
    # Create symlink for system Java wrappers
    local jdk_path
    jdk_path=$(brew --prefix openjdk 2>/dev/null || brew --prefix "openjdk@${version}" 2>/dev/null)
    if [[ -n "$jdk_path" ]]; then
      sudo ln -sfn "$jdk_path/libexec/openjdk.jdk" /Library/Java/JavaVirtualMachines/openjdk.jdk 2>/dev/null || true
    fi
    ;;
  dnf | yum)
    radp_log_info "Installing JDK via dnf..."
    local pkg_version="${version}"
    [[ "$version" == "latest" ]] && pkg_version="21"
    radp_os_install_pkgs "java-${pkg_version}-openjdk-devel" || return 1
    ;;
  apt | apt-get)
    radp_log_info "Installing JDK via apt..."
    local pkg_version="${version}"
    [[ "$version" == "latest" ]] && pkg_version="21"
    radp_os_install_pkgs "openjdk-${pkg_version}-jdk" || return 1
    ;;
  pacman)
    radp_log_info "Installing JDK via pacman..."
    local pkg_version="${version}"
    [[ "$version" == "latest" ]] && pkg_version="21"
    radp_os_install_pkgs "jdk${pkg_version}-openjdk" || return 1
    ;;
  *)
    _setup_jdk_from_adoptium "$version"
    ;;
  esac
}

_setup_jdk_via_vfox() {
  local version="$1"

  radp_log_info "Installing JDK via vfox..."

  # Ensure java plugin is added
  if ! vfox list java &>/dev/null; then
    vfox add java || return 1
  fi

  if [[ "$version" == "latest" ]]; then
    version="21" # LTS
  fi

  vfox install "java@$version" || return 1
  vfox use --global "java@$version" 2>/dev/null || true
  _setup_vfox_refresh_path
}

_setup_jdk_via_sdkman() {
  local version="$1"

  radp_log_info "Installing JDK via SDKMAN..."

  # Source sdkman
  # shellcheck source=/dev/null
  source "$SDKMAN_DIR/bin/sdkman-init.sh"

  if [[ "$version" == "latest" ]]; then
    # Install latest Temurin LTS
    sdk install java 21-tem || return 1
    sdk default java 21-tem || return 1
  else
    # Try to find matching Temurin version
    local candidate
    candidate=$(sdk list java 2>/dev/null | grep -E "${version}.*-tem" | head -1 | awk '{print $NF}')
    if [[ -n "$candidate" ]]; then
      sdk install java "$candidate" || return 1
      sdk default java "$candidate" || return 1
    else
      radp_log_warn "Temurin $version not found, installing OpenJDK..."
      sdk install java "${version}-open" || return 1
      sdk default java "${version}-open" || return 1
    fi
  fi
}

_setup_jdk_from_adoptium() {
  local version="$1"

  # Get version
  local major_version
  if [[ "$version" == "latest" ]]; then
    major_version="21"
  else
    major_version="${version%%.*}"
  fi

  local arch os
  arch=$(_setup_get_arch)
  os=$(_setup_get_os)

  # Map to Adoptium naming
  local adoptium_os="$os"
  [[ "$os" == "darwin" ]] && adoptium_os="mac"

  local adoptium_arch="x64"
  [[ "$arch" == "arm64" ]] && adoptium_arch="aarch64"

  # Adoptium API to get download URL
  local api_url="https://api.adoptium.net/v3/binary/latest/${major_version}/ga/${adoptium_os}/${adoptium_arch}/jdk/hotspot/normal/eclipse"

  local tmpdir
  tmpdir=$(_setup_mktemp_dir)
  trap 'rm -rf "$tmpdir"; trap - RETURN' RETURN

  local filename="jdk.tar.gz"

  radp_log_info "Downloading Temurin JDK $major_version..."
  radp_io_download "$api_url" "$tmpdir/$filename" || return 1

  _setup_extract_archive "$tmpdir/$filename" "$tmpdir" || return 1

  # Find extracted directory
  local jdk_dir
  jdk_dir=$(find "$tmpdir" -maxdepth 1 -type d -name "jdk-*" | head -1)
  if [[ -z "$jdk_dir" ]]; then
    jdk_dir=$(find "$tmpdir" -maxdepth 1 -type d -name "OpenJDK*" | head -1)
  fi

  if [[ -z "$jdk_dir" ]]; then
    radp_log_error "Could not find extracted JDK directory"
    return 1
  fi

  # Install to appropriate location
  local install_dir="/usr/local/java"

  $gr_sudo mkdir -p "$install_dir" || return 1
  $gr_sudo rm -rf "$install_dir/jdk-${major_version}" || return 1
  $gr_sudo mv "$jdk_dir" "$install_dir/jdk-${major_version}" || return 1

  # Create symlinks
  $gr_sudo ln -sf "$install_dir/jdk-${major_version}/bin/java" /usr/local/bin/java || return 1
  $gr_sudo ln -sf "$install_dir/jdk-${major_version}/bin/javac" /usr/local/bin/javac || return 1

  radp_log_info "JDK installed to $install_dir/jdk-${major_version}"
  radp_log_info "Set JAVA_HOME=$install_dir/jdk-${major_version}"
}
