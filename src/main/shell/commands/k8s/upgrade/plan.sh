#!/usr/bin/env bash
# @cmd
# @desc Show kubeadm upgrade plan (run on the first control plane node)
# @example k8s upgrade plan

cmd_k8s_upgrade_plan() {
  if ! _k8s_is_kubeadm_available; then
    radp_log_error "kubeadm is not installed"
    return 1
  fi

  _k8s_upgrade_plan || return 1
  return 0
}
