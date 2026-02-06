#!/usr/bin/env bash
# @cmd
# @desc Show profile details
# @arg name! Profile name
# @complete name _homelabctl_complete_profiles
# @example setup profile show recommend
# @example setup profile show devops

cmd_setup_profile_show() {
  local name="${1:-}"

  if [[ -z "$name" ]]; then
    radp_cli_help_command "setup profile show"
    return 1
  fi

  _setup_registry_init

  # Find profile file
  local profile_file
  profile_file=$(_setup_find_profile "$name")
  if [[ -z "$profile_file" ]]; then
    radp_log_error "Profile not found: $name"
    radp_log_info "Run 'homelabctl setup profile list' to see available profiles"
    return 1
  fi

  # Get profile metadata
  local desc platform
  desc=$(_setup_yaml_get_value "desc" <"$profile_file")
  platform=$(_setup_yaml_get_value "platform" <"$profile_file")

  # Determine source
  local source="builtin"
  local user_dir
  user_dir=$(_setup_get_user_dir)
  [[ "$profile_file" == "$user_dir"* ]] && source="user"

  echo "Profile: $name"
  echo ""
  printf "  %-12s %s\n" "Description:" "$desc"
  printf "  %-12s %s\n" "Platform:" "${platform:-any}"
  printf "  %-12s %s\n" "Source:" "$source"
  printf "  %-12s %s\n" "File:" "$profile_file"
  echo ""

  echo "Packages:"
  _setup_parse_profile "$profile_file" | while IFS='|' read -r pkg_name pkg_version; do
    local status=" "
    local check_cmd

    # Check if package is installed
    if _setup_registry_has_package "$pkg_name"; then
      check_cmd=$(_setup_registry_get_package_cmd "$pkg_name")
      if _setup_is_installed "$check_cmd"; then
        status="✓"
      fi
    fi

    if [[ "$pkg_version" == "latest" ]]; then
      printf "  %s %-20s\n" "$status" "$pkg_name"
    else
      printf "  %s %-20s (v%s)\n" "$status" "$pkg_name" "$pkg_version"
    fi
  done

  echo ""
  echo "Legend: ✓ = installed"
  echo ""
  echo "Apply with: homelabctl setup profile apply $name"
}
