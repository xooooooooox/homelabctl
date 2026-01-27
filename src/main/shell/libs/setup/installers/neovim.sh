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
            radp_os_install_pkgs neovim || return 1
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

    local tmpdir
    tmpdir=$(_setup_mktemp_dir)
    trap 'rm -rf "$tmpdir"' RETURN

    case "$os" in
        darwin)
            local filename="nvim-macos-${arch}.tar.gz"
            local tag="$version"
            [[ "$version" == "stable" ]] && tag="stable"
            local url="https://github.com/neovim/neovim/releases/download/${tag}/${filename}"

            radp_log_info "Downloading neovim $version..."
            radp_io_download "$url" "$tmpdir/$filename" || return 1

            _setup_extract_archive "$tmpdir/$filename" "$tmpdir" || return 1

            # Move to /usr/local
            local sudo_cmd=""
            [[ ! -w "/usr/local" ]] && sudo_cmd="${gr_sudo:-sudo}"

            $sudo_cmd rm -rf /usr/local/nvim
            $sudo_cmd mv "$tmpdir/nvim-macos-${arch}" /usr/local/nvim || return 1
            $sudo_cmd ln -sf /usr/local/nvim/bin/nvim /usr/local/bin/nvim || return 1
            ;;
        linux)
            # Use AppImage on Linux
            local filename="nvim.appimage"
            local tag="$version"
            [[ "$version" == "stable" ]] && tag="stable"
            local url="https://github.com/neovim/neovim/releases/download/${tag}/${filename}"

            radp_log_info "Downloading neovim $version (AppImage)..."
            radp_io_download "$url" "$tmpdir/$filename" || return 1

            chmod +x "$tmpdir/$filename"

            # Try to extract AppImage (better compatibility)
            if "$tmpdir/$filename" --appimage-extract &>/dev/null; then
                local sudo_cmd=""
                [[ ! -w "/usr/local/bin" ]] && sudo_cmd="${gr_sudo:-sudo}"

                $sudo_cmd rm -rf /usr/local/nvim
                $sudo_cmd mv "$tmpdir/squashfs-root" /usr/local/nvim
                $sudo_cmd ln -sf /usr/local/nvim/usr/bin/nvim /usr/local/bin/nvim
            else
                # Use AppImage directly
                _setup_install_binary "$tmpdir/$filename" "nvim" || return 1
            fi
            ;;
        *)
            radp_log_error "Unsupported OS: $os"
            return 1
            ;;
    esac
}
