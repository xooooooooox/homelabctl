#!/usr/bin/env bash
# docker configurer
# Provides runtime configuration functions for Docker

#######################################
# Configure Docker for non-root user access (rootless)
# Adds user to docker group for docker command access without sudo
# Arguments:
#   1 - user: Username to configure (default: current user)
# Returns:
#   0 - Success
#   1 - Failure
#######################################
_setup_configure_docker_rootless() {
  local user="${1:-$(radp_os_get_current_user)}"

  # Check if Docker is installed
  if ! _common_is_command_available docker; then
    radp_log_error "Docker is not installed. Please install Docker first."
    return 1
  fi

  # Check if user exists
  if ! id "$user" &>/dev/null; then
    radp_log_error "User '$user' does not exist"
    return 1
  fi

  radp_log_info "Configuring Docker rootless access for user '$user'..."

  # Ensure docker group exists
  radp_os_ensure_group "docker" || return 1

  # Add user to docker group
  radp_os_user_add_to_group "$user" "docker" || return 1

  # Verify docker access (if current user and not in dry-run mode)
  if [[ "$user" == "$(radp_os_get_current_user)" ]] && ! radp_is_dry_run; then
    radp_log_info "Testing Docker access..."
    # Use sg to run command in docker group context
    if sg docker -c 'docker ps' &>/dev/null; then
      radp_log_info "Docker access verified for user '$user'"
    else
      radp_log_warn "Docker access test failed. Please log out and back in to apply group changes."
    fi
  else
    radp_log_info "User '$user' added to docker group"
    radp_log_warn "User needs to log out and back in to apply group changes"
  fi

  return 0
}

#######################################
# Configure Docker HTTP/HTTPS proxy
# Sets up systemd drop-in for proxy environment variables
# Arguments:
#   1 - http_proxy: HTTP proxy URL
#   2 - https_proxy: HTTPS proxy URL (optional, defaults to http_proxy)
#   3 - no_proxy: Comma-separated bypass list (optional)
# Returns:
#   0 - Success
#   1 - Failure
#######################################
_setup_configure_docker_proxy() {
  local http_proxy="${1:?'HTTP proxy URL required'}"
  local https_proxy="${2:-$http_proxy}"
  local no_proxy="${3:-localhost,127.0.0.1}"

  # Check if Docker is installed
  if ! _common_is_command_available docker; then
    radp_log_error "Docker is not installed. Please install Docker first."
    return 1
  fi

  radp_log_info "Configuring Docker proxy..."

  # Configure proxy for docker service
  radp_os_service_configure_http_proxy "docker" "$http_proxy" "$https_proxy" "$no_proxy" || return 1

  # Also configure for containerd if it's managed separately
  if systemctl list-unit-files containerd.service &>/dev/null 2>&1; then
    radp_log_info "Configuring proxy for containerd service..."
    radp_os_service_configure_http_proxy "containerd" "$http_proxy" "$https_proxy" "$no_proxy" || true
  fi

  # Restart Docker to apply changes
  radp_log_info "Restarting Docker service to apply proxy settings..."
  radp_os_service_restart "docker" || {
    radp_log_error "Failed to restart Docker service"
    return 1
  }

  radp_log_info "Docker proxy configured successfully"
  return 0
}

#######################################
# Configure Docker registry mirrors
# Updates /etc/docker/daemon.json with mirror configuration
# Arguments:
#   1 - mirrors: Comma-separated list of mirror URLs
# Returns:
#   0 - Success
#   1 - Failure
#######################################
_setup_configure_docker_mirrors() {
  local mirrors="${1:?'Mirror URLs required (comma-separated)'}"

  # Check if Docker is installed
  if ! _common_is_command_available docker; then
    radp_log_error "Docker is not installed. Please install Docker first."
    return 1
  fi

  local daemon_json="/etc/docker/daemon.json"

  radp_log_info "Configuring Docker registry mirrors..."

  # Build mirrors JSON array for display
  local mirrors_json="["
  local first=true
  IFS=',' read -ra mirror_list <<<"$mirrors"
  for mirror in "${mirror_list[@]}"; do
    mirror=$(echo "$mirror" | xargs) # trim whitespace
    if [[ -n "$mirror" ]]; then
      if [[ "$first" != true ]]; then
        mirrors_json+=","
      fi
      mirrors_json+="\"${mirror}\""
      first=false
    fi
  done
  mirrors_json+="]"

  # Check for dry-run mode
  if radp_dry_run_skip "Configure Docker registry mirrors in $daemon_json"; then
    radp_log_info "[dry-run] Would configure mirrors: $mirrors_json"
    return 0
  fi

  # Create docker config directory
  $gr_sudo mkdir -p /etc/docker || return 1

  # Check if daemon.json exists and merge
  if [[ -f "$daemon_json" ]]; then
    radp_log_info "Updating existing $daemon_json..."

    # Backup original
    if [[ ! -f "${daemon_json}.bak" ]]; then
      $gr_sudo cp "$daemon_json" "${daemon_json}.bak"
    fi

    # Use jq if available, otherwise simple replacement
    if _common_is_command_available jq; then
      local tmp_file
      tmp_file=$(mktemp)
      jq --argjson mirrors "$mirrors_json" '. + {"registry-mirrors": $mirrors}' "$daemon_json" >"$tmp_file" &&
        $gr_sudo mv "$tmp_file" "$daemon_json"
    else
      # Simple approach: create new config
      radp_log_warn "jq not found, creating new daemon.json (existing config will be overwritten)"
      $gr_sudo tee "$daemon_json" >/dev/null <<EOF
{
  "registry-mirrors": ${mirrors_json}
}
EOF
    fi
  else
    # Create new daemon.json
    radp_log_info "Creating $daemon_json..."
    $gr_sudo tee "$daemon_json" >/dev/null <<EOF
{
  "registry-mirrors": ${mirrors_json}
}
EOF
  fi

  if [[ $? -ne 0 ]]; then
    radp_log_error "Failed to write daemon.json"
    return 1
  fi

  # Restart Docker to apply changes
  radp_log_info "Restarting Docker service to apply mirror settings..."
  radp_os_service_restart "docker" || {
    radp_log_error "Failed to restart Docker service"
    return 1
  }

  radp_log_info "Docker registry mirrors configured:"
  for mirror in "${mirror_list[@]}"; do
    mirror=$(echo "$mirror" | xargs)
    [[ -n "$mirror" ]] && radp_log_info "  - $mirror"
  done

  return 0
}

#######################################
# Remove Docker proxy configuration
# Returns:
#   0 - Success
#   1 - Failure
#######################################
_setup_configure_docker_remove_proxy() {
  radp_log_info "Removing Docker proxy configuration..."

  radp_os_service_remove_http_proxy "docker" || return 1

  # Also remove for containerd if configured
  if [[ -f "/etc/systemd/system/containerd.service.d/http-proxy.conf" ]]; then
    radp_os_service_remove_http_proxy "containerd" || true
  fi

  # Restart Docker to apply changes
  radp_os_service_restart "docker" || {
    radp_log_warn "Failed to restart Docker service"
  }

  radp_log_info "Docker proxy configuration removed"
  return 0
}
