#!/usr/bin/env bash
# fzf-tab-completion installer

_setup_install_fzf_tab_completion() {
  local version="${1:-latest}"
  local install_dir="${XDG_DATA_HOME:-$HOME/.local/share}/fzf-tab-completion"

  if [[ -d "$install_dir" ]] && [[ "$version" == "latest" ]]; then
    radp_log_info "fzf-tab-completion is already installed"
    return 0
  fi

  # fzf is required
  if ! _setup_is_installed fzf; then
    radp_log_error "fzf is required to install fzf-tab-completion. Install fzf first."
    return 1
  fi

  # git is required
  if ! _common_is_command_available git; then
    radp_log_error "git is required for fzf-tab-completion install but not found"
    return 1
  fi

  if [[ -d "$install_dir" ]]; then
    radp_log_info "Updating fzf-tab-completion..."
    git -C "$install_dir" pull || return 1
  else
    radp_log_info "Installing fzf-tab-completion..."
    git clone https://github.com/lincheney/fzf-tab-completion.git "$install_dir" || return 1
  fi

  radp_log_info "fzf-tab-completion installed to $install_dir"
  radp_log_info "Add the following to your shell config:"
  radp_log_info ""
  radp_log_info "  # For bash (~/.bashrc):"
  radp_log_info "  source $install_dir/bash/fzf-bash-completion.sh"
  radp_log_info "  bind -x '\"\\t\": fzf_bash_completion'"
  radp_log_info ""
  radp_log_info "  # For zsh (~/.zshrc):"
  radp_log_info "  source $install_dir/zsh/fzf-zsh-completion.sh"
  radp_log_info "  bindkey '^I' fzf_completion"
}
