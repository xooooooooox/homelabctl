#!/usr/bin/env bash
# @cmd
# @desc Generate shell completion script
# @arg shell! Shell type (bash or zsh)
# @example completion bash > ~/.bash_completion.d/homelabctl
# @example completion zsh > ~/.zfunc/_homelabctl

cmd_completion() {
  local shell="${1:-}"

  if [[ -z "$shell" ]]; then
    radp_cli_help_command "completion"
    return 1
  fi

  case "$shell" in
  bash)
    # For bash: helpers first, then completion script
    _completion_output_helpers
    radp_cli_completion_generate "$shell"
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
    homelabctl setup list --names-only 2>/dev/null
}

_homelabctl_complete_categories() {
    homelabctl setup list --category-names 2>/dev/null
}

_homelabctl_complete_profiles() {
    homelabctl setup profile list --names-only 2>/dev/null
}

COMPLETION_HELPERS
}
