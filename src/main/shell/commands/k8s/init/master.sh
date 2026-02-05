#!/usr/bin/env bash
# @cmd
# @desc Initialize Kubernetes master node
# @option -a, --apiserver-advertise-address! <ip> API server advertise address (required)
# @option -p, --pod-network-cidr <cidr> Pod network CIDR (default: 10.244.0.0/16)
# @flag --dry-run Show what would be done
# @example k8s init master -a 192.168.1.100
# @example k8s init master -a 192.168.1.100 -p 10.244.0.0/16

cmd_k8s_init_master() {
  local apiserver_address="${opt_apiserver_advertise_address}"
  local pod_cidr="${opt_pod_network_cidr:-$(_k8s_get_default_pod_cidr)}"

  # Enable dry-run mode if flag is set
  radp_set_dry_run "${opt_dry_run:-}"

  # Validate IP address format
  if [[ ! "$apiserver_address" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    radp_log_error "Invalid IP address format: $apiserver_address"
    return 1
  fi

  # Check if kubeadm is installed
  if ! _k8s_is_kubeadm_available; then
    radp_log_error "kubeadm is not installed"
    radp_log_info "Run first: homelabctl k8s install"
    return 1
  fi

  # Check if already initialized (skip in dry-run mode)
  if ! radp_is_dry_run && [[ -f /etc/kubernetes/admin.conf ]]; then
    radp_log_warn "Kubernetes appears to be already initialized"
    if ! radp_io_prompt_confirm --msg "Continue anyway? This may cause issues. (y/N)" --default N --timeout 30; then
      return 1
    fi
  fi

  radp_log_info "Initializing Kubernetes master node..."
  radp_log_info "  API Server Address: $apiserver_address"
  radp_log_info "  Pod Network CIDR: $pod_cidr"

  _k8s_init_master "$apiserver_address" "$pod_cidr" || return 1

  radp_log_info ""
  radp_log_info "Master node initialized successfully!"
  radp_log_info ""
  radp_log_info "To add worker nodes, run on each worker:"
  radp_log_info "  homelabctl k8s install"
  radp_log_info "  homelabctl k8s init worker -c $apiserver_address:6443"
  radp_log_info ""
  radp_log_info "Or get the join command:"
  radp_log_info "  sudo kubeadm token create --print-join-command"

  return 0
}
