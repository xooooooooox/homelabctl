#!/usr/bin/env bash
# @cmd
# @desc Initialize all user configuration directories
# @flag --force Overwrite existing files
# @flag --dry-run Show what would be created without making changes
# @example init all
# @example init all --dry-run
# @example init all --force

cmd_init_all() {
  local force="${opt_force:-false}"
  local dry_run="${opt_dry_run:-false}"
  local failed=0

  local flags=()
  [[ "$force" == "true" ]] && flags+=(--force)
  [[ "$dry_run" == "true" ]] && flags+=(--dry-run)

  # Opening line
  local header="Initializing all configurations"
  [[ "$dry_run" == "true" ]] && header="$header (dry-run)"
  radp_log_raw "$header"

  # Totals
  local total_created=0 total_skipped=0 total_overwritten=0
  local module_count=0

  # Mark orchestration mode for in-process subcommands
  _init_orchestrated=true

  # Initialize setup and k8s modules (in-process dispatch, no subprocess/banner)
  for module in setup k8s; do
    radp_log_raw ""

    _init_result_created=0
    _init_result_skipped=0
    _init_result_overwritten=0

    if radp_cli_dispatch init "$module" "${flags[@]}"; then
      total_created=$(( total_created + _init_result_created ))
      total_skipped=$(( total_skipped + _init_result_skipped ))
      total_overwritten=$(( total_overwritten + _init_result_overwritten ))
      (( ++module_count ))
    else
      radp_log_error "Failed to initialize $module configuration"
      ((++failed))
    fi
  done

  # VF module - must be subprocess (delegates to radp-vf via exec)
  radp_log_raw ""

  local result_file
  result_file=$(mktemp)
  export RADP_VF_INIT_RESULT_FILE="$result_file"
  export RADP_INIT_ORCHESTRATED=true

  if GX_RADP_FW_BANNER_MODE=off homelabctl init vf "${flags[@]}"; then
    if [[ -f "$result_file" ]]; then
      local vf_created vf_skipped vf_overwritten
      vf_created=$(grep '^created:' "$result_file" | cut -d: -f2)
      vf_skipped=$(grep '^skipped:' "$result_file" | cut -d: -f2)
      vf_overwritten=$(grep '^overwritten:' "$result_file" | cut -d: -f2)
      total_created=$(( total_created + ${vf_created:-0} ))
      total_skipped=$(( total_skipped + ${vf_skipped:-0} ))
      total_overwritten=$(( total_overwritten + ${vf_overwritten:-0} ))
    fi
    (( ++module_count ))
  else
    radp_log_error "Failed to initialize vf configuration"
    (( ++failed ))
  fi
  rm -f "$result_file"
  unset RADP_VF_INIT_RESULT_FILE
  unset RADP_INIT_ORCHESTRATED

  radp_log_raw ""

  # Always print summary so partial success is visible
  radp_log_raw "$(_init_all_format_summary "$dry_run" "$module_count" "$total_created" "$total_overwritten" "$total_skipped" "$failed")"

  if [[ $failed -gt 0 ]]; then
    return 1
  fi
  return 0
}

#######################################
# Format summary line for init all
# Arguments:
#   1 - dry_run flag
#   2 - module count
#   3 - created count
#   4 - overwritten count
#   5 - skipped count
#   6 - failed count
#######################################
_init_all_format_summary() {
  local dry_run="$1"
  local modules="$2"
  local created="$3"
  local overwritten="$4"
  local skipped="$5"
  local failed="${6:-0}"
  local parts=()

  # Module count always first
  local mod_word="modules"
  (( modules == 1 )) && mod_word="module"
  parts+=("${modules} ${mod_word} initialized")

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

  if (( failed > 0 )); then
    parts+=("${failed} failed")
  fi

  local result="${parts[0]}"
  local i
  for (( i=1; i<${#parts[@]}; i++ )); do
    result+=", ${parts[$i]}"
  done
  echo "${result}."
}
