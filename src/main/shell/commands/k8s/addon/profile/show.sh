#!/usr/bin/env bash
# @cmd
# @desc Show addon profile details
# @arg name! Profile name
# @example k8s addon profile show quickstart
# @example k8s addon profile show production

cmd_k8s_addon_profile_show() {
  local profile_name="${args_name}"

  # Find profile file
  local profile_file
  profile_file=$(_k8s_addon_find_profile "$profile_name")
  if [[ -z "$profile_file" ]]; then
    radp_log_error "Profile not found: $profile_name"
    radp_log_info "Run 'homelabctl k8s addon profile list' to see available profiles"
    return 1
  fi

  # Get profile metadata
  local desc platform
  desc=$(_k8s_addon_get_profile_field "$profile_file" "desc")
  platform=$(_k8s_addon_get_profile_field "$profile_file" "platform")

  # Determine source
  local source="builtin"
  local user_dir
  user_dir=$(_k8s_addon_get_user_profiles_dir)
  [[ "$profile_file" == "$user_dir"* ]] && source="user"

  echo "Profile: $profile_name"
  echo ""
  printf "  %-12s %s\n" "Description:" "$desc"
  printf "  %-12s %s\n" "Platform:" "${platform:-any}"
  printf "  %-12s %s\n" "Source:" "$source"
  printf "  %-12s %s\n" "File:" "$profile_file"
  echo ""

  echo "Addons:"

  # Check if cluster is accessible for status checking
  local can_check_status=""
  if _k8s_is_cluster_accessible 2>/dev/null; then
    can_check_status="true"
  fi

  while IFS='|' read -r addon_name addon_version; do
    local status=" "
    local version_display=""

    # Check if addon is installed
    if [[ -n "$can_check_status" ]]; then
      if _k8s_addon_is_installed "$addon_name" 2>/dev/null; then
        status="✓"
      fi
    fi

    # Format version display
    if [[ "$addon_version" != "latest" ]]; then
      version_display=" (v$addon_version)"
    fi

    # Get addon description from registry
    local addon_desc=""
    if _k8s_addon_exists "$addon_name" 2>/dev/null; then
      addon_desc=$(_k8s_addon_get_property "$addon_name" "desc" 2>/dev/null)
    fi

    printf "  %s %-30s %s\n" "$status" "${addon_name}${version_display}" "$addon_desc"
  done < <(_k8s_addon_parse_profile "$profile_file")

  echo ""
  if [[ -n "$can_check_status" ]]; then
    echo "Legend: ✓ = installed"
    echo ""
  fi
  echo "Apply with: homelabctl k8s addon profile apply $profile_name"
}
