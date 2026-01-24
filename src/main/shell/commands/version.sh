# @cmd
# @desc Show homelabctl version information

cmd_version() {
    # Version is loaded from config.yaml via radp.extend.homelabctl.version
    echo "homelabctl ${gr_radp_extend_homelabctl_version:-v0.1.0}"
}
