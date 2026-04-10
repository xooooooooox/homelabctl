#!/usr/bin/env bash
# @cmd
# @desc Show kubeadm upgrade plan (run on the first control plane node)
# @option --ignore-preflight-errors <list> Comma-separated preflight errors to ignore (e.g., CoreDNSUnsupportedPlugins,CoreDNSMigration)
# @example k8s upgrade plan
# @example k8s upgrade plan --ignore-preflight-errors=CoreDNSUnsupportedPlugins,CoreDNSMigration

cmd_k8s_upgrade_plan() {
  local ignore_errors="${opt_ignore_preflight_errors:-}"

  if ! _k8s_is_kubeadm_available; then
    radp_log_error "kubeadm is not installed"
    return 1
  fi

  _k8s_upgrade_plan "$ignore_errors" || return 1
  return 0
}
