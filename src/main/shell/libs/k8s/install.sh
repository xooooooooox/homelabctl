#!/usr/bin/env bash
# K8S installation library
# Provides installation, prerequisites configuration, and initialization functions

#######################################
# Configure prerequisites for Kubernetes
# Includes: SELinux, firewalld, swap, kernel modules, sysctl
# Returns:
#   0 - Success
#   1 - Failure
#######################################
_k8s_configure_prerequisites() {
  radp_log_info "Configuring Kubernetes prerequisites..."

  # Step 1: Disable SELinux, firewalld, and swap
  radp_log_info "Disabling SELinux..."
  radp_os_disable_selinux || return 1

  radp_log_info "Disabling firewalld..."
  radp_os_disable_firewalld || return 1

  radp_log_info "Disabling swap..."
  radp_os_disable_swap || return 1

  # Step 2: Configure and load kernel modules
  radp_log_info "Configuring kernel modules..."
  radp_os_setup_kernel_modules "k8s" "overlay" "br_netfilter" || return 1

  # Step 3: Configure sysctl parameters for Kubernetes networking
  radp_log_info "Configuring sysctl parameters..."
  radp_os_sysctl_configure_persistent "k8s" \
    "net.bridge.bridge-nf-call-iptables=1" \
    "net.bridge.bridge-nf-call-ip6tables=1" \
    "net.ipv4.ip_forward=1" || return 1

  # Step 4: Verify configurations (skip in dry-run mode)
  if ! radp_is_dry_run; then
    radp_log_info "Verifying configurations..."

    if ! radp_os_is_kernel_module_loaded "overlay"; then
      radp_log_error "Kernel module 'overlay' not loaded"
      return 1
    fi

    if ! radp_os_is_kernel_module_loaded "br_netfilter"; then
      radp_log_error "Kernel module 'br_netfilter' not loaded"
      return 1
    fi

    radp_os_sysctl_check "net.bridge.bridge-nf-call-iptables" "1" || return 1
    radp_os_sysctl_check "net.bridge.bridge-nf-call-ip6tables" "1" || return 1
    radp_os_sysctl_check "net.ipv4.ip_forward" "1" || return 1
  fi

  radp_log_info "Prerequisites configured successfully"
  return 0
}

#######################################
# Configure HTTP proxy for container runtime systemd service
# Creates systemd drop-in file for containerd proxy settings
# Arguments:
#   1 - runtime: Container runtime name (containerd, docker)
# Returns:
#   0 - Success or proxy not enabled
#   1 - Failure
#######################################
_k8s_configure_container_runtime_proxy() {
  local runtime="${1:-containerd}"

  if ! _k8s_is_container_runtime_proxy_enabled; then
    radp_log_debug "Container runtime proxy not enabled, skipping"
    return 0
  fi

  local http_proxy https_proxy no_proxy
  http_proxy=$(_k8s_get_container_runtime_http_proxy)
  https_proxy=$(_k8s_get_container_runtime_https_proxy)
  no_proxy=$(_k8s_get_container_runtime_no_proxy)

  if [[ -z "$http_proxy" && -z "$https_proxy" ]]; then
    radp_log_warn "Proxy enabled but no proxy URLs configured"
    return 0
  fi

  local proxy_conf_dir="/etc/systemd/system/${runtime}.service.d"
  local proxy_conf_file="$proxy_conf_dir/http-proxy.conf"

  radp_log_info "Configuring HTTP proxy for $runtime..."

  radp_exec_sudo "Create proxy config directory" mkdir -p "$proxy_conf_dir" || return 1

  local proxy_content="[Service]
Environment=\"HTTP_PROXY=${http_proxy}\"
Environment=\"HTTPS_PROXY=${https_proxy}\"
Environment=\"NO_PROXY=${no_proxy}\""

  echo "$proxy_content" | radp_exec_sudo "Write proxy config" tee "$proxy_conf_file" >/dev/null || return 1

  radp_exec_sudo "Reload systemd daemon" systemctl daemon-reload

  radp_log_info "Proxy configured at $proxy_conf_file"
  return 0
}

