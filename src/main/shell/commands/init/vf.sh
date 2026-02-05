#!/usr/bin/env bash
# @cmd
# @desc Initialize vagrant project (passthrough to radp-vf init)
# @meta passthrough
# @example init vf myproject
# @example init vf myproject -t k8s-cluster
# @example init vf --list-templates

# All arguments are passed through to radp-vf init
cmd_init_vf() {
  if ! _common_is_command_available radp-vf; then
    radp_log_error "radp-vf not found in PATH. Install radp-vagrant-framework first."
    radp_log_error "See: https://github.com/xooooooooox/radp-vagrant-framework#installation"
    return 1
  fi

  # Pass through to radp-vf init
  exec radp-vf init "$@"
}
