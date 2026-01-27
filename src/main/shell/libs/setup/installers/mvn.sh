#!/usr/bin/env bash
# maven installer

_setup_install_mvn() {
  local version="${1:-latest}"

  if _setup_is_installed mvn && [[ "$version" == "latest" ]]; then
    radp_log_info "maven is already installed"
    return 0
  fi

  local pm
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

  case "$pm" in
  brew)
    radp_log_info "Installing maven via Homebrew..."
    brew install maven || return 1
    ;;
  *)
    _setup_mvn_from_apache "$version"
    ;;
  esac
}

_setup_mvn_from_apache() {
  local version="$1"
  [[ "$version" == "latest" ]] && version="3.9.12"

  local tmpdir
  tmpdir=$(_setup_mktemp_dir)
  trap 'rm -rf "$tmpdir"; trap - RETURN' RETURN

  local filename="apache-maven-${version}-bin.tar.gz"
  local url="https://dlcdn.apache.org/maven/maven-3/${version}/binaries/${filename}"

  radp_log_info "Downloading maven $version..."
  radp_io_download "$url" "$tmpdir/$filename" || return 1

  _setup_extract_archive "$tmpdir/$filename" "$tmpdir" || return 1

  local install_dir="/opt/maven"
  $gr_sudo mkdir -p "$install_dir" || return 1
  $gr_sudo rm -rf "$install_dir/apache-maven-${version}" || return 1
  $gr_sudo mv "$tmpdir/apache-maven-${version}" "$install_dir/" || return 1
  $gr_sudo ln -snf "$install_dir/apache-maven-${version}" "$install_dir/current" || return 1
  $gr_sudo ln -sf "$install_dir/current/bin/mvn" /usr/local/bin/mvn || return 1

  radp_log_info "Maven installed to $install_dir/apache-maven-${version}"
}
