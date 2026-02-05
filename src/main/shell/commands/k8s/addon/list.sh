#!/usr/bin/env bash
# @cmd
# @desc List available Kubernetes addons
# @flag --installed Show only installed addons
# @example k8s addon list
# @example k8s addon list --installed

cmd_k8s_addon_list() {
  local installed_only="${opt_installed:-}"

  if [[ -n "$installed_only" ]]; then
    # Show only installed addons
    if ! _k8s_is_cluster_accessible; then
      radp_log_error "Cannot connect to Kubernetes cluster"
      return 1
    fi

    radp_log_info "Installed addons:"
    echo ""

    _k8s_addon_registry_load || return 1

    local found=0
    for addon in "${!__k8s_addon_registry[@]}"; do
      if _k8s_addon_is_installed "$addon"; then
        local namespace
        namespace=$(_k8s_addon_get_property "$addon" "helm.namespace")
        namespace="${namespace:-default}"

        local status
        status=$(helm status "$addon" -n "$namespace" -o json 2>/dev/null | yq -r '.info.status // "unknown"' 2>/dev/null)

        printf "  %-30s %-15s %s\n" "$addon" "$namespace" "$status"
        ((found++))
      fi
    done

    if [[ $found -eq 0 ]]; then
      radp_log_info "No addons installed"
    fi
  else
    # Show all available addons
    _k8s_addon_list || return 1
  fi

  return 0
}
