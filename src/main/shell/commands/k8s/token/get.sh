#!/usr/bin/env bash
# @cmd
# @desc Get current valid Kubernetes token
# @flag --create Create new token if no valid token exists
# @flag --join-command Print full join command instead of just token
# @example k8s token get
# @example k8s token get --create
# @example k8s token get --join-command

cmd_k8s_token_get() {
  local create="${opt_create:-}"
  local join_command="${opt_join_command:-}"

  # Check if kubeadm is available
  if ! _k8s_is_kubeadm_available; then
    radp_log_error "kubeadm is not installed"
    return 1
  fi

  if [[ -n "$join_command" ]]; then
    # Print full join command
    local cmd
    cmd=$(_k8s_get_join_command) || {
      radp_log_error "Failed to generate join command"
      return 1
    }
    echo "$cmd"
  else
    # Get token only
    local create_flag="false"
    [[ -n "$create" ]] && create_flag="true"

    local token
    token=$(_k8s_get_token "$create_flag") || {
      radp_log_error "No valid token found"
      radp_log_info "Use --create to generate a new token"
      return 1
    }

    echo "$token"
  fi

  return 0
}
