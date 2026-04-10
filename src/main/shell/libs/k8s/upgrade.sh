#!/usr/bin/env bash
# K8S upgrade functions (kubeadm cluster upgrade)
# Reference: https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/

#######################################
# Extract minor version from full version
# Arguments:
#   1 - full version (e.g., "1.31.0" or "1.31")
# Outputs:
#   minor version (e.g., "1.31")
#######################################
__k8s_minor_version() {
  local v="${1:?'version required'}"
  # Strip any leading "v"
  v="${v#v}"
  # Keep only MAJOR.MINOR
  echo "$v" | awk -F. '{printf "%s.%s", $1, $2}'
}

#######################################
# Rewrite yum kubernetes repo to point at a new minor version
# Arguments:
#   1 - full version (e.g., "1.31.0")
# Returns:
#   0 on success, 1 on failure
#######################################
__k8s_upgrade_repo_yum() {
  local version="${1:?'version required'}"
  local minor
  minor=$(__k8s_minor_version "$version")

  radp_log_info "Updating yum kubernetes repo to v${minor}..."

  local repo_content="[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v${minor}/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v${minor}/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni"

  echo "$repo_content" | radp_exec_sudo "Write /etc/yum.repos.d/kubernetes.repo (v${minor})" \
    tee /etc/yum.repos.d/kubernetes.repo >/dev/null || return 1

  return 0
}

#######################################
# Rewrite apt kubernetes repo to point at a new minor version
# Arguments:
#   1 - full version (e.g., "1.31.0")
# Returns:
#   0 on success, 1 on failure
#######################################
__k8s_upgrade_repo_apt() {
  local version="${1:?'version required'}"
  local minor
  minor=$(__k8s_minor_version "$version")

  radp_log_info "Updating apt kubernetes repo to v${minor}..."

  # Refresh GPG key for the new minor version
  if ! radp_is_dry_run; then
    curl -fsSL "https://pkgs.k8s.io/core:/stable:/v${minor}/deb/Release.key" |
      $gr_sudo gpg --dearmor --yes -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg || return 1
  else
    radp_log_info "[dry-run] Refresh /etc/apt/keyrings/kubernetes-apt-keyring.gpg for v${minor}"
  fi

  echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${minor}/deb/ /" |
    radp_exec_sudo "Write /etc/apt/sources.list.d/kubernetes.list (v${minor})" \
      tee /etc/apt/sources.list.d/kubernetes.list >/dev/null || return 1

  radp_exec_sudo "apt-get update" apt-get update || return 1

  return 0
}

#######################################
# Install specific pinned version of k8s packages via yum/dnf
# Arguments:
#   1 - full version (e.g., "1.31.0")
#   $@ - package names to install (kubeadm, kubelet, kubectl)
# Returns:
#   0 on success, 1 on failure
#######################################
__k8s_install_pinned_yum() {
  local version="${1:?'version required'}"
  shift
  local -a packages=()
  local pkg
  for pkg in "$@"; do
    packages+=("${pkg}-${version}-*")
  done

  radp_exec_sudo "Install ${packages[*]}" \
    yum install -y --disableexcludes=kubernetes "${packages[@]}" || return 1

  return 0
}

#######################################
# Install specific pinned version of k8s packages via apt
# Handles apt-mark hold/unhold around install
# Arguments:
#   1 - full version (e.g., "1.31.0")
#   $@ - package names to install (kubeadm, kubelet, kubectl)
# Returns:
#   0 on success, 1 on failure
#######################################
__k8s_install_pinned_apt() {
  local version="${1:?'version required'}"
  shift
  local -a packages=("$@")
  local -a specs=()
  local pkg
  for pkg in "${packages[@]}"; do
    specs+=("${pkg}=${version}-*")
  done

  radp_exec_sudo "Unhold ${packages[*]}" apt-mark unhold "${packages[@]}" || return 1
  radp_exec_sudo "Install ${specs[*]}" apt-get install -y "${specs[@]}" || {
    # Re-hold even on failure to avoid leaving packages unlocked
    radp_exec_sudo "Re-hold ${packages[*]}" apt-mark hold "${packages[@]}" || true
    return 1
  }
  radp_exec_sudo "Hold ${packages[*]}" apt-mark hold "${packages[@]}" || return 1

  return 0
}

