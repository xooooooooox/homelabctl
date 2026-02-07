#!/usr/bin/env bash
# Shared helper functions for init commands (setup, k8s, all)
# Auto-loaded by framework from libs/ directory

#######################################
# Process a single file for init: print symbol line and optionally create
# Uses outer variables: created, skipped, overwritten (must be declared by caller)
# Arguments:
#   1 - base directory
#   2 - relative file path (for display)
#   3 - force flag ("true"/"false")
#   4 - dry_run flag ("true"/"false")
#   5.. - creator command and args (called only when file should be written)
#######################################
_init_process_file() {
  local base_dir="$1"
  local rel_path="$2"
  local force="$3"
  local dry_run="$4"
  shift 4

  local full_path="$base_dir/$rel_path"

  if [[ -f "$full_path" ]] && [[ "$force" != "true" ]]; then
    radp_log_raw "  ~ ${rel_path} (exists, use --force)"
    (( ++skipped ))
  elif [[ -f "$full_path" ]] && [[ "$force" == "true" ]]; then
    radp_log_raw "  ! ${rel_path}"
    (( ++overwritten ))
    if [[ "$dry_run" != "true" ]]; then
      "$@"
    fi
  else
    radp_log_raw "  + ${rel_path}"
    (( ++created ))
    if [[ "$dry_run" != "true" ]]; then
      "$@"
    fi
  fi
}

#######################################
# Format a count-based summary line
# Arguments:
#   1 - dry_run flag ("true"/"false")
# Uses outer variables: created, skipped, overwritten (must be declared by caller)
#######################################
_init_format_summary() {
  local dry_run="$1"
  local parts=()

  if (( created > 0 )); then
    local file_word="files"
    (( created == 1 )) && file_word="file"
    if [[ "$dry_run" == "true" ]]; then
      parts+=("${created} ${file_word} to create")
    else
      parts+=("${created} ${file_word} created")
    fi
  fi

  if (( overwritten > 0 )); then
    parts+=("${overwritten} overwritten")
  fi

  if (( skipped > 0 )); then
    parts+=("${skipped} skipped")
  fi

  if (( ${#parts[@]} == 0 )); then
    echo "Nothing to do."
    return
  fi

  local result="${parts[0]}"
  local i
  for (( i=1; i<${#parts[@]}; i++ )); do
    result+=", ${parts[$i]}"
  done
  echo "${result}."
}
