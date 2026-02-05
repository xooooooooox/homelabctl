#!/usr/bin/env bash
# @cmd
# @desc Run radp-vagrant-framework commands (passthrough to radp-vf)
# @meta passthrough
# @example vf --help
# @example vf info
# @example vf list
# @example vf list -v
# @example vf validate
# @example vf dump-config
# @example vf init myproject
# @example vf init myproject -t k8s-cluster
# @example vf template list
# @example vf vg status
# @example vf vg up
# @example vf vg ssh node-1

# All arguments are passed through to radp-vf
cmd_vf() {
  local radp_vf=""
  if ! _common_is_command_available radp-vf; then
    radp_log_error "radp-vf not found in PATH. Install radp-vagrant-framework first."
    radp_log_error "See: https://github.com/xooooooooox/radp-vagrant-framework#installation"
    return 1
  fi
  radp_vf="radp-vf"

  # Pass through to radp-vf
  if [[ -n "${gr_radp_extend_homelabctl_vf_config_base_filename:-}" ]]; then
    export RADP_VAGRANT_CONFIG_BASE_FILENAME="$gr_radp_extend_homelabctl_vf_config_base_filename"
  fi
  if [[ -n "${gr_radp_extend_homelabctl_vf_env:-}" ]]; then
      export RADP_VAGRANT_ENV="$gr_radp_extend_homelabctl_vf_env"
  fi
  if [[ -n "${gr_radp_extend_homelabctl_vf_config_dir:-}" ]]; then
    exec "$radp_vf" "$@" -c "$gr_radp_extend_homelabctl_vf_config_dir"
  else
    exec "$radp_vf" "$@"
  fi
}
