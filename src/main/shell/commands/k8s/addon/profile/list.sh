#!/usr/bin/env bash
# @cmd
# @desc List available addon profiles
# @flag --names-only Output profile names only (for completion)
# @example k8s addon profile list

cmd_k8s_addon_profile_list() {
  local names_only="${opt_names_only:-}"

  # Output profile names only (for shell completion)
  if [[ -n "$names_only" ]]; then
    _k8s_addon_list_profiles | cut -d'|' -f1
    return 0
  fi

  echo "Available addon profiles:"
  echo ""

  local found=0
  while IFS='|' read -r name desc source; do
    printf "  %-20s %-10s %s\n" "$name" "[$source]" "$desc"
    ((++found))
  done < <(_k8s_addon_list_profiles)

  if [[ $found -eq 0 ]]; then
    echo "  No profiles found"
  fi

  echo ""
  echo "Use 'homelabctl k8s addon profile show <name>' for profile details"
  echo "Use 'homelabctl k8s addon profile apply <name>' to apply a profile"
}
