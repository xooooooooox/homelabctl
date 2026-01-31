#!/usr/bin/env bash
# @cmd
# @desc Show version information

# Application version
# Update this value when releasing a new version
declare -gr gr_app_version="v0.1.17"

cmd_version() {
    echo "homelabctl $(radp_get_install_version "${gr_app_version}")"
}