#######################################
# Install container runtime (containerd)
# Returns:
#   0 - Success
#   1 - Failure
#######################################
_k8s_install_container_runtime() {
  radp_log_info "Installing container runtime (containerd)..."

  # Configure HTTP proxy BEFORE installation (if enabled)
  _k8s_configure_container_runtime_proxy "containerd" || {
    radp_log_warn "Failed to configure proxy, continuing without proxy"
  }

  # Install containerd via homelabctl setup
  radp_exec "Install containerd" homelabctl setup install containerd || {
    radp_log_error "Failed to install containerd"
    return 1
  }

  # Ensure proxy is applied after installation and restart
  _k8s_configure_container_runtime_proxy "containerd" || true
  radp_exec_sudo "Restart containerd" systemctl restart containerd 2>/dev/null || true

  radp_log_info "Container runtime installed successfully"
  return 0
}

#######################################
# Install kubeadm, kubelet, kubectl via yum
# Arguments:
#   1 - version: K8S version (e.g., 1.30)
# Returns:
#   0 - Success
#   1 - Failure
#######################################
__k8s_install_kubeadm_yum() {
  local version="${1:?'Version required'}"

  radp_log_info "Adding Kubernetes repository for version $version..."

  # Add Kubernetes yum repository
  local repo_content="[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v${version}/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v${version}/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni"

  echo "$repo_content" | radp_exec_sudo "Add Kubernetes yum repository" tee /etc/yum.repos.d/kubernetes.repo >/dev/null || {
    radp_log_error "Failed to add Kubernetes repository"
    return 1
  }

  # Install packages
  radp_exec_sudo "Install kubelet kubeadm kubectl" \
    yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes || return 1

  # Enable kubelet
  radp_exec_sudo "Enable kubelet service" systemctl enable kubelet

  return 0
}

#######################################
# Install kubeadm, kubelet, kubectl via apt
# Arguments:
#   1 - version: K8S version (e.g., 1.30)
# Returns:
#   0 - Success
#   1 - Failure
#######################################
__k8s_install_kubeadm_apt() {
  local version="${1:?'Version required'}"

  radp_log_info "Adding Kubernetes repository for version $version..."

  # Install prerequisites
  radp_exec_sudo "Update apt cache" apt-get update || return 1
  radp_exec_sudo "Install apt prerequisites" \
    apt-get install -y apt-transport-https ca-certificates curl gpg || return 1

  # Create keyrings directory if needed
  radp_exec_sudo "Create keyrings directory" mkdir -p -m 755 /etc/apt/keyrings

  # Add GPG key
  if ! radp_is_dry_run; then
    curl -fsSL "https://pkgs.k8s.io/core:/stable:/v${version}/deb/Release.key" | \
      $gr_sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg || return 1
  else
    radp_log_info "[DRY-RUN] Would download and install Kubernetes GPG key"
  fi

  # Add repository
  echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${version}/deb/ /" | \
    radp_exec_sudo "Add Kubernetes apt repository" tee /etc/apt/sources.list.d/kubernetes.list > /dev/null

  # Install packages
  radp_exec_sudo "Update apt cache" apt-get update || return 1
  radp_exec_sudo "Install kubelet kubeadm kubectl" \
    apt-get install -y kubelet kubeadm kubectl || return 1
  radp_exec_sudo "Hold kubernetes packages" apt-mark hold kubelet kubeadm kubectl || return 1

  # Enable kubelet
  radp_exec_sudo "Enable kubelet service" systemctl enable kubelet

  return 0
}

#######################################
# Install kubeadm, kubelet, kubectl
# Arguments:
#   1 - version: K8S version (default: from config)
# Returns:
#   0 - Success
#   1 - Failure
#######################################
_k8s_install_kubeadm() {
  local version="${1:-$(_k8s_get_default_version)}"

  radp_log_info "Installing kubeadm, kubelet, kubectl version $version..."

  local distro_id
  distro_id=$(radp_os_get_distro_id 2>/dev/null || echo "unknown")

  case "$distro_id" in
    centos|rhel|rocky|almalinux|fedora)
      __k8s_install_kubeadm_yum "$version" || return 1
      ;;
    ubuntu|debian)
      __k8s_install_kubeadm_apt "$version" || return 1
      ;;
    *)
      radp_log_error "Unsupported distribution: $distro_id"
      return 1
      ;;
  esac

  # Verify installation (skip in dry-run mode)
  if ! radp_is_dry_run; then
    local cmd
    for cmd in kubelet kubeadm kubectl; do
      if ! _common_is_command_available "$cmd"; then
        radp_log_error "Failed to install $cmd"
        return 1
      fi
    done

    radp_log_info "kubeadm version: $(kubeadm version -o short 2>/dev/null)"
    radp_log_info "kubectl version: $(kubectl version --client -o yaml 2>/dev/null | grep gitVersion | awk '{print $2}')"
  fi

  return 0
}

