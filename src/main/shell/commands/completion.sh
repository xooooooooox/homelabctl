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
    # For bash: helpers first, then completion script with vg case replaced
    _completion_output_helpers
    # Generate and replace the vg case with vagrant delegation
    radp_cli_completion_generate "$shell" | sed "
        /^        'vg')$/,/^            ;;$/ c\\
        'vg')\\
            # Delegate to vagrant's native completion for consistent experience\\
            if type _vagrant \&>/dev/null; then\\
                # Shift words to simulate vagrant being called directly\\
                local vagrant_words=(\"vagrant\" \"\${words[@]:2}\")\\
                local vagrant_cword=\$((cword - 1))\\
                COMP_WORDS=(\"\${vagrant_words[@]}\")\\
                COMP_CWORD=\$vagrant_cword\\
                COMP_LINE=\"\${vagrant_words[*]}\"\\
                COMP_POINT=\${#COMP_LINE}\\
                _vagrant\\
            else\\
                # Fallback if vagrant completion not loaded\\
                local vagrant_cmds=\"up halt destroy status ssh provision reload suspend resume snapshot box plugin validate\"\\
                COMPREPLY=(\$(compgen -W \"\$vagrant_cmds\" -- \"\$cur\"))\\
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
    _completion_output_vg_zsh
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

COMPLETION_HELPERS
}

#######################################
# Output custom _homelabctl_vg for zsh
# Overrides framework-generated version to delegate to vagrant completion
#######################################
_completion_output_vg_zsh() {
  cat <<'VG_ZSH'

# Override _homelabctl_vg to delegate to vagrant's native completion
_homelabctl_vg() {
    # Delegate to vagrant's native completion for consistent experience
    if (( $+functions[_vagrant] )); then
        _vagrant "$@"
    else
        # Fallback if vagrant completion not loaded
        local -a vagrant_cmds=(
            'up:Start and provision VMs'
            'halt:Stop VMs'
            'destroy:Destroy VMs'
            'status:Show VM status'
            'ssh:SSH into VM'
            'provision:Run provisioners'
            'reload:Restart VMs'
            'suspend:Suspend VMs'
            'resume:Resume suspended VMs'
            'snapshot:Manage snapshots'
        )
        _arguments -s \
            '1: :->vagrant_cmd' \
            '*:: :->vagrant_args'

        case "$state" in
            vagrant_cmd)
                _describe -t commands 'vagrant command' vagrant_cmds
                ;;
            vagrant_args)
                _files
                ;;
        esac
    fi
}
VG_ZSH
}