#######################################
# Upgrade kubeadm package to a specific version
# Dispatches on distro package manager
# Arguments:
#   1 - full version (e.g., "1.31.0")
# Returns:
#   0 on success, 1 on failure
#######################################
_k8s_upgrade_kubeadm_package() {
  local version="${1:?'version required'}"

  radp_log_info "Upgrading kubeadm package to ${version}..."

  local distro_id
  distro_id=$(radp_os_get_distro_id 2>/dev/null || echo "unknown")

  case "$distro_id" in
    centos | rhel | rocky | almalinux | fedora)
      __k8s_upgrade_repo_yum "$version" || return 1
      __k8s_install_pinned_yum "$version" kubeadm || return 1
      ;;
    ubuntu | debian)
      __k8s_upgrade_repo_apt "$version" || return 1
      __k8s_install_pinned_apt "$version" kubeadm || return 1
      ;;
    *)
      radp_log_error "Unsupported distribution: $distro_id"
      return 1
      ;;
  esac

  if ! radp_is_dry_run; then
    radp_log_info "kubeadm version: $(kubeadm version -o short 2>/dev/null)"
  fi

  return 0
}

#######################################
# Upgrade kubelet and kubectl packages to a specific version
# Arguments:
#   1 - full version (e.g., "1.31.0")
# Returns:
#   0 on success, 1 on failure
#######################################
_k8s_upgrade_kubelet_kubectl_package() {
  local version="${1:?'version required'}"

  radp_log_info "Upgrading kubelet and kubectl packages to ${version}..."

  local distro_id
  distro_id=$(radp_os_get_distro_id 2>/dev/null || echo "unknown")

  case "$distro_id" in
    centos | rhel | rocky | almalinux | fedora)
      __k8s_install_pinned_yum "$version" kubelet kubectl || return 1
      ;;
    ubuntu | debian)
      __k8s_install_pinned_apt "$version" kubelet kubectl || return 1
      ;;
    *)
      radp_log_error "Unsupported distribution: $distro_id"
      return 1
      ;;
  esac

  return 0
}

#######################################
# Run kubeadm upgrade plan
# Returns:
#   0 on success, 1 on failure
#######################################
_k8s_upgrade_plan() {
  radp_log_info "Running kubeadm upgrade plan..."
  radp_exec_sudo "kubeadm upgrade plan" kubeadm upgrade plan || return 1
  return 0
}

#######################################
# Run kubeadm upgrade apply (first control plane node)
# Arguments:
#   1 - full version (e.g., "1.31.0")
# Returns:
#   0 on success, 1 on failure
#######################################
_k8s_upgrade_apply_first_cp() {
  local version="${1:?'version required'}"
  radp_log_info "Running kubeadm upgrade apply v${version}..."
  radp_exec_sudo "kubeadm upgrade apply v${version}" \
    kubeadm upgrade apply "v${version}" -y || return 1
  return 0
}

#######################################
# Run kubeadm upgrade node (other CP / worker)
# Returns:
#   0 on success, 1 on failure
#######################################
_k8s_upgrade_node_local() {
  radp_log_info "Running kubeadm upgrade node..."
  radp_exec_sudo "kubeadm upgrade node" kubeadm upgrade node || return 1
  return 0
}

#######################################
# Restart kubelet after package upgrade
# Returns:
#   0 on success, 1 on failure
#######################################
_k8s_restart_kubelet() {
  radp_log_info "Restarting kubelet..."
  radp_exec_sudo "systemctl daemon-reload" systemctl daemon-reload || return 1
  radp_exec_sudo "systemctl restart kubelet" systemctl restart kubelet || return 1
  return 0
}

