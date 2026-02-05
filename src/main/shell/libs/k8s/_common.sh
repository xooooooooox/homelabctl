#!/usr/bin/env bash
# K8S common helper functions
# Sourced by all k8s commands and libs

#######################################
# Get default K8S version
# Globals:
#   gr_radp_extend_homelabctl_k8s_default_version
# Outputs:
#   Default K8S version string
#######################################
_k8s_get_default_version() {
  echo "${gr_radp_extend_homelabctl_k8s_default_version:-1.30}"
}

#######################################
# Get default install type
# Globals:
#   gr_radp_extend_homelabctl_k8s_default_install_type
# Outputs:
#   Install type (kubeadm, minikube, etc.)
#######################################
_k8s_get_default_install_type() {
  echo "${gr_radp_extend_homelabctl_k8s_default_install_type:-kubeadm}"
}

#######################################
# Get default pod CIDR
# Globals:
#   gr_radp_extend_homelabctl_k8s_default_pod_cidr
# Outputs:
#   Pod network CIDR
#######################################
_k8s_get_default_pod_cidr() {
  echo "${gr_radp_extend_homelabctl_k8s_default_pod_cidr:-10.244.0.0/16}"
}

#######################################
# Get default CNI plugin
# Globals:
#   gr_radp_extend_homelabctl_k8s_default_cni
# Outputs:
#   CNI plugin name
#######################################
_k8s_get_default_cni() {
  echo "${gr_radp_extend_homelabctl_k8s_default_cni:-flannel}"
}

#######################################
# Get flannel manifest URL
# Globals:
#   gr_radp_extend_homelabctl_k8s_flannel_url
# Outputs:
#   Flannel manifest URL
#######################################
_k8s_get_flannel_url() {
  echo "${gr_radp_extend_homelabctl_k8s_flannel_url:-https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml}"
}

#######################################
# Get etcd backup home directory
# Globals:
#   gr_radp_extend_homelabctl_k8s_backup_home
# Outputs:
#   Backup directory path
#######################################
_k8s_get_backup_home() {
  echo "${gr_radp_extend_homelabctl_k8s_backup_home:-/var/opt/k8s/backups/etcd}"
}

#######################################
# Get extra config path
# Globals:
#   gr_radp_extend_homelabctl_k8s_extra_config_path
# Outputs:
#   Extra config directory path
#######################################
_k8s_get_extra_config_path() {
  echo "${gr_radp_extend_homelabctl_k8s_extra_config_path:-$HOME/.config/homelabctl/k8s}"
}

#######################################
# Get builtin defaults path for k8s addon
# Outputs:
#   Builtin defaults directory path
#######################################
_k8s_get_builtin_defaults_path() {
  echo "${RADP_APP_ROOT}/src/main/shell/libs/k8s/addon/defaults"
}

#######################################
# Get minimum CPU cores requirement
# Globals:
#   gr_radp_extend_homelabctl_k8s_min_cpu_cores
# Outputs:
#   Minimum CPU cores
#######################################
_k8s_get_min_cpu_cores() {
  echo "${gr_radp_extend_homelabctl_k8s_min_cpu_cores:-2}"
}

#######################################
# Get minimum RAM requirement in GB
# Globals:
#   gr_radp_extend_homelabctl_k8s_min_ram_gb
# Outputs:
#   Minimum RAM in GB
#######################################
_k8s_get_min_ram_gb() {
  echo "${gr_radp_extend_homelabctl_k8s_min_ram_gb:-2}"
}

#######################################
# Get backup retention days
# Globals:
#   gr_radp_extend_homelabctl_k8s_backup_keep_days
# Outputs:
#   Number of days to keep backups
#######################################
_k8s_get_backup_keep_days() {
  echo "${gr_radp_extend_homelabctl_k8s_backup_keep_days:-7}"
}

