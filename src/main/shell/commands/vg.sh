#!/usr/bin/env bash
# @cmd
# @desc Run vagrant commands (passthrough to radp-vf vg)
# @meta passthrough
# @example vg status
# @example vg up
# @example vg ssh node-1
# @example vg provision myvm --provision-with shell
# @example vg --help
# @example RADP_VAGRANT_ENV=prod vg up

# All arguments are passed through to radp-vf vg
cmd_vg() {
  if ! command -v radp-vf &>/dev/null; then
    radp_log_error "radp-vf not found in PATH. Install radp-vagrant-framework first."
    radp_log_error "see: https://github.com/xooooooooox/radp-vagrant-framework#installation"
    return 1
  fi

  exec radp-vf vg "$@"
}
