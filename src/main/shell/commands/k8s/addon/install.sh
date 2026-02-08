#!/usr/bin/env bash
# @cmd
# @desc Install a Kubernetes addon
# @arg name! Addon name to install
# @option -v, --version <ver> Addon version (uses default if not specified)
# @option -f, --values <file> Custom values file for helm
# @flag --dry-run Show what would be done
# @example k8s addon install metallb
# @example k8s addon install ingress-nginx -v 4.11.1
# @example k8s addon install cert-manager -f /path/to/values.yaml

cmd_k8s_addon_install() {
  local addon_name="${args_name}"
  local version="${opt_version:-}"
  local values_file="${opt_values:-}"

  # Enable dry-run mode if flag is set
  radp_set_dry_run "${opt_dry_run:-false}"

  # Check if cluster is accessible
  if ! _k8s_is_cluster_accessible; then
    radp_log_error "Cannot connect to Kubernetes cluster"
    return 1
  fi

  # Check if addon is already installed (skip check in dry-run mode)
  if ! radp_is_dry_run && _k8s_addon_is_installed "$addon_name"; then
    radp_log_info "Addon is already installed: $addon_name"
    radp_log_info "To upgrade, uninstall first: homelabctl k8s addon uninstall $addon_name"
    return 0
  fi

  _k8s_addon_install "$addon_name" "$version" "$values_file" || return 1

  return 0
}
