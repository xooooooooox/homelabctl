#!/usr/bin/env bash
# @cmd
# @desc Configure chrony for time synchronization
# @option --servers <list> Comma-separated NTP servers (e.g., "ntp.aliyun.com,ntp1.aliyun.com")
# @option --pool <pool> NTP pool to use if servers not specified (default: pool.ntp.org)
# @option --timezone <tz> Timezone to set (e.g., "Asia/Shanghai")
# @flag --sync-now Force immediate time sync after configuration
# @flag --dry-run Show what would be done without making changes
# @example setup configure chrony --servers "ntp.aliyun.com" --timezone "Asia/Shanghai"
# @example setup configure chrony --pool "cn.pool.ntp.org" --sync-now

cmd_setup_configure_chrony() {
  local servers="${opt_servers:-}"
  local pool="${opt_pool:-pool.ntp.org}"
  local timezone="${opt_timezone:-}"
  local sync_now="${opt_sync_now:-}"

  # Set dry-run mode from flag
  radp_set_dry_run "${opt_dry_run:-}"

  radp_log_info "Configuring chrony time synchronization..."

  # Install chrony if not present
  if ! _configure_chrony_install; then
    return 1
  fi

  # Configure NTP servers
  _configure_chrony_servers "$servers" "$pool"

  # Set timezone if specified
  if [[ -n "$timezone" ]]; then
    _configure_chrony_timezone "$timezone"
  fi

  # Start and enable service
  _configure_chrony_start

  # Force sync if requested
  if [[ -n "$sync_now" ]]; then
    _configure_chrony_sync
  fi

  radp_log_info "Chrony configuration completed"
  radp_log_info "Use 'chronyc sources' to view NTP sources"
  radp_log_info "Use 'chronyc tracking' to view sync status"
}

_configure_chrony_install() {
  if _common_is_command_available chronyc; then
    radp_log_info "chrony is already installed"
    return 0
  fi

  radp_log_info "Installing chrony..."

  local pm
  pm=$(radp_os_get_distro_pm)

  case "$pm" in
    yum)
      radp_exec_sudo "Install chrony via yum" yum install -y chrony
      ;;
    dnf)
      radp_exec_sudo "Install chrony via dnf" dnf install -y chrony
      ;;
    apt|apt-get)
      radp_exec_sudo "Update apt cache" apt-get update
      radp_exec_sudo "Install chrony via apt" apt-get install -y chrony
      ;;
    brew)
      radp_log_warn "chrony is not typically used on macOS"
      return 1
      ;;
    *)
      radp_log_error "Unsupported package manager: $pm"
      return 1
      ;;
  esac

  radp_log_info "chrony installed successfully"
}

_configure_chrony_find_config() {
  local configs=(
    "/etc/chrony.conf"
    "/etc/chrony/chrony.conf"
  )
  for conf in "${configs[@]}"; do
    if [[ -f "$conf" ]]; then
      echo "$conf"
      return 0
    fi
  done
  echo "/etc/chrony.conf"
}

_configure_chrony_servers() {
  local servers="$1"
  local pool="$2"

  local chrony_conf
  chrony_conf=$(_configure_chrony_find_config)

  if [[ -n "$servers" ]]; then
    radp_log_info "Configuring NTP servers: $servers"

    if radp_dry_run_skip "Configure servers in $chrony_conf"; then
      return 0
    fi

    # Backup original config
    if [[ -f "$chrony_conf" && ! -f "${chrony_conf}.orig" ]]; then
      ${gr_sudo:-} cp "$chrony_conf" "${chrony_conf}.orig"
      radp_log_info "Backed up original config to ${chrony_conf}.orig"
    fi

    # Check if already configured
    if grep -q "# Added by homelabctl" "$chrony_conf" 2>/dev/null; then
      radp_log_info "NTP servers already configured by homelabctl"
      return 0
    fi

    # Comment out existing server/pool lines
    ${gr_sudo:-} sed -i.bak -E 's/^([^#]*)(server|pool)\s+/#\1\2 /' "$chrony_conf"

    # Build new server lines
    local new_servers=""
    IFS=',' read -ra server_list <<< "$servers"
    for server in "${server_list[@]}"; do
      server=$(echo "$server" | xargs)
      if [[ -n "$server" ]]; then
        new_servers="${new_servers}server ${server} iburst\n"
      fi
    done

    # Append new servers
    echo -e "\n# Added by homelabctl\n${new_servers}" | ${gr_sudo:-} tee -a "$chrony_conf" >/dev/null
    ${gr_sudo:-} rm -f "${chrony_conf}.bak"
    ${gr_sudo:-} chmod 644 "$chrony_conf"

    radp_log_info "Configured NTP servers in $chrony_conf"
  else
    radp_log_info "Using NTP pool: $pool"
  fi
}

_configure_chrony_timezone() {
  local timezone="$1"

  radp_log_info "Setting timezone to: $timezone"

  if _common_is_command_available timedatectl; then
    radp_exec_sudo "Set timezone to $timezone" timedatectl set-timezone "$timezone"
  elif [[ -f "/usr/share/zoneinfo/$timezone" ]]; then
    radp_exec_sudo "Link timezone file" ln -sf "/usr/share/zoneinfo/$timezone" /etc/localtime
    if ! radp_is_dry_run; then
      echo "$timezone" | ${gr_sudo:-} tee /etc/timezone >/dev/null
    else
      radp_log_info "[dry-run] Write $timezone to /etc/timezone"
    fi
  else
    radp_log_warn "Cannot set timezone: $timezone not found"
    return 0
  fi

  radp_log_info "Timezone set to $timezone"
}

_configure_chrony_start() {
  local service_name=""

  # Detect service name
  if systemctl list-unit-files chronyd.service &>/dev/null 2>&1; then
    service_name="chronyd"
  elif systemctl list-unit-files chrony.service &>/dev/null 2>&1; then
    service_name="chrony"
  elif [[ -f /etc/redhat-release ]]; then
    service_name="chronyd"
  else
    service_name="chrony"
  fi

  radp_log_info "Enabling and starting $service_name service..."

  if _common_is_command_available systemctl; then
    radp_exec_sudo "Enable $service_name service" systemctl enable "$service_name" 2>/dev/null || true
    radp_exec_sudo "Restart $service_name service" systemctl restart "$service_name"
  elif _common_is_command_available service; then
    radp_exec_sudo "Restart $service_name service" service "$service_name" restart
  else
    radp_log_warn "Cannot manage chrony service: no systemctl or service command"
    return 0
  fi

  radp_log_info "$service_name service is running"
}

_configure_chrony_sync() {
  radp_log_info "Forcing immediate time synchronization..."

  if radp_dry_run_skip "Force time sync via chronyc makestep"; then
    return 0
  fi

  sleep 2
  if ${gr_sudo:-} chronyc makestep &>/dev/null; then
    radp_log_info "Time synchronized"
  else
    radp_log_warn "Could not force time sync (chronyc makestep failed)"
  fi

  radp_log_info "Time synchronization status:"
  chronyc tracking 2>/dev/null | head -5 || true
}
