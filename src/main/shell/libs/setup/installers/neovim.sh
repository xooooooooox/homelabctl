#!/usr/bin/env bash
# neovim installer

_setup_install_neovim() {
    local version="${1:-latest}"

    if _setup_is_installed nvim && [[ "$version" == "latest" ]]; then
        radp_log_info "neovim is already installed"
        return 0
    fi

    local pm
    pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

    case "$pm" in
        brew)
            radp_log_info "Installing neovim via Homebrew..."
            brew install neovim || return 1
            ;;
        dnf|yum)
            radp_log_info "Installing neovim via dnf..."
            if ! radp_os_install_pkgs neovim 2>/dev/null; then
                radp_log_info "neovim not available in repos, falling back to binary release..."
                _setup_neovim_from_release "$version"
            fi
            ;;
        apt|apt-get)
            # apt version is often outdated, use appimage or PPA
            _setup_neovim_from_release "$version"
            ;;
        pacman)
            radp_log_info "Installing neovim via pacman..."
            radp_os_install_pkgs neovim || return 1
            ;;
        *)
            _setup_neovim_from_release "$version"
            ;;
    esac
}

_setup_neovim_from_release() {
    local version="$1"

    # Get latest version if needed
    if [[ "$version" == "latest" ]]; then
        version=$(_setup_github_latest_version "neovim/neovim")
        # If getting latest fails, use stable
        [[ -z "$version" ]] && version="stable"
    fi

    local arch os
    arch=$(_setup_get_arch)
    os=$(_setup_get_os)

    # Map arch to neovim release naming (uses x86_64 not amd64)
    local nvim_arch="$arch"
    [[ "$arch" == "amd64" ]] && nvim_arch="x86_64"

    local tmpdir
    tmpdir=$(_setup_mktemp_dir)
    trap 'rm -rf "$tmpdir"; trap - RETURN' RETURN

    # Build release tag: version "stable" stays as-is, others get "v" prefix
    local tag
    if [[ "$version" == "stable" ]]; then
        tag="stable"
    else
        tag="v${version}"
    fi

    case "$os" in
        darwin)
            local filename="nvim-macos-${nvim_arch}.tar.gz"
            local url="https://github.com/neovim/neovim/releases/download/${tag}/${filename}"

            radp_log_info "Downloading neovim $version..."
            radp_io_download "$url" "$tmpdir/$filename" || return 1

            _setup_extract_archive "$tmpdir/$filename" "$tmpdir" || return 1

            $gr_sudo rm -rf /usr/local/nvim
            $gr_sudo mv "$tmpdir/nvim-macos-${nvim_arch}" /usr/local/nvim || return 1
            $gr_sudo ln -sf /usr/local/nvim/bin/nvim /usr/local/bin/nvim || return 1
            ;;
        linux)
            local filename="nvim-linux-${nvim_arch}.tar.gz"
            local url="https://github.com/neovim/neovim/releases/download/${tag}/${filename}"

            radp_log_info "Downloading neovim $version..."
            radp_io_download "$url" "$tmpdir/$filename" || return 1

            _setup_extract_archive "$tmpdir/$filename" "$tmpdir" || return 1

            $gr_sudo rm -rf /usr/local/nvim
            $gr_sudo mv "$tmpdir/nvim-linux-${nvim_arch}" /usr/local/nvim || return 1
            $gr_sudo ln -sf /usr/local/nvim/bin/nvim /usr/local/bin/nvim || return 1
            ;;
        *)
            radp_log_error "Unsupported OS: $os"
            return 1
            ;;
    esac
}
