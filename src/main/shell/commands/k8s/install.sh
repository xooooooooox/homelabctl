#!/usr/bin/env bash
# @cmd
# @desc Install Kubernetes (kubeadm, kubelet, kubectl)
# @option -t, --type <type> Install type: kubeadm or minikube (default: kubeadm)
# @option -v, --version <ver> Kubernetes version (default: 1.30)
# @flag --skip-prerequisites Skip prerequisites configuration
# @flag --skip-container-runtime Skip container runtime installation
# @flag --dry-run Show what would be done
# @example k8s install
# @example k8s install -v 1.29
# @example k8s install -t kubeadm -v 1.30

cmd_k8s_install() {
  local install_type="${opt_type:-$(_k8s_get_default_install_type)}"
  local version="${opt_version:-$(_k8s_get_default_version)}"
  local skip_prerequisites="${opt_skip_prerequisites:-}"
  local skip_container_runtime="${opt_skip_container_runtime:-}"

  # Enable dry-run mode if flag is set
  radp_set_dry_run "${opt_dry_run:-false}"

  radp_log_info "Installing Kubernetes..."
  radp_log_info "  Install type: $install_type"
  radp_log_info "  Version: $version"

  case "$install_type" in
    kubeadm)
      # Step 1: Check system requirements
      radp_log_info "Checking system requirements..."
      _k8s_check_requirements || return 1

      # Step 2: Configure prerequisites
      if [[ -z "$skip_prerequisites" ]]; then
        _k8s_configure_prerequisites || return 1
      else
        radp_log_info "Skipping prerequisites configuration"
      fi

      # Step 3: Install container runtime
      if [[ -z "$skip_container_runtime" ]]; then
        _k8s_install_container_runtime || return 1
      else
        radp_log_info "Skipping container runtime installation"
      fi

      # Step 4: Install kubeadm, kubelet, kubectl
      _k8s_install_kubeadm "$version" || return 1
      ;;

    minikube)
      radp_log_error "Minikube installation not yet implemented"
      return 1
      ;;

    *)
      radp_log_error "Invalid install type: $install_type"
      radp_log_info "Supported types: kubeadm, minikube"
      return 1
      ;;
  esac

  radp_log_info ""
  radp_log_info "Kubernetes components installed successfully!"
  radp_log_info ""
  radp_log_info "Next steps:"
  radp_log_info "  - Initialize master: homelabctl k8s init master -a <ip-address>"
  radp_log_info "  - Or join cluster:   homelabctl k8s init worker -c <master-ip>:6443"

  return 0
}
