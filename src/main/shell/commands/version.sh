#!/usr/bin/env bash
# @cmd
# @desc Show version information
# @example version

# Application version
# Update this value when releasing a new version
declare -gr gr_app_version="v0.2.11"

cmd_version() {
    echo "homelabctl $(radp_get_install_version "${gr_app_version}")"
}