#######################################
# Initialize master node
# Arguments:
#   1 - apiserver_advertise_address: IP address for API server
#   2 - pod_network_cidr: Pod network CIDR (optional)
# Returns:
#   0 - Success
#   1 - Failure
#######################################
_k8s_init_master() {
  local apiserver_advertise_address="${1:?'API server address required'}"
  local pod_network_cidr="${2:-$(_k8s_get_default_pod_cidr)}"

  radp_log_info "Initializing Kubernetes master node..."
  radp_log_info "  API Server Address: $apiserver_advertise_address"
  radp_log_info "  Pod Network CIDR: $pod_network_cidr"

  # Step 1: Pull required images
  radp_log_info "Pulling Kubernetes images..."
  radp_exec_sudo "Pull K8S container images" kubeadm config images pull -v=5 || {
    radp_log_error "Failed to pull Kubernetes images"
    return 1
  }

  # Step 2: Initialize kubeadm
  radp_log_info "Running kubeadm init..."
  radp_exec_sudo "Initialize Kubernetes control plane" \
    kubeadm init \
      --apiserver-advertise-address="$apiserver_advertise_address" \
      --pod-network-cidr="$pod_network_cidr" || {
    radp_log_error "Failed to initialize Kubernetes master"
    return 1
  }

  # Step 3: Configure kubectl for current user
  radp_log_info "Configuring kubectl for current user..."
  radp_exec "Create .kube directory" mkdir -p "$HOME/.kube" || return 1
  radp_exec_sudo "Copy admin.conf" cp -f /etc/kubernetes/admin.conf "$HOME/.kube/config" || return 1
  radp_exec_sudo "Set kubeconfig ownership" chown "$(id -u)":"$(id -g)" "$HOME/.kube/config" || return 1

  # Step 4: Setup shell completion
  radp_log_info "Setting up kubectl completion..."
  if ! radp_is_dry_run; then
    if [[ -f "$HOME/.bashrc" ]]; then
      if ! grep -q 'kubectl completion bash' "$HOME/.bashrc"; then
        echo 'source <(kubectl completion bash)' >> "$HOME/.bashrc"
      fi
    fi
  fi

  # Step 5: Install CNI plugin
  local cni_plugin
  cni_plugin=$(_k8s_get_default_cni)
  radp_log_info "Installing CNI plugin ($cni_plugin)..."

  case "$cni_plugin" in
    flannel)
      _k8s_install_flannel "$apiserver_advertise_address" || return 1
      ;;
    *)
      radp_log_error "Unsupported CNI plugin: $cni_plugin"
      radp_log_info "Supported CNI plugins: flannel"
      return 1
      ;;
  esac

  # Step 6: Verify cluster (skip in dry-run mode)
  if ! radp_is_dry_run; then
    radp_log_info "Verifying cluster initialization..."
    if radp_wait_until "kubectl cluster-info" --max-attempts 5 --interval 10; then
      radp_log_info "Kubernetes master initialized successfully!"
    else
      radp_log_error "Failed to verify cluster initialization"
      return 1
    fi
  fi

  return 0
}

