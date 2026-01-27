#!/usr/bin/env bash
# jq installer

_setup_install_jq() {
    local version="${1:-latest}"

    if _setup_is_installed jq && [[ "$version" == "latest" ]]; then
        radp_log_info "jq is already installed"
        return 0
    fi

    local pm
    pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

    case "$pm" in
        brew)
            radp_log_info "Installing jq via Homebrew..."
            brew install jq || return 1
            ;;
        dnf|yum)
            radp_log_info "Installing jq via dnf..."
            radp_os_install_pkgs jq || return 1
            ;;
        apt|apt-get)
            radp_log_info "Installing jq via apt..."
            radp_os_install_pkgs jq || return 1
            ;;
        pacman)
            radp_log_info "Installing jq via pacman..."
            radp_os_install_pkgs jq || return 1
            ;;
        *)
            _setup_jq_from_release "$version"
            ;;
    esac
}

_setup_jq_from_release() {
    local version="$1"

    # Get latest version if needed
    if [[ "$version" == "latest" ]]; then
        version=$(_setup_github_latest_version "jqlang/jq")
        [[ -z "$version" ]] && version="1.7.1"
    fi

    local arch os
    arch=$(_setup_get_arch)
    os=$(_setup_get_os)

    # Map OS/arch to release naming
    local binary_name
    case "$os" in
        darwin)
            binary_name="jq-macos-amd64"
            [[ "$arch" == "arm64" ]] && binary_name="jq-macos-arm64"
            ;;
        linux)
            binary_name="jq-linux-amd64"
            [[ "$arch" == "arm64" ]] && binary_name="jq-linux-arm64"
            ;;
        *)
            radp_log_error "Unsupported OS: $os"
            return 1
            ;;
    esac

    local url="https://github.com/jqlang/jq/releases/download/jq-${version}/${binary_name}"

    local tmpdir
    tmpdir=$(_setup_mktemp_dir)
    trap 'rm -rf "$tmpdir"; trap - RETURN' RETURN

    radp_log_info "Downloading jq $version..."
    radp_io_download "$url" "$tmpdir/jq" || return 1

    chmod +x "$tmpdir/jq"
    _setup_install_binary "$tmpdir/jq" || return 1
}
