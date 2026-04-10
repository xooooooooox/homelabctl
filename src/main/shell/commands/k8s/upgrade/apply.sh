#!/usr/bin/env bash
# @cmd
# @desc Upgrade the first control plane node (runs kubeadm upgrade apply + drain + kubelet upgrade + uncordon)
# @arg version! Target Kubernetes version (e.g., 1.31.0)
# @option --ignore-preflight-errors <list> Comma-separated preflight errors to ignore (e.g., CoreDNSUnsupportedPlugins,CoreDNSMigration)
# @flag -y, --yes Skip confirmation prompt
# @flag --dry-run Show what would be done
# @example k8s upgrade apply 1.31.0
# @example k8s upgrade apply 1.31.0 --dry-run
# @example k8s upgrade apply 1.31.0 --ignore-preflight-errors=CoreDNSUnsupportedPlugins,CoreDNSMigration

cmd_k8s_upgrade_apply() {
  local version="${1:-}"
  local ignore_errors="${opt_ignore_preflight_errors:-}"
  local auto_yes="${opt_yes:-}"

  radp_set_dry_run "${opt_dry_run:-false}"

  if [[ -z "$version" ]]; then
    radp_log_error "Version is required"
    return 1
  fi

  # Normalize: strip leading "v"
  version="${version#v}"

  if ! _k8s_is_kubeadm_available; then
    radp_log_error "kubeadm is not installed — run 'homelabctl k8s install' first"
    return 1
  fi

  if ! _k8s_is_cluster_accessible; then
    radp_log_error "Cluster is not accessible via kubectl"
    return 1
  fi

  if [[ ! -f /etc/kubernetes/manifests/kube-apiserver.yaml ]]; then
    radp_log_error "This does not look like a control plane node"
    radp_log_info "Run 'k8s upgrade apply' only on the first control plane node"
    return 1
  fi

  if ! radp_is_dry_run && [[ -z "$auto_yes" ]]; then
    radp_log_warn "About to upgrade the first control plane node to v${version}"
    radp_log_warn "This will run kubeadm upgrade apply, drain the node, upgrade kubelet/kubectl, and uncordon"
    if ! radp_io_prompt_confirm --msg "Continue? (y/N)" --default N --timeout 60; then
      return 1
    fi
  fi

  _k8s_upgrade_local_first_cp "$version" "$ignore_errors" || return 1

  radp_log_info ""
  radp_log_info "First control plane upgraded to v${version}"
  radp_log_info "Next steps:"
  radp_log_info "  - Upgrade other control planes / workers: homelabctl k8s upgrade node -v ${version}"
  radp_log_info "  - Or orchestrate from here:              homelabctl k8s upgrade cluster ${version}"
  return 0
}
