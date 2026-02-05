#!/usr/bin/env bash
# K8S cluster operations library
# Provides health check, token management, and cluster info functions

#######################################
# Check Kubernetes cluster health
# Verifies all nodes are Ready and all pods are running
# Returns:
#   0 - Cluster is healthy
#   1 - Cluster has issues
# Outputs:
#   Health status to stdout via logging
#######################################
_k8s_check_health() {
  local all_nodes_ready=true
  local all_pods_ready=true

  # Check if cluster is accessible
  if ! _k8s_is_cluster_accessible; then
    radp_log_error "Cannot connect to Kubernetes cluster"
    return 1
  fi

  # Check node status (read-only operation)
  radp_log_info "Checking nodes..."
  local all_nodes line
  all_nodes=$(kubectl get node -o wide 2>/dev/null)

  while IFS= read -r line; do
    # Skip header line
    if [[ $line == NAME* ]]; then
      continue
    fi

    local node_name node_status
    node_name=$(echo "$line" | awk '{print $1}')
    node_status=$(echo "$line" | awk '{print $2}')

    if [[ "$node_status" != "Ready" ]]; then
      all_nodes_ready=false
      radp_log_error "Node $node_name is not ready, status: $node_status"
    else
      radp_log_debug "Node $node_name is Ready"
    fi
  done <<<"$all_nodes"

  # Check pod status (read-only operation)
  radp_log_info "Checking pods..."
  local all_pods
  all_pods=$(kubectl get pods -A 2>/dev/null)

  while IFS= read -r line; do
    # Skip header line
    if [[ $line == NAMESPACE* ]]; then
      continue
    fi

    local namespace pod_name ready status
    namespace=$(echo "$line" | awk '{print $1}')
    pod_name=$(echo "$line" | awk '{print $2}')
    ready=$(echo "$line" | awk '{print $3}')
    status=$(echo "$line" | awk '{print $4}')

    # Parse ready ratio (e.g., "1/1")
    local ready_count total
    IFS='/' read -r ready_count total <<<"$ready"

    # Allow Completed status for job pods
    if [[ "$status" == "Completed" ]]; then
      radp_log_debug "Pod $pod_name in $namespace completed"
      continue
    fi

    # Check if pod is running and ready
    if [[ "$status" != "Running" ]] || [[ "$ready_count" -ne "$total" ]]; then
      all_pods_ready=false
      radp_log_error "Pod $pod_name in namespace $namespace is not ready, status: $status, ready: $ready"
    fi
  done <<<"$all_pods"

  if [[ $all_nodes_ready == true && $all_pods_ready == true ]]; then
    radp_log_info "Cluster is healthy"
    return 0
  else
    radp_log_error "Cluster has issues"
    return 1
  fi
}

#######################################
# Get current valid Kubernetes token
# If no valid token exists and create flag is set, creates a new one
# Arguments:
#   $1 - create_if_missing: 'true' to create new token if none valid (default: true)
# Outputs:
#   Token string to stdout
# Returns:
#   0 - Success
#   1 - No valid token and not creating
#######################################
_k8s_get_token() {
  local create_if_missing="${1:-true}"
  local current_time token expires

  if ! _k8s_is_kubeadm_available; then
    radp_log_error "kubeadm is not installed"
    return 1
  fi

  current_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  # Check for existing valid token (read-only operation)
  while IFS= read -r line; do
    token=$(echo "$line" | awk '{print $1}')
    expires=$(echo "$line" | awk '{print $3}')

    # Compare dates, if token is not expired, return it
    if [[ "$expires" > "$current_time" ]]; then
      echo "$token"
      return 0
    fi
  done < <($gr_sudo kubeadm token list 2>/dev/null | tail -n +2)

  if [[ "$create_if_missing" == 'true' ]]; then
    radp_log_warn "No valid token found, creating a new one"

    # In dry-run mode, show what would be done
    if radp_is_dry_run; then
      radp_log_info "[DRY-RUN] Would create new kubeadm token"
      echo "<dry-run-token>"
      return 0
    fi

    token=$($gr_sudo kubeadm token create 2>/dev/null)
    echo "$token"
    return 0
  else
    radp_log_error "No valid token found"
    return 1
  fi
}

#######################################
# Create a new Kubernetes token
# Outputs:
#   New token string to stdout
# Returns:
#   0 - Success
#   1 - Failure
#######################################
_k8s_create_token() {
  if ! _k8s_is_kubeadm_available; then
    radp_log_error "kubeadm is not installed"
    return 1
  fi

  # In dry-run mode, show what would be done
  if radp_is_dry_run; then
    radp_log_info "[DRY-RUN] Would create new kubeadm token"
    echo "<dry-run-token>"
    return 0
  fi

  local token
  token=$($gr_sudo kubeadm token create 2>/dev/null) || {
    radp_log_error "Failed to create token"
    return 1
  }

  echo "$token"
  radp_log_info "Created new token: $token"
  return 0
}

#######################################
# Get discovery token CA cert hash
# Used for worker node joining
# Outputs:
#   SHA256 hash prefixed with "sha256:"
# Returns:
#   0 - Success
#   1 - Failure (missing cert file)
#######################################
_k8s_get_discovery_token_ca_cert_hash() {
  local ca_cert="/etc/kubernetes/pki/ca.crt"

  # In dry-run mode, return placeholder
  if radp_is_dry_run; then
    echo "sha256:<dry-run-hash>"
    return 0
  fi

  if [[ ! -f "$ca_cert" ]]; then
    radp_log_error "CA certificate not found: $ca_cert"
    return 1
  fi

  local hash
  hash=$(openssl x509 -pubkey -in "$ca_cert" | \
         openssl rsa -pubin -outform der 2>/dev/null | \
         openssl dgst -sha256 -hex | \
         sed 's/^.* //')

  echo "sha256:$hash"
}

#######################################
# Get all node hostnames in the cluster
# Outputs:
#   One hostname per line
# Returns:
#   0 - Success
#   1 - Failure
#######################################
_k8s_get_node_hostnames() {
  if ! _k8s_is_kubectl_available; then
    radp_log_error "kubectl is not installed"
    return 1
  fi

  # Read-only operation
  kubectl get nodes -o custom-columns=NAME:.metadata.name --no-headers 2>/dev/null
}

#######################################
# Get node count in the cluster
# Outputs:
#   Number of nodes
# Returns:
#   0 - Success
#   1 - Failure
#######################################
_k8s_get_node_count() {
  if ! _k8s_is_kubectl_available; then
    return 1
  fi

  # Read-only operation
  kubectl get nodes --no-headers 2>/dev/null | wc -l
}

#######################################
# Get join command for worker nodes
# Outputs:
#   Full kubeadm join command
# Returns:
#   0 - Success
#   1 - Failure
#######################################
_k8s_get_join_command() {
  if ! _k8s_is_kubeadm_available; then
    radp_log_error "kubeadm is not installed"
    return 1
  fi

  # In dry-run mode, show placeholder
  if radp_is_dry_run; then
    radp_log_info "[DRY-RUN] Would create token and print join command"
    echo "kubeadm join <master-ip>:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>"
    return 0
  fi

  $gr_sudo kubeadm token create --print-join-command 2>/dev/null
}
