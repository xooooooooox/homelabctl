#!/usr/bin/env bash
# @cmd
# @desc Upgrade an additional control plane or worker node (runs kubeadm upgrade node)
# @option -v, --version! <ver> Target Kubernetes version (e.g., 1.31.0)
# @option -r, --role <role> Node role: control-plane or worker (default: auto-detect)
# @flag --skip-drain Skip local drain/uncordon (used when orchestrated from master)
# @flag -y, --yes Skip confirmation prompt
# @flag --dry-run Show what would be done
# @example k8s upgrade node -v 1.31.0
# @example k8s upgrade node -v 1.31.0 --role worker
# @example k8s upgrade node -v 1.31.0 --skip-drain --yes

cmd_k8s_upgrade_node() {
  local version="${opt_version:-}"
  local role="${opt_role:-}"
  local skip_drain="false"
  [[ -n "${opt_skip_drain:-}" ]] && skip_drain="true"
  local auto_yes="${opt_yes:-}"

  radp_set_dry_run "${opt_dry_run:-false}"

  if [[ -z "$version" ]]; then
    radp_log_error "Version is required (-v/--version)"
    return 1
  fi
  version="${version#v}"

  if ! _k8s_is_kubeadm_available; then
    radp_log_error "kubeadm is not installed — run 'homelabctl k8s install' first"
    return 1
  fi

  # Auto-detect role if not specified
  if [[ -z "$role" ]]; then
    if [[ -f /etc/kubernetes/manifests/kube-apiserver.yaml ]]; then
      role="control-plane"
    else
      role="worker"
    fi
    radp_log_info "Auto-detected node role: ${role}"
  fi

  if [[ "$role" != "control-plane" && "$role" != "worker" ]]; then
    radp_log_error "Invalid role: ${role} (must be 'control-plane' or 'worker')"
    return 1
  fi

  if ! radp_is_dry_run && [[ -z "$auto_yes" ]]; then
    radp_log_warn "About to upgrade this ${role} node to v${version}"
    if ! radp_io_prompt_confirm --msg "Continue? (y/N)" --default N --timeout 60; then
      return 1
    fi
  fi

  _k8s_upgrade_local_node "$version" "$role" "$skip_drain" || return 1

  radp_log_info ""
  radp_log_info "Node upgraded to v${version}"
  return 0
}