#######################################
# Get backup schedule (cron expression)
# Globals:
#   gr_radp_extend_homelabctl_k8s_backup_schedule
# Outputs:
#   Cron schedule expression
#######################################
_k8s_get_backup_schedule() {
  echo "${gr_radp_extend_homelabctl_k8s_backup_schedule:-0 2 * * *}"
}

#######################################
# Check if kubectl is available
# Wrapper for _common_is_command_available
# Returns:
#   0 if available, 1 if not
#######################################
_k8s_is_kubectl_available() {
  _common_is_command_available kubectl
}

#######################################
# Check if kubeadm is available
# Wrapper for _common_is_command_available
# Returns:
#   0 if available, 1 if not
#######################################
_k8s_is_kubeadm_available() {
  _common_is_command_available kubeadm
}

#######################################
# Check if helm is available
# Wrapper for _common_is_command_available
# Returns:
#   0 if available, 1 if not
#######################################
_k8s_is_helm_available() {
  _common_is_command_available helm
}

#######################################
# Check if K8S cluster is accessible
# Returns:
#   0 if accessible, 1 if not
#######################################
_k8s_is_cluster_accessible() {
  _k8s_is_kubectl_available || return 1
  kubectl cluster-info &>/dev/null
}

#######################################
# Check system requirements for K8S
# Wrapper for _common_check_requirements
# Arguments:
#   --skip-prompt  Skip confirmation prompt on failure
# Returns:
#   0 if requirements met, 1 if not
#######################################
_k8s_check_requirements() {
  _common_check_requirements \
    --min-cpu "$(_k8s_get_min_cpu_cores)" \
    --min-ram "$(_k8s_get_min_ram_gb)" \
    --product "Kubernetes" \
    "$@"
}

#######################################
# Check if container runtime proxy is enabled
# Globals:
#   gr_radp_extend_homelabctl_k8s_container_runtime_proxy_enabled
# Returns:
#   0 if enabled, 1 if not
#######################################
_k8s_is_container_runtime_proxy_enabled() {
  [[ "${gr_radp_extend_homelabctl_k8s_container_runtime_proxy_enabled:-false}" == "true" ]]
}

#######################################
# Get container runtime HTTP proxy
# Globals:
#   gr_radp_extend_homelabctl_k8s_container_runtime_proxy_http_proxy
# Outputs:
#   HTTP proxy URL
#######################################
_k8s_get_container_runtime_http_proxy() {
  echo "${gr_radp_extend_homelabctl_k8s_container_runtime_proxy_http_proxy:-}"
}

#######################################
# Get container runtime HTTPS proxy
# Globals:
#   gr_radp_extend_homelabctl_k8s_container_runtime_proxy_https_proxy
# Outputs:
#   HTTPS proxy URL
#######################################
_k8s_get_container_runtime_https_proxy() {
  echo "${gr_radp_extend_homelabctl_k8s_container_runtime_proxy_https_proxy:-}"
}

#######################################
# Get container runtime no proxy list
# Globals:
#   gr_radp_extend_homelabctl_k8s_container_runtime_proxy_no_proxy
# Outputs:
#   No proxy hosts
#######################################
_k8s_get_container_runtime_no_proxy() {
  echo "${gr_radp_extend_homelabctl_k8s_container_runtime_proxy_no_proxy:-localhost,127.0.0.1,10.96.0.0/12,10.244.0.0/16}"
}

#######################################
# Ensure helm is installed
# Returns:
#   0 if helm is available (installed if needed), 1 on failure
#######################################
_k8s_ensure_helm() {
  if _k8s_is_helm_available; then
    return 0
  fi

  radp_log_info "Installing helm..."

  # Try to install helm using homelabctl setup
  if _common_is_command_available homelabctl; then
    homelabctl setup install helm || {
      radp_log_error "Failed to install helm"
      return 1
    }
    return 0
  fi

  radp_log_error "helm is not installed and cannot be auto-installed"
  return 1
}