#######################################
# Install flannel CNI plugin
# Arguments:
#   1 - apiserver_address: API server IP for interface detection
# Returns:
#   0 - Success
#   1 - Failure
#######################################
_k8s_install_flannel() {
  local apiserver_address="${1:?'API server address required'}"

  local flannel_url
  flannel_url=$(_k8s_get_flannel_url)

  # In dry-run mode, just show what would be done
  if radp_is_dry_run; then
    radp_log_info "[DRY-RUN] Would download flannel manifest from: $flannel_url"
    radp_log_info "[DRY-RUN] Would apply flannel manifest to cluster"
    return 0
  fi

  local temp_dir
  temp_dir=$(mktemp -d)
  local flannel_yaml="$temp_dir/kube-flannel.yml"

  # Download flannel manifest
  curl -fsSL "$flannel_url" -o "$flannel_yaml" || {
    radp_log_error "Failed to download flannel manifest"
    rm -rf "$temp_dir"
    return 1
  }

  # Detect network interface for the API server IP
  local eth
  eth=$(ip -o addr show | grep "$apiserver_address" | awk '{print $2}' | head -1)

  if [[ -n "$eth" ]]; then
    radp_log_info "Detected network interface: $eth"
    # Add --iface argument to flannel container
    sed -i "/- --kube-subnet-mgr/a \        - --iface=$eth" "$flannel_yaml"
  fi

  # Apply flannel manifest
  kubectl apply -f "$flannel_yaml" || {
    radp_log_error "Failed to apply flannel manifest"
    rm -rf "$temp_dir"
    return 1
  }

  rm -rf "$temp_dir"

  # Wait for flannel to be ready
  if radp_wait_until "ip link show flannel.1 || ip link show cni0" --max-attempts 15 --interval 10 --message "Waiting for flannel to be ready..."; then
    radp_log_info "Flannel CNI installed successfully"
  else
    radp_log_warn "Flannel may not be fully ready, please verify manually"
  fi

  return 0
}

#######################################
# Initialize worker node and join cluster
# Arguments:
#   1 - control_plane: Master node address (ip:port format)
#   2 - ssh_user: SSH user for connecting to master (optional, default from config)
# Returns:
#   0 - Success
#   1 - Failure
#######################################
_k8s_init_worker() {
  local control_plane="${1:?'Control plane address required (ip:port)'}"
  local ssh_user="${2:-$(_k8s_get_ssh_user)}"

  # Validate control plane format
  if [[ ! "$control_plane" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+$ ]]; then
    radp_log_error "Invalid control plane format. Expected: ip:port (e.g., 192.168.1.100:6443)"
    return 1
  fi

  local master_ip="${control_plane%:*}"
  local master_port="${control_plane#*:}"

  radp_log_info "Joining Kubernetes cluster..."
  radp_log_info "  Master: $master_ip:$master_port"

  # In dry-run mode, show what would be done
  if radp_is_dry_run; then
    radp_log_info "[DRY-RUN] Would retrieve join credentials from master via SSH"
    radp_log_info "[DRY-RUN] Would run: kubeadm join $control_plane --token <token> --discovery-token-ca-cert-hash <hash>"
    radp_log_info "[DRY-RUN] Would copy kubeconfig from master"
    return 0
  fi

  # Get join information from master
  local token discovery_hash

  # Try to get token and hash from master via SSH
  if _common_is_command_available ssh; then
    radp_log_info "Retrieving join credentials from master..."

    token=$(ssh -o StrictHostKeyChecking=no "${ssh_user}@${master_ip}" "kubeadm token create" 2>/dev/null) || {
      radp_log_error "Failed to get token from master. Ensure SSH access is configured."
      radp_log_info "Alternatively, run on master: kubeadm token create --print-join-command"
      return 1
    }

    discovery_hash=$(ssh -o StrictHostKeyChecking=no "${ssh_user}@${master_ip}" \
      "openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'" 2>/dev/null)

    if [[ -z "$discovery_hash" ]]; then
      radp_log_error "Failed to get CA hash from master"
      return 1
    fi
    discovery_hash="sha256:$discovery_hash"
  else
    radp_log_error "SSH not available. Please provide join command manually."
    radp_log_info "Run on master: kubeadm token create --print-join-command"
    return 1
  fi

  # Join the cluster
  radp_log_info "Running kubeadm join..."
  radp_exec_sudo "Join Kubernetes cluster" \
    kubeadm join "$control_plane" \
      --token "$token" \
      --discovery-token-ca-cert-hash "$discovery_hash" || {
    radp_log_error "Failed to join cluster"
    return 1
  }

  # Setup kubeconfig
  radp_log_info "Setting up kubeconfig..."
  mkdir -p "$HOME/.kube"
  scp -o StrictHostKeyChecking=no "${ssh_user}@${master_ip}:/etc/kubernetes/admin.conf" "$HOME/.kube/config" 2>/dev/null || {
    radp_log_warn "Failed to copy kubeconfig from master"
  }

  if [[ -f "$HOME/.kube/config" ]]; then
    chmod 600 "$HOME/.kube/config"
  fi

  radp_log_info "Worker node joined cluster successfully!"
  return 0
}
