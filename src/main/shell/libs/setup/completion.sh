#!/usr/bin/env bash
# Setup shell completion helper functions
# These functions are called by the generated shell completion scripts

#######################################
# Complete package names
# Called by shell completion for: setup install, setup info
# Outputs:
#   Package names, one per line
#######################################
_homelabctl_complete_packages() {
    homelabctl -q setup list --names-only 2>/dev/null
}

#######################################
# Complete category names
# Called by shell completion for: setup list -c
# Outputs:
#   Category names, one per line
#######################################
_homelabctl_complete_categories() {
    homelabctl -q setup list --category-names 2>/dev/null
}

#######################################
# Complete profile names
# Called by shell completion for: setup profile show, setup profile apply
# Outputs:
#   Profile names, one per line
#######################################
_homelabctl_complete_profiles() {
    homelabctl -q setup profile list --names-only 2>/dev/null
}