#######################################
# Drain a node
# Arguments:
#   1 - node name
#   2 - role hint ("worker" to add --delete-emptydir-data, anything else for CP)
# Returns:
#   0 on success, 1 on failure
#######################################
_k8s_drain_node() {
  local node="${1:?'node name required'}"
  local role="${2:-control-plane}"

  radp_log_info "Draining node ${node}..."

  local -a drain_args=("$node" --ignore-daemonsets)
  if [[ "$role" == "worker" ]]; then
    drain_args+=(--delete-emptydir-data)
  fi

  radp_exec "kubectl drain ${drain_args[*]}" \
    kubectl drain "${drain_args[@]}" || return 1

  return 0
}

#######################################
# Uncordon a node
# Arguments:
#   1 - node name
# Returns:
#   0 on success, 1 on failure
#######################################
_k8s_uncordon_node() {
  local node="${1:?'node name required'}"
  radp_log_info "Uncordoning node ${node}..."
  radp_exec "kubectl uncordon ${node}" kubectl uncordon "$node" || return 1
  return 0
}

#######################################
# Wait for a node to reach Ready state
# Arguments:
#   1 - node name
#   2 - timeout seconds (default: 300)
# Returns:
#   0 if Ready, 1 on timeout
#######################################
_k8s_wait_node_ready() {
  local node="${1:?'node name required'}"
  local timeout="${2:-300}"

  if radp_is_dry_run; then
    radp_log_info "[dry-run] Would wait for node ${node} to become Ready"
    return 0
  fi

  radp_log_info "Waiting for node ${node} to become Ready (timeout: ${timeout}s)..."
  if kubectl wait --for=condition=Ready "node/${node}" --timeout="${timeout}s" >/dev/null 2>&1; then
    radp_log_info "Node ${node} is Ready"
    return 0
  else
    radp_log_error "Node ${node} did not become Ready within ${timeout}s"
    return 1
  fi
}

#######################################
# Detect local node role via local kubeadm artifacts
# Falls back to checking /etc/kubernetes/manifests/kube-apiserver.yaml
# Outputs:
#   "control-plane" or "worker"
#######################################
__k8s_detect_local_role() {
  if [[ -f /etc/kubernetes/manifests/kube-apiserver.yaml ]]; then
    echo "control-plane"
  else
    echo "worker"
  fi
}

#######################################
# Get local node name (hostname as seen by kubelet)
# Outputs:
#   hostname
#######################################
__k8s_local_node_name() {
  # kubelet uses hostname by default unless --hostname-override is set
  # Try to read from kubelet config first
  local name=""
  if [[ -f /var/lib/kubelet/kubeadm-flags.env ]]; then
    name=$(grep -oE 'hostname-override=[^" ]+' /var/lib/kubelet/kubeadm-flags.env 2>/dev/null | head -1 | cut -d= -f2)
  fi
  if [[ -z "$name" ]]; then
    name=$(hostname 2>/dev/null)
  fi
  echo "$name"
}

#######################################
# Full local upgrade flow for the FIRST control plane node
# Arguments:
#   1 - full version (e.g., "1.31.0")
# Returns:
#   0 on success, 1 on failure
#######################################
_k8s_upgrade_local_first_cp() {
  local version="${1:?'version required'}"
  local node
  node=$(__k8s_local_node_name)

  radp_log_info "=== Upgrading first control plane node (${node}) to v${version} ==="

  _k8s_upgrade_kubeadm_package "$version" || return 1
  _k8s_upgrade_plan || radp_log_warn "kubeadm upgrade plan returned non-zero (continuing)"
  _k8s_upgrade_apply_first_cp "$version" || return 1
  _k8s_drain_node "$node" "control-plane" || return 1
  _k8s_upgrade_kubelet_kubectl_package "$version" || return 1
  _k8s_restart_kubelet || return 1
  _k8s_uncordon_node "$node" || return 1
  _k8s_wait_node_ready "$node" || return 1

  radp_log_info "=== First control plane upgrade complete ==="
  return 0
}

