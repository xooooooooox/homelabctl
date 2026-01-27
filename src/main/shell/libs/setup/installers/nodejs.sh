#!/usr/bin/env bash
# nodejs installer

_setup_install_nodejs() {
    local version="${1:-latest}"

    if _setup_is_installed node && [[ "$version" == "latest" ]]; then
        radp_log_info "nodejs is already installed"
        return 0
    fi

    local pm
    pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

    # Check if vfox is available for version management
    if _setup_is_installed vfox; then
        _setup_nodejs_via_vfox "$version"
        return $?
    fi

    # Check if nvm is available
    if [[ -n "${NVM_DIR:-}" ]] && [[ -s "$NVM_DIR/nvm.sh" ]]; then
        _setup_nodejs_via_nvm "$version"
        return $?
    fi

    # Fall back to system package manager or manual install
    case "$pm" in
        brew)
            radp_log_info "Installing nodejs via Homebrew..."
            if [[ "$version" == "latest" ]]; then
                brew install node || return 1
            else
                # Use specific version
                brew install "node@${version%%.*}" || return 1
            fi
            ;;
        dnf|yum)
            radp_log_info "Installing nodejs via dnf..."
            radp_os_install_pkgs nodejs npm || return 1
            ;;
        apt|apt-get)
            _setup_nodejs_from_nodesource "$version"
            ;;
        pacman)
            radp_log_info "Installing nodejs via pacman..."
            radp_os_install_pkgs nodejs npm || return 1
            ;;
        *)
            _setup_nodejs_from_binary "$version"
            ;;
    esac
}

_setup_nodejs_via_vfox() {
    local version="$1"

    radp_log_info "Installing nodejs via vfox..."

    # Ensure nodejs plugin is added
    if ! vfox list nodejs &>/dev/null; then
        vfox add nodejs || return 1
    fi

    if [[ "$version" == "latest" ]]; then
        # Get latest LTS version
        version=$(vfox search nodejs 2>/dev/null | grep -E "lts" | head -1 | awk '{print $1}')
        [[ -z "$version" ]] && version="20"
    fi

    vfox install "nodejs@$version" || return 1
    # vfox use --global may fail in non-interactive shells without vfox activate,
    # but it still writes to ~/.vfox/.tool-versions successfully
    if ! vfox use --global "nodejs@$version" 2>/dev/null; then
        radp_log_info "Set nodejs@$version as global default. Run 'vfox activate' in your shell to use it."
    fi
}

_setup_nodejs_via_nvm() {
    local version="$1"

    radp_log_info "Installing nodejs via nvm..."

    # Source nvm
    # shellcheck source=/dev/null
    source "$NVM_DIR/nvm.sh"

    if [[ "$version" == "latest" ]]; then
        nvm install --lts || return 1
        nvm use --lts || return 1
        nvm alias default lts/* || return 1
    else
        nvm install "$version" || return 1
        nvm use "$version" || return 1
        nvm alias default "$version" || return 1
    fi
}

_setup_nodejs_from_nodesource() {
    local version="$1"

    radp_log_info "Installing nodejs from NodeSource..."

    # Determine major version
    local major_version
    if [[ "$version" == "latest" ]]; then
        major_version="20"  # LTS
    else
        major_version="${version%%.*}"
    fi

    # Download and run NodeSource setup script
    local tmpdir
    tmpdir=$(_setup_mktemp_dir)
    trap 'rm -rf "$tmpdir"; trap - RETURN' RETURN

    local setup_url="https://deb.nodesource.com/setup_${major_version}.x"
    radp_io_download "$setup_url" "$tmpdir/setup.sh" || return 1

    $gr_sudo bash "$tmpdir/setup.sh" || return 1
    radp_os_install_pkgs nodejs || return 1
}

_setup_nodejs_from_binary() {
    local version="$1"

    # Get version if latest
    if [[ "$version" == "latest" ]]; then
        version=$(_setup_github_latest_version "nodejs/node")
        [[ -z "$version" ]] && version="20.10.0"
    fi

    local arch os
    arch=$(_setup_get_arch)
    os=$(_setup_get_os)

    # Map to nodejs naming
    local node_arch="x64"
    [[ "$arch" == "arm64" ]] && node_arch="arm64"

    local filename="node-v${version}-${os}-${node_arch}.tar.gz"
    local url="https://nodejs.org/dist/v${version}/${filename}"

    local tmpdir
    tmpdir=$(_setup_mktemp_dir)
    trap 'rm -rf "$tmpdir"; trap - RETURN' RETURN

    radp_log_info "Downloading nodejs $version..."
    radp_io_download "$url" "$tmpdir/$filename" || return 1

    _setup_extract_archive "$tmpdir/$filename" "$tmpdir" || return 1

    # Install to /usr/local
    $gr_sudo cp -r "$tmpdir/node-v${version}-${os}-${node_arch}"/* /usr/local/ || return 1
}
