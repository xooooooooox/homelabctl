#!/usr/bin/env bash
# @cmd
# @desc Show homelabctl version information

cmd_version() {
  # Version is loaded from config/config.yaml (radp.extend.homelabctl.version)
  echo "homelabctl $(radp_get_install_version "${gr_radp_extend_homelabctl_version:-v0.1.0}")"
}
