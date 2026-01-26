#!/usr/bin/env bash
# @cmd
# @desc List available setup profiles
# @example setup profile list

cmd_setup_profile_list() {
    _setup_registry_init

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