#######################################
# Full local upgrade flow for other CPs or workers
# Arguments:
#   1 - full version (e.g., "1.31.0")
#   2 - role ("control-plane" or "worker"); auto-detected if omitted
#   3 - skip_drain ("true" to skip local drain/uncordon, e.g. when orchestrator
#                    already drained from master side)
# Returns:
#   0 on success, 1 on failure
#######################################
_k8s_upgrade_local_node() {
  local version="${1:?'version required'}"
  local role="${2:-$(__k8s_detect_local_role)}"
  local skip_drain="${3:-false}"
  local node
  node=$(__k8s_local_node_name)

  radp_log_info "=== Upgrading ${role} node (${node}) to v${version} ==="

  _k8s_upgrade_kubeadm_package "$version" || return 1
  _k8s_upgrade_node_local || return 1

  # Drain before kubelet upgrade requires kubectl access.
  # Workers typically don't have kubeconfig; drain is usually initiated from
  # a control plane. Skip drain if caller indicated (orchestrated mode) or
  # if kubectl is not locally usable.
  if [[ "$skip_drain" != "true" ]] && _k8s_is_cluster_accessible; then
    _k8s_drain_node "$node" "$role" || radp_log_warn "drain failed (continuing)"
  else
    radp_log_info "Skipping local drain (skip_drain=${skip_drain})"
  fi

  _k8s_upgrade_kubelet_kubectl_package "$version" || return 1
  _k8s_restart_kubelet || return 1

  if [[ "$skip_drain" != "true" ]] && _k8s_is_cluster_accessible; then
    _k8s_uncordon_node "$node" || radp_log_warn "uncordon failed (continuing)"
    _k8s_wait_node_ready "$node" || return 1
  fi

  radp_log_info "=== Node upgrade complete ==="
  return 0
}

#######################################
# Build ssh options from _k8s_get_ssh_user / _k8s_get_ssh_key
# Outputs:
#   Space-separated ssh option string
#######################################
__k8s_ssh_opts() {
  local ssh_key
  ssh_key=$(_k8s_get_ssh_key)
  local opts="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
  [[ -n "$ssh_key" ]] && opts+=" -i ${ssh_key}"
  echo "$opts"
}

#######################################
# Execute command on remote host via SSH
# Arguments:
#   1 - host
#   $@ - command and arguments
# Returns:
#   Command exit code (0 in dry-run)
#######################################
__k8s_ssh_exec() {
  local host="${1:?'host required'}"
  shift
  local ssh_user
  ssh_user=$(_k8s_get_ssh_user)
  local ssh_opts
  ssh_opts=$(__k8s_ssh_opts)

  if radp_is_dry_run; then
    radp_log_info "[dry-run] ssh ${ssh_user}@${host} $*"
    return 0
  fi

  # shellcheck disable=SC2086
  ssh $ssh_opts "${ssh_user}@${host}" "$@"
}

#######################################
# Get internal IP of a node
# Arguments:
#   1 - node name
# Outputs:
#   IP address, empty on failure
#######################################
__k8s_node_internal_ip() {
  local node="${1:?'node required'}"
  kubectl get node "$node" \
    -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}' 2>/dev/null
}

#######################################
# List node names by selector
# Arguments:
#   1 - label selector (e.g., "node-role.kubernetes.io/control-plane=")
# Outputs:
#   one node name per line
#######################################
__k8s_list_nodes_by_label() {
  local selector="${1:-}"
  if [[ -n "$selector" ]]; then
    kubectl get nodes -l "$selector" -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' 2>/dev/null
  else
    kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' 2>/dev/null
  fi
}

