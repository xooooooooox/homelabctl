#!/usr/bin/env bash
# fd installer

_setup_install_fd() {
    local version="${1:-latest}"

    if _setup_is_installed fd && [[ "$version" == "latest" ]]; then
        radp_log_info "fd is already installed"
        return 0
    fi

    local pm
    pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

    case "$pm" in
        brew)
            radp_log_info "Installing fd via Homebrew..."
            brew install fd || return 1
            ;;
        dnf|yum)
            radp_log_info "Installing fd via dnf..."
            if ! radp_os_install_pkgs fd-find 2>/dev/null; then
                radp_log_info "fd-find not available in repos, falling back to binary release..."
                _setup_fd_from_release "$version"
            fi
            ;;
        apt|apt-get)
            radp_log_info "Installing fd via apt..."
            # fd is called 'fd-find' on Debian/Ubuntu, binary is 'fdfind'
            radp_os_install_pkgs fd-find || return 1
            # Create symlink if needed
            if _setup_is_installed fdfind && ! _setup_is_installed fd; then
                mkdir -p "$HOME/.local/bin"
                ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
                radp_log_info "Created symlink: fd -> fdfind"
            fi
            ;;
        pacman)
            radp_log_info "Installing fd via pacman..."
            radp_os_install_pkgs fd || return 1
            ;;
        *)
            _setup_fd_from_release "$version"
            ;;
    esac
}

_setup_fd_from_release() {
    local version="$1"

    # Get latest version if needed
    if [[ "$version" == "latest" ]]; then
        version=$(_setup_github_latest_version "sharkdp/fd")
        [[ -z "$version" ]] && version="10.1.0"
    fi

    local arch os
    arch=$(_setup_get_arch)
    os=$(_setup_get_os)

    # Map OS/arch to release naming
    local target
    case "$os" in
        darwin)
            target="fd-v${version}-x86_64-apple-darwin"
            [[ "$arch" == "arm64" ]] && target="fd-v${version}-aarch64-apple-darwin"
            ;;
        linux)
            target="fd-v${version}-x86_64-unknown-linux-musl"
            [[ "$arch" == "arm64" ]] && target="fd-v${version}-aarch64-unknown-linux-gnu"
            ;;
        *)
            radp_log_error "Unsupported OS: $os"
            return 1
            ;;
    esac

    local filename="${target}.tar.gz"
    local url="https://github.com/sharkdp/fd/releases/download/v${version}/${filename}"

    local tmpdir
    tmpdir=$(_setup_mktemp_dir)
    trap 'rm -rf "$tmpdir"; trap - RETURN' RETURN

    radp_log_info "Downloading fd $version..."
    radp_io_download "$url" "$tmpdir/$filename" || return 1

    _setup_extract_archive "$tmpdir/$filename" "$tmpdir" || return 1
    _setup_install_binary "$tmpdir/$target/fd" || return 1
}
