#!/usr/bin/env bash
# @cmd
# @desc Initialize VF configuration directory
# @meta passthrough
# @example init vf
# @example init vf --dry-run
# @example init vf --force

cmd_init_vf() {
  # Set environment variables from homelabctl config
  if [[ -n "${gr_radp_extend_homelabctl_vf_config_dir:-}" ]]; then
    export RADP_VAGRANT_CONFIG_DIR="$gr_radp_extend_homelabctl_vf_config_dir"
  else
    # Default to homelabctl config path + vagrant
    export RADP_VAGRANT_CONFIG_DIR="${gr_fw_user_config_path}/vagrant"
  fi

  if [[ -n "${gr_radp_extend_homelabctl_vf_env:-}" ]]; then
    export RADP_VAGRANT_ENV="$gr_radp_extend_homelabctl_vf_env"
  fi

  # Passthrough all arguments to radp-vf init
  exec radp-vf init "$@"
}
