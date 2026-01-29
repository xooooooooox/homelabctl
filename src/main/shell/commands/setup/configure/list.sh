#!/usr/bin/env bash
# @cmd
# @desc List available system configurations
# @example setup configure list

cmd_setup_configure_list() {
  local configure_dir
  configure_dir="$(dirname "${BASH_SOURCE[0]}")"

  echo "Available configurations:"
  echo ""
  printf "  %-20s %s\n" "NAME" "DESCRIPTION"
  printf "  %-20s %s\n" "----" "-----------"

  local file name desc
  for file in "$configure_dir"/*.sh; do
    [[ -f "$file" ]] || continue

    name="$(basename "$file" .sh)"

    # Skip list.sh itself and files starting with _
    [[ "$name" == "list" || "$name" == _* ]] && continue

    # Check if it's a command file (has @cmd marker)
    grep -q '^# @cmd' "$file" || continue

    # Extract @desc annotation
    desc=$(grep '^# @desc' "$file" | head -1 | sed 's/^# @desc[[:space:]]*//')
    [[ -z "$desc" ]] && desc="No description"

    printf "  %-20s %s\n" "$name" "$desc"
  done

  echo ""
  echo "Run 'homelabctl setup configure <name> --help' for more information."
}
