#!/usr/bin/env bash
# @cmd
# @desc List available setup profiles
# @flag --names-only Output profile names only (for completion)
# @example setup profile list
# @example setup profile list --names-only

cmd_setup_profile_list() {
  local names_only="${opt_names_only:-}"

  _setup_registry_init

  # Output profile names only (for shell completion)
  if [[ -n "$names_only" ]]; then
    _setup_list_profiles | cut -d'|' -f1
    return 0
  fi

  echo "Available profiles:"
  echo ""

  local found=0
  while IFS='|' read -r name desc source; do
    printf "  %-20s %-10s %s\n" "$name" "[$source]" "$desc"
    found=1
  done < <(_setup_list_profiles)

  if [[ $found -eq 0 ]]; then
    echo "  No profiles found"
  fi

  echo ""
  echo "Use 'homelabctl setup profile show <name>' for profile details"
  echo "Use 'homelabctl setup profile apply <name>' to apply a profile"
}
