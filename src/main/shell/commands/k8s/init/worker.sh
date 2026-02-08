#!/usr/bin/env bash
# @cmd
# @desc Initialize Kubernetes worker node and join cluster
# @option -c, --control-plane! <host:port> Control plane address (required, format: ip:port)
# @option -t, --token <token> Join token (optional, will retrieve from master if not provided)
# @option --discovery-token-ca-cert-hash <hash> CA cert hash (optional, will retrieve if not provided)
# @option -u, --ssh-user <user> SSH user for connecting to master (default: from config, typically root)
# @flag --dry-run Show what would be done
# @example k8s init worker -c 192.168.1.100:6443
# @example k8s init worker -c 192.168.1.100:6443 -u vagrant
# @example k8s init worker -c 192.168.1.100:6443 -t abcdef.1234567890abcdef

cmd_k8s_init_worker() {
  local control_plane="${opt_control_plane}"
  local token="${opt_token:-}"
  local ca_hash="${opt_discovery_token_ca_cert_hash:-}"
  local ssh_user="${opt_ssh_user:-}"

  # Enable dry-run mode if flag is set
  radp_set_dry_run "${opt_dry_run:-false}"

  # Validate control plane format
  if [[ ! "$control_plane" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+$ ]]; then
    radp_log_error "Invalid control plane format: $control_plane"
    radp_log_info "Expected format: ip:port (e.g., 192.168.1.100:6443)"
    return 1
  fi

  # Check if kubeadm is installed
  if ! _k8s_is_kubeadm_available; then
    radp_log_error "kubeadm is not installed"
    radp_log_info "Run first: homelabctl k8s install"
    return 1
  fi

  # Check if already joined (skip in dry-run mode)
  if ! radp_is_dry_run && [[ -f /etc/kubernetes/kubelet.conf ]]; then
    radp_log_warn "This node appears to be already part of a cluster"
    if ! radp_io_prompt_confirm --msg "Continue anyway? (y/N)" --default N --timeout 30; then
      return 1
    fi
  fi

  radp_log_info "Joining Kubernetes cluster..."
  radp_log_info "  Control Plane: $control_plane"

  # If token and hash provided, use them directly
  if [[ -n "$token" && -n "$ca_hash" ]]; then
    radp_log_info "Using provided token and CA hash"
    radp_exec_sudo "Join cluster" kubeadm join "$control_plane" \
      --token "$token" \
      --discovery-token-ca-cert-hash "$ca_hash" || {
      radp_log_error "Failed to join cluster"
      return 1
    }
  else
    # Use the library function to handle SSH-based join
    _k8s_init_worker "$control_plane" "$ssh_user" || return 1
  fi

  radp_log_info ""
  radp_log_info "Worker node joined cluster successfully!"
  radp_log_info ""
  radp_log_info "Verify on master node:"
  radp_log_info "  kubectl get nodes"

  return 0
}
