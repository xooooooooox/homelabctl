#!/usr/bin/env bash
# @cmd
# @desc Configure Docker acceleration (proxy or registry mirrors)
# @option --proxy <url> HTTP/HTTPS proxy URL (e.g., http://192.168.1.1:8080)
# @option --https-proxy <url> HTTPS proxy URL (default: same as --proxy)
# @option --no-proxy <list> Comma-separated hosts to bypass proxy (default: localhost,127.0.0.1)
# @option --mirrors <list> Comma-separated registry mirror URLs
# @flag --remove-proxy Remove existing proxy configuration
# @flag --dry-run Show what would be done without making changes
# @example setup configure docker acceleration --mirrors "https://mirror.ccs.tencentyun.com"
# @example setup configure docker acceleration --proxy "http://192.168.1.1:8080"
# @example setup configure docker acceleration --proxy "http://proxy:8080" --no-proxy "localhost,127.0.0.1,10.0.0.0/8"
# @example setup configure docker acceleration --remove-proxy

cmd_setup_configure_docker_acceleration() {
  local proxy="${opt_proxy:-}"
  local https_proxy="${opt_https_proxy:-$proxy}"
  local no_proxy="${opt_no_proxy:-localhost,127.0.0.1}"
  local mirrors="${opt_mirrors:-}"
  local remove_proxy="${opt_remove_proxy:-}"
  local dry_run="${opt_dry_run:-}"

  # Set dry-run mode from flag
  radp_set_dry_run "$dry_run"

  # Validate options
  if [[ -z "$proxy" && -z "$mirrors" && -z "$remove_proxy" ]]; then
    radp_log_error "At least one of --proxy, --mirrors, or --remove-proxy is required"
    radp_log_info ""
    radp_log_info "Examples:"
    radp_log_info "  Configure proxy:   homelabctl setup configure docker acceleration --proxy http://proxy:8080"
    radp_log_info "  Configure mirrors: homelabctl setup configure docker acceleration --mirrors https://mirror.example.com"
    radp_log_info "  Remove proxy:      homelabctl setup configure docker acceleration --remove-proxy"
    return 1
  fi

  # Load configurer
  if ! _setup_load_configurer "docker"; then
    radp_log_error "Docker configurer not found"
    return 1
  fi

  # Handle remove proxy
  if [[ -n "$remove_proxy" ]]; then
    if [[ -n "$dry_run" ]]; then
      radp_log_info "[dry-run] Would remove Docker proxy configuration"
      radp_log_info "[dry-run] Files to be removed:"
      radp_log_info "  - /etc/systemd/system/docker.service.d/http-proxy.conf"
      radp_log_info "  - /etc/systemd/system/containerd.service.d/http-proxy.conf (if exists)"
      return 0
    fi
    _setup_configure_docker_remove_proxy
    return $?
  fi

  # Handle proxy configuration
  if [[ -n "$proxy" ]]; then
    if [[ -n "$dry_run" ]]; then
      radp_log_info "[dry-run] Would configure Docker proxy"
      radp_log_info "[dry-run] Settings:"
      radp_log_info "  HTTP_PROXY:  $proxy"
      radp_log_info "  HTTPS_PROXY: $https_proxy"
      radp_log_info "  NO_PROXY:    $no_proxy"
      radp_log_info "[dry-run] Files to be created/updated:"
      radp_log_info "  - /etc/systemd/system/docker.service.d/http-proxy.conf"
      radp_log_info "  - /etc/systemd/system/containerd.service.d/http-proxy.conf"
      radp_log_info "[dry-run] Docker service would be restarted"
    else
      _setup_configure_docker_proxy "$proxy" "$https_proxy" "$no_proxy" || return 1
    fi
  fi

  # Handle mirrors configuration
  if [[ -n "$mirrors" ]]; then
    if [[ -n "$dry_run" ]]; then
      radp_log_info "[dry-run] Would configure Docker registry mirrors"
      radp_log_info "[dry-run] Mirrors:"
      IFS=',' read -ra mirror_list <<< "$mirrors"
      for mirror in "${mirror_list[@]}"; do
        mirror=$(echo "$mirror" | xargs)
        [[ -n "$mirror" ]] && radp_log_info "  - $mirror"
      done
      radp_log_info "[dry-run] File to be updated: /etc/docker/daemon.json"
      radp_log_info "[dry-run] Docker service would be restarted"
    else
      _setup_configure_docker_mirrors "$mirrors" || return 1
    fi
  fi

  return 0
}
