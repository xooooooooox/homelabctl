#!/usr/bin/env bash
# @cmd
# @desc Create a new Kubernetes join token
# @flag --print-join-command Print full join command after creation
# @example k8s token create
# @example k8s token create --print-join-command

cmd_k8s_token_create() {
  local print_join="${opt_print_join_command:-}"

  # Check if kubeadm is available
  if ! _k8s_is_kubeadm_available; then
    radp_log_error "kubeadm is not installed"
    return 1
  fi

  if [[ -n "$print_join" ]]; then
    # Create token and print join command
    local cmd
    cmd=$(_k8s_get_join_command) || {
      radp_log_error "Failed to create token and generate join command"
      return 1
    }
    echo "$cmd"
  else
    # Just create and print token
    local token
    token=$(_k8s_create_token) || return 1
    echo "$token"
  fi

  return 0
}
