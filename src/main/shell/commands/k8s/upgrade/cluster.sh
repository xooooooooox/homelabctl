#!/usr/bin/env bash
# @cmd
# @desc Orchestrate a full cluster upgrade (first CP -> other CPs -> workers) via SSH
# @arg version! Target Kubernetes version (e.g., 1.31.0)
# @option --ignore-preflight-errors <list> Comma-separated preflight errors to ignore (passed to every node)
# @option -u, --ssh-user <user> SSH user for remote nodes (default: from config)
# @option -i, --ssh-key <path> SSH private key for remote nodes
# @flag -y, --yes Skip confirmation prompt
# @flag --dry-run Show what would be done
# @example k8s upgrade cluster 1.31.0
# @example k8s upgrade cluster 1.31.0 -u vagrant -i ~/.ssh/id_rsa
# @example k8s upgrade cluster 1.31.0 --ignore-preflight-errors=CoreDNSUnsupportedPlugins,CoreDNSMigration

cmd_k8s_upgrade_cluster() {
  local version="${1:-}"
  local ignore_errors="${opt_ignore_preflight_errors:-}"
  local ssh_user="${opt_ssh_user:-}"
  local ssh_key="${opt_ssh_key:-}"
  local auto_yes="${opt_yes:-}"

  radp_set_dry_run "${opt_dry_run:-false}"

  if [[ -z "$version" ]]; then
    radp_log_error "Version is required"
    return 1
  fi
  version="${version#v}"

  if ! _k8s_is_kubeadm_available; then
    radp_log_error "kubeadm is not installed — run 'homelabctl k8s install' first"
    return 1
  fi

  if ! _k8s_is_cluster_accessible; then
    radp_log_error "Cluster is not accessible via kubectl"
    radp_log_info "Run this command from a control plane node with a working kubeconfig"
    return 1
  fi

  if [[ ! -f /etc/kubernetes/manifests/kube-apiserver.yaml ]]; then
    radp_log_error "This does not look like a control plane node"
    radp_log_info "Run 'k8s upgrade cluster' only from the first control plane node"
    return 1
  fi

  if ! radp_is_dry_run && [[ -z "$auto_yes" ]]; then
    radp_log_warn "About to upgrade the ENTIRE cluster to v${version}"
    radp_log_warn "Order: first CP (this node) -> other CPs -> workers"
    radp_log_warn "Each node will be drained, upgraded, and uncordoned sequentially"
    radp_log_warn "SSH access to remote nodes required (configured via gr_radp_extend_homelabctl_k8s_ssh_user/ssh_key)"
    if ! radp_io_prompt_confirm --msg "Continue? (y/N)" --default N --timeout 60; then
      return 1
    fi
  fi

  _k8s_upgrade_cluster "$version" "$ignore_errors" "$ssh_user" "$ssh_key" || return 1

  return 0
}
