# @cmd
# @desc Show homelabctl version information

cmd_version() {
    # Version is loaded from src/main/shell/vars/constants.sh
    echo "homelabctl ${gr_homelabctl_version:-v0.1.0}"
}
