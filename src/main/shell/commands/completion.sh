#!/usr/bin/env bash
# @cmd
# @desc Generate shell completion script
# @arg shell! Shell type (bash or zsh)
# @arg-values shell bash zsh
# @example completion bash > ~/.local/share/bash-completion/completions/homelabctl
# @example completion zsh > ~/.zfunc/_homelabctl

cmd_completion() {
  local shell="${1:-}"

  if [[ -z "$shell" ]]; then
    radp_cli_help_command "completion"
    return 1
  fi

  case "$shell" in
  bash)
    # For bash: helpers first, then completion script with vf delegation
    _completion_output_helpers
    # Generate and replace the vf case with radp-vf delegation
    radp_cli_completion_generate "$shell" | sed "
        /^        'vf')$/,/^            ;;$/ c\\
        'vf')\\
            # Delegate to radp-vf completion\\
            if type _radp_vf \&>/dev/null; then\\
                # Set config from homelabctl config if not in command line\\
                local _hctl_vf_config_dir\\
                _hctl_vf_config_dir=\"\$(_homelabctl_vf_config_dir)\"\\
                [[ -n \"\$_hctl_vf_config_dir\" ]] && export RADP_VAGRANT_CONFIG_DIR=\"\$_hctl_vf_config_dir\"\\
                local _hctl_vf_env\\
                _hctl_vf_env=\"\$(_homelabctl_vf_env)\"\\
                [[ -n \"\$_hctl_vf_env\" ]] && export RADP_VAGRANT_ENV=\"\$_hctl_vf_env\"\\
                local radp_vf_words=(\"radp-vf\" \"\${words[@]:2}\")\\
                local radp_vf_cword=\$((cword - 1))\\
                COMP_WORDS=(\"\${radp_vf_words[@]}\")\\
                COMP_CWORD=\$radp_vf_cword\\
                COMP_LINE=\"\${radp_vf_words[*]}\"\\
                COMP_POINT=\${#COMP_LINE}\\
                _RADP_VF_DELEGATED=1 _radp_vf\\
            else\\
                # Fallback if radp-vf completion not loaded\\
                COMPREPLY=(\$(compgen -W \"completion dump-config generate info init list template validate version vg --help\" -- \"\$cur\"))\\
            fi\\
            ;;\\
        'vf '*)\\
            # Delegate vf subcommands to radp-vf completion\\
            if type _radp_vf \&>/dev/null; then\\
                # Set config from homelabctl config if not in command line\\
                local _hctl_vf_config_dir\\
                _hctl_vf_config_dir=\"\$(_homelabctl_vf_config_dir)\"\\
                [[ -n \"\$_hctl_vf_config_dir\" ]] && export RADP_VAGRANT_CONFIG_DIR=\"\$_hctl_vf_config_dir\"\\
                local _hctl_vf_env\\
                _hctl_vf_env=\"\$(_homelabctl_vf_env)\"\\
                [[ -n \"\$_hctl_vf_env\" ]] && export RADP_VAGRANT_ENV=\"\$_hctl_vf_env\"\\
                local radp_vf_words=(\"radp-vf\" \"\${words[@]:2}\")\\
                local radp_vf_cword=\$((cword - 1))\\
                COMP_WORDS=(\"\${radp_vf_words[@]}\")\\
                COMP_CWORD=\$radp_vf_cword\\
                COMP_LINE=\"\${radp_vf_words[*]}\"\\
                COMP_POINT=\${#COMP_LINE}\\
                _RADP_VF_DELEGATED=1 _radp_vf\\
            else\\
                COMPREPLY=()\\
            fi\\
            ;;
    "
    ;;
  zsh)
    # For zsh: #compdef must be first line
    echo "#compdef homelabctl"
    echo ""
    # Then helper functions
    _completion_output_helpers
    # Framework-generated script, but REMOVE "_homelabctl "$@"" line
    # so our override is defined BEFORE execution
    radp_cli_completion_generate "$shell" | tail -n +2 | sed '/^_homelabctl "\$@"$/d'
    # Custom overrides
    _completion_output_vf_zsh
    # Execution call at the very end (after all overrides)
    echo ''
    echo '_homelabctl "$@"'
    ;;
  *)
    radp_log_error "Unsupported shell: $shell (supported: bash, zsh)"
    return 1
    ;;
  esac
}

#######################################
# Output completion helper functions
# These are included in the generated completion script
#######################################
_completion_output_helpers() {
  cat <<'COMPLETION_HELPERS'
# homelabctl completion helper functions

_homelabctl_complete_packages() {
  homelabctl -q setup list --names-only 2>/dev/null
}

_homelabctl_complete_categories() {
  homelabctl -q setup list --category-names 2>/dev/null
}

_homelabctl_complete_profiles() {
  homelabctl -q setup profile list --names-only 2>/dev/null
}

# Get vf config_dir from homelabctl config (for completion delegation)
_homelabctl_vf_config_dir() {
  # Priority 1: Check if already set via env var
  if [[ -n "${RADP_VAGRANT_CONFIG_DIR:-}" ]]; then
    echo "$RADP_VAGRANT_CONFIG_DIR"
    return
  fi
  # Priority 2: Default homelabctl vf config location
  local default_dir="$HOME/.config/homelabctl/vagrant"
  if [[ -f "$default_dir/vagrant.yaml" ]]; then
    echo "$default_dir"
    return
  fi
  # Priority 3: Current directory if it has vagrant.yaml
  if [[ -f "./vagrant.yaml" ]]; then
    echo "."
    return
  fi
}

# Get vf env from homelabctl config
_homelabctl_vf_env() {
  # Check if set via env var
  if [[ -n "${RADP_VAGRANT_ENV:-}" ]]; then
    echo "$RADP_VAGRANT_ENV"
    return
  fi
  # Try to read from homelabctl's config.yaml
  local config_file="$HOME/.config/homelabctl/config.yaml"
  if [[ -f "$config_file" ]] && command -v yq &>/dev/null; then
    local env_val
    env_val=$(yq -r '.radp.env // empty' "$config_file" 2>/dev/null)
    [[ -n "$env_val" ]] && echo "$env_val"
  fi
}

COMPLETION_HELPERS
}

#######################################
# Output custom _homelabctl_vf for zsh
# Delegates to radp-vf completion for consistent experience
#######################################
_completion_output_vf_zsh() {
  cat <<'VF_ZSH'

# Override _homelabctl_vf to delegate to radp-vf's native completion
_homelabctl_vf() {
    # Set config from homelabctl config if not already set
    local _hctl_vf_config_dir _hctl_vf_env
    _hctl_vf_config_dir="$(_homelabctl_vf_config_dir)"
    [[ -n "$_hctl_vf_config_dir" ]] && export RADP_VAGRANT_CONFIG_DIR="$_hctl_vf_config_dir"
    _hctl_vf_env="$(_homelabctl_vf_env)"
    [[ -n "$_hctl_vf_env" ]] && export RADP_VAGRANT_ENV="$_hctl_vf_env"

    # Replace "vf" with "radp-vf" so _radp-vf sees the right command name
    words[1]="radp-vf"

    # Delegate to radp-vf completion (file _radp-vf, autoloaded by compinit)
    if (( $+functions[_radp-vf] )); then
        _radp-vf
    else
        _files
    fi
}
VF_ZSH
}
