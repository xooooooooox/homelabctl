#!/usr/bin/env bash
# @cmd
# @desc List available packages
# @option -c, --category <name> Filter by category
# @complete category _homelabctl_complete_categories
# @option --installed Show only installed packages
# @option --categories List available categories
# @option --names-only Output package names only (for completion)
# @option --category-names Output category names only (for completion)
# @example setup list
# @example setup list -c cli-tools
# @example setup list --installed
# @example setup list --categories

cmd_setup_list() {
  local category="${opt_category:-}"
  local installed_only="${opt_installed:-}"
  local show_categories="${opt_categories:-}"
  local names_only="${opt_names_only:-}"
  local category_names="${opt_category_names:-}"

  _setup_registry_init

  # Output package names only (for shell completion)
  if [[ -n "$names_only" ]]; then
    _setup_registry_list_packages "$category" | cut -d'|' -f1
    return 0
  fi

  # Output category names only (for shell completion)
  if [[ -n "$category_names" ]]; then
    _setup_registry_list_categories | cut -d'|' -f1
    return 0
  fi

  # Show categories if requested
  if [[ -n "$show_categories" ]]; then
    echo "Available categories:"
    echo ""
    _setup_registry_list_categories | while IFS='|' read -r cat_name cat_desc; do
      printf "  %-15s %s\n" "$cat_name" "$cat_desc"
    done
    return 0
  fi

  # Show packages
  echo "Available packages:"
  if [[ -n "$category" ]]; then
    echo "  (filtered by category: $category)"
  fi
  if [[ -n "$installed_only" ]]; then
    echo "  (showing installed only)"
  fi
  echo ""

  while IFS='|' read -r pkg_name pkg_desc pkg_cat; do
    local status=" "
    local check_cmd
    check_cmd=$(_setup_registry_get_package_cmd "$pkg_name")

    if _setup_is_installed "$check_cmd"; then
      status="✓"
    fi

    # Apply installed filter
    if [[ -n "$installed_only" && "$status" != "✓" ]]; then
      continue
    fi

    printf " %s %-15s %-12s %s\n" "$status" "$pkg_name" "[$pkg_cat]" "$pkg_desc"
  done < <(_setup_registry_list_packages "$category")

  echo ""
  echo "Legend: ✓ = installed"
  echo ""
  echo "Use 'homelabctl setup info <name>' for package details"
  echo "Use 'homelabctl setup install <name>' to install a package"
}