#######################################
# Orchestrate full cluster upgrade from the first control plane node
# Arguments:
#   1 - full version (e.g., "1.31.0")
# Returns:
#   0 on success, 1 on failure
#######################################
_k8s_upgrade_cluster() {
  local version="${1:?'version required'}"

  if ! _k8s_is_cluster_accessible; then
    radp_log_error "Cluster not accessible via kubectl — run this from a control plane node"
    return 1
  fi

  local local_node
  local_node=$(__k8s_local_node_name)
  radp_log_info "Cluster upgrade to v${version} (orchestrating from ${local_node})"

  # Discover nodes
  local -a all_cps=() other_cps=() workers=()
  local n
  while IFS= read -r n; do
    [[ -n "$n" ]] && all_cps+=("$n")
  done < <(__k8s_list_nodes_by_label "node-role.kubernetes.io/control-plane=")

  while IFS= read -r n; do
    [[ -n "$n" ]] && workers+=("$n")
  done < <(__k8s_list_nodes_by_label '!node-role.kubernetes.io/control-plane')

  # Split CPs into first (= local) and others
  for n in "${all_cps[@]}"; do
    [[ "$n" != "$local_node" ]] && other_cps+=("$n")
  done

  radp_log_info "Discovered nodes:"
  radp_log_info "  first CP (local): ${local_node}"
  if [[ ${#other_cps[@]} -gt 0 ]]; then
    radp_log_info "  other CPs: ${other_cps[*]}"
  fi
  if [[ ${#workers[@]} -gt 0 ]]; then
    radp_log_info "  workers:   ${workers[*]}"
  fi

  # Step 1: first CP (local)
  _k8s_upgrade_local_first_cp "$version" || {
    radp_log_error "First control plane upgrade failed"
    return 1
  }

  # Step 2: other CPs (remote)
  for n in "${other_cps[@]}"; do
    __k8s_upgrade_remote_node "$n" "$version" "control-plane" || {
      radp_log_error "Remote CP upgrade failed: $n"
      return 1
    }
  done

  # Step 3: workers (remote)
  for n in "${workers[@]}"; do
    __k8s_upgrade_remote_node "$n" "$version" "worker" || {
      radp_log_error "Remote worker upgrade failed: $n"
      return 1
    }
  done

  radp_log_info "=== Cluster upgrade to v${version} complete ==="
  radp_log_info "Run 'kubectl get nodes' to verify all nodes are on the new version"
  return 0
}

#######################################
# Upgrade a remote node: drain from local, SSH to run upgrade, uncordon from local
# Arguments:
#   1 - node name
#   2 - full version
#   3 - role (control-plane / worker)
# Returns:
#   0 on success, 1 on failure
#######################################
__k8s_upgrade_remote_node() {
  local node="${1:?'node required'}"
  local version="${2:?'version required'}"
  local role="${3:?'role required'}"

  radp_log_info "--- Upgrading remote ${role} ${node} to v${version} ---"

  local ip
  ip=$(__k8s_node_internal_ip "$node")
  # Fall back to node name if internal IP cannot be resolved
  [[ -z "$ip" ]] && ip="$node"

  # Drain from local (control plane has kubectl)
  _k8s_drain_node "$node" "$role" || {
    radp_log_error "Failed to drain ${node}"
    return 1
  }

  # Run upgrade remotely via homelabctl
  # Use --role to bypass local auto-detection, --skip-drain (already drained),
  # and --yes to skip confirmation prompt over non-interactive SSH.
  __k8s_ssh_exec "$ip" "sudo homelabctl k8s upgrade node -v ${version} --role ${role} --skip-drain --yes" || {
    radp_log_error "Remote upgrade failed on ${node}"
    _k8s_uncordon_node "$node" || true
    return 1
  }

  # Uncordon from local
  _k8s_uncordon_node "$node" || {
    radp_log_error "Failed to uncordon ${node}"
    return 1
  }

  _k8s_wait_node_ready "$node" || {
    radp_log_error "${node} did not become Ready"
    return 1
  }

  radp_log_info "--- ${node} upgrade complete ---"
  return 0
}
