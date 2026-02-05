#!/usr/bin/env bash
# @cmd
# @desc Uninstall a Kubernetes addon
# @arg name! Addon name to uninstall
# @flag --dry-run Show what would be done
# @example k8s addon uninstall metallb
# @example k8s addon uninstall ingress-nginx

cmd_k8s_addon_uninstall() {
  local addon_name="${args_name}"

  # Enable dry-run mode if flag is set
  radp_set_dry_run "${opt_dry_run:-}"

  # Check if cluster is accessible
  if ! _k8s_is_cluster_accessible; then
    radp_log_error "Cannot connect to Kubernetes cluster"
    return 1
  fi

  # Check if addon is installed (skip check in dry-run mode)
  if ! radp_is_dry_run && ! _k8s_addon_is_installed "$addon_name"; then
    radp_log_info "Addon is not installed: $addon_name"
    return 0
  fi

  _k8s_addon_uninstall "$addon_name" || return 1

  return 0
}
