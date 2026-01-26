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
    homelabctl setup list --names-only 2>/dev/null
}

#######################################
# Complete category names
# Called by shell completion for: setup list -c
# Outputs:
#   Category names, one per line
#######################################
_homelabctl_complete_categories() {
    homelabctl setup list --category-names 2>/dev/null
}

#######################################
# Complete profile names
# Called by shell completion for: setup profile show, setup profile apply
# Outputs:
#   Profile names, one per line
#######################################
_homelabctl_complete_profiles() {
    homelabctl setup profile list --names-only 2>/dev/null
}
