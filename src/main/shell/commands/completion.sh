#!/usr/bin/env bash
# @cmd
# @desc Generate shell completion script
# @arg shell! Shell type (bash or zsh)
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
    # Output #compdef header first
    echo "#compdef homelabctl"
    echo ""
    # Then helper functions
    _completion_output_helpers
    # Then rest of completion script (skip the #compdef line from generator)
    radp_cli_completion_generate "$shell" | tail -n +2
    # Then custom overrides (redefine functions to override framework-generated ones)
    _completion_output_vf_zsh
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
  # Check if already set via env var
  if [[ -n "${RADP_VAGRANT_CONFIG_DIR:-}" ]]; then
    echo "$RADP_VAGRANT_CONFIG_DIR"
    return
  fi
  # Try to get from homelabctl config
  local config_dir
  config_dir=$(homelabctl -q --config --all --json 2>/dev/null | grep -o '"config_dir": *"[^"]*"' | head -1 | sed 's/"config_dir": *"\([^"]*\)"/\1/')
  [[ -n "$config_dir" ]] && echo "$config_dir"
}

# Get vf env from homelabctl config
_homelabctl_vf_env() {
  if [[ -n "${RADP_VAGRANT_ENV:-}" ]]; then
    echo "$RADP_VAGRANT_ENV"
    return
  fi
  local env_val
  env_val=$(homelabctl -q --config --all --json 2>/dev/null | grep -o '"env": *"[^"]*"' | tail -1 | sed 's/"env": *"\([^"]*\)"/\1/')
  [[ -n "$env_val" ]] && echo "$env_val"
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
    # Delegate to radp-vf's native completion for consistent experience
    if (( $+functions[_radp_vf] )); then
        # Set config from homelabctl config if not already set
        local _hctl_vf_config_dir _hctl_vf_env
        _hctl_vf_config_dir="$(_homelabctl_vf_config_dir)"
        [[ -n "$_hctl_vf_config_dir" ]] && export RADP_VAGRANT_CONFIG_DIR="$_hctl_vf_config_dir"
        _hctl_vf_env="$(_homelabctl_vf_env)"
        [[ -n "$_hctl_vf_env" ]] && export RADP_VAGRANT_ENV="$_hctl_vf_env"
        # In args state, words[1] is "vf" - just replace with "radp-vf"
        # CURRENT is already correct, no adjustment needed
        words[1]="radp-vf"
        _radp_vf
    else
        # Fallback if radp-vf completion not loaded
        local context state state_descr line
        typeset -A opt_args

        _arguments -C \
            '(-h --help)'{-h,--help}'[Show help]' \
            '1: :->command' \
            '*:: :->args'

        case "$state" in
            command)
                local -a radp_vf_cmds=(
                    'completion:Generate shell completion script'
                    'dump-config:Dump merged configuration'
                    'generate:Generate standalone Vagrantfile'
                    'info:Show environment and configuration info'
                    'init:Initialize a new project with sample configuration'
                    'list:List clusters and guests from configuration'
                    'template:Manage project templates'
                    'validate:Validate YAML configuration files'
                    'version:Show version'
                    'vg:Run vagrant command with framework'
                )
                _describe -t commands 'radp-vf command' radp_vf_cmds
                ;;
            args)
                case "${words[1]}" in
                    vg)
                        # Delegate to vagrant completion if available
                        if (( $+functions[_vagrant] )); then
                            _vagrant
                        else
                            local -a vagrant_cmds=(
                                'up:Start and provision VMs'
                                'halt:Stop VMs'
                                'destroy:Destroy VMs'
                                'status:Show VM status'
                                'ssh:SSH into VM'
                                'provision:Run provisioners'
                                'reload:Restart VMs'
                            )
                            _describe -t commands 'vagrant command' vagrant_cmds
                        fi
                        ;;
                    *)
                        _files
                        ;;
                esac
                ;;
        esac
    fi
}
VF_ZSH
}
