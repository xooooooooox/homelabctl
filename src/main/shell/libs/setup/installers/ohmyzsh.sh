#!/usr/bin/env bash
# oh-my-zsh installer

_setup_install_ohmyzsh() {
  local version="${1:-latest}"

  if [[ -d "${ZSH:-$HOME/.oh-my-zsh}" ]]; then
    radp_log_info "oh-my-zsh is already installed"
    return 0
  fi

  # zsh is required
  if ! _setup_is_installed zsh; then
    radp_log_error "zsh is required to install oh-my-zsh. Install zsh first."
    return 1
  fi

  local tmpdir
  tmpdir=$(_setup_mktemp_dir)
  trap 'rm -rf "$tmpdir"; trap - RETURN' RETURN

  radp_log_info "Installing oh-my-zsh..."
  radp_io_download "https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh" "$tmpdir/install.sh" || return 1

  # Run unattended install (RUNZSH=no prevents switching shell immediately)
  RUNZSH=no CHSH=no sh "$tmpdir/install.sh" || return 1
}
