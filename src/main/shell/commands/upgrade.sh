#!/usr/bin/env bash
# @cmd
# @desc Upgrade homelabctl to the latest version
# @meta passthrough

cmd_upgrade() {
  radp_cli_upgrade_self "$@"
}
