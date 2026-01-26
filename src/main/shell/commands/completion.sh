#!/usr/bin/env bash
# @cmd
# @desc Generate shell completion script
# @arg shell! Shell type (bash or zsh)
# @example completion bash > ~/.bash_completion.d/homelabctl
# @example completion zsh > ~/.zfunc/_homelabctl

cmd_completion() {
  local shell="${1:-}"

  if [[ -z "$shell" ]]; then
    radp_log_error "Shell type required (bash or zsh)"
    return 1
  fi

  # Output completion helper functions first
  _completion_output_helpers

  # Output standard completion script
  radp_cli_completion_generate "$shell"
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
