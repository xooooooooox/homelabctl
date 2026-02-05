#!/usr/bin/env bash
# @cmd
# @desc Check Kubernetes cluster health
# @flag --verbose Show detailed output
# @example k8s health
# @example k8s health --verbose

cmd_k8s_health() {
  local verbose="${opt_verbose:-}"

  # Check if kubectl is available
  if ! _k8s_is_kubectl_available; then
    radp_log_error "kubectl is not installed"
    return 1
  fi

  # Check if cluster is accessible
  if ! _k8s_is_cluster_accessible; then
    radp_log_error "Cannot connect to Kubernetes cluster"
    radp_log_info "Check your kubeconfig: kubectl cluster-info"
    return 1
  fi

  # Run health check
  if [[ -n "$verbose" ]]; then
    radp_log_info "Cluster info:"
    kubectl cluster-info
    echo ""
  fi

  _k8s_check_health || return 1

  if [[ -n "$verbose" ]]; then
    echo ""
    radp_log_info "Node details:"
    kubectl get nodes -o wide
    echo ""
    radp_log_info "Pod summary by namespace:"
    kubectl get pods -A --no-headers | awk '{ns[$1]++} END {for (n in ns) printf "  %-30s %d pods\n", n, ns[n]}' | sort
  fi

  return 0
}
