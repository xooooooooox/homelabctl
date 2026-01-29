#!/usr/bin/env bash
# @cmd
# @desc Clone dotfiles repository using yadm
# @option --repo-url <url> Dotfiles repository URL (HTTPS or SSH format)
# @option --class <class> Set yadm class before clone
# @option --https-user <user> Username for HTTPS authentication
# @option --https-token <token> Personal access token for HTTPS authentication
# @option --https-token-file <file> Path to file containing access token
# @option --ssh-key-file <file> Path to SSH private key file
# @option --ssh-host <host> Override SSH hostname/IP (for private servers)
# @option --ssh-port <port> Override SSH port (default 22)
# @option --user <name> Target user (default: current user, requires sudo for other users)
# @flag --bootstrap Run yadm bootstrap after clone
# @flag --decrypt Run yadm decrypt after clone (requires GPG key imported)
# @flag --strict-host-key Enable strict host key checking (default: disabled for automation)
# @flag --dry-run Show what would be done without making changes
# @example setup configure yadm --repo-url "https://github.com/user/dotfiles.git"
# @example setup configure yadm --repo-url "git@github.com:user/dotfiles.git" --ssh-key-file ~/.ssh/id_rsa --bootstrap
# @example setup configure yadm --repo-url "git@gitlab.local:user/dotfiles.git" --ssh-host 192.168.1.10 --decrypt

cmd_setup_configure_yadm() {
  local repo_url="${opt_repo_url:-}"
  local yadm_class="${opt_class:-}"
  local https_user="${opt_https_user:-}"
  local https_token="${opt_https_token:-}"
  local https_token_file="${opt_https_token_file:-}"
  local ssh_key_file="${opt_ssh_key_file:-}"
  local ssh_host="${opt_ssh_host:-}"
  local ssh_port="${opt_ssh_port:-22}"
  local target_user="${opt_user:-}"
  local bootstrap="${opt_bootstrap:-}"
  local decrypt="${opt_decrypt:-}"
  local strict_host_key="${opt_strict_host_key:-}"

  # Set dry-run mode from flag
  radp_set_dry_run "${opt_dry_run:-}"

  # Validate required variables
  if [[ -z "$repo_url" ]]; then
    radp_log_error "Repository URL is required (--repo-url)"
    return 1
  fi

  # Validate file existence
  if [[ -n "$ssh_key_file" && ! -f "$ssh_key_file" ]]; then
    radp_log_error "SSH key file not found: $ssh_key_file"
    return 1
  fi

  if [[ -n "$https_token_file" && ! -f "$https_token_file" ]]; then
    radp_log_error "Token file not found: $https_token_file"
    return 1
  fi

  # Determine target user
  local current_user
  current_user=$(whoami)

  if [[ -z "$target_user" ]]; then
    target_user="$current_user"
  elif [[ "$target_user" != "$current_user" && "$current_user" != "root" ]]; then
    radp_log_error "Cannot configure yadm for user '$target_user' without root privileges"
    radp_log_error "Run with sudo or omit --user to use current user"
    return 1
  fi

  radp_log_info "Configuring yadm clone for user '$target_user'..."

  if radp_dry_run_skip "Clone yadm repository for user '$target_user'"; then
    radp_log_info "[dry-run]   - Repository: $repo_url"
    [[ -n "$yadm_class" ]] && radp_log_info "[dry-run]   - Class: $yadm_class"
    [[ -n "$ssh_key_file" ]] && radp_log_info "[dry-run]   - SSH key: $ssh_key_file"
    [[ -n "$ssh_host" ]] && radp_log_info "[dry-run]   - SSH host override: $ssh_host"
    [[ -n "$bootstrap" ]] && radp_log_info "[dry-run]   - Would run bootstrap after clone"
    [[ -n "$decrypt" ]] && radp_log_info "[dry-run]   - Would run decrypt after clone"
    return 0
  fi

  # Install git if not present
  if ! command -v git &>/dev/null; then
    radp_log_info "Installing git (required by yadm)..."
    radp_exec_sudo "Install git" radp_os_install_pkgs git
  fi

  # Install yadm if not present
  if ! command -v yadm &>/dev/null; then
    radp_log_info "Installing yadm..."
    _configure_yadm_install
  fi

  # Get user's home directory
  local home_dir
  if [[ "$target_user" == "root" ]]; then
    home_dir="/root"
  else
    home_dir=$(getent passwd "$target_user" | cut -d: -f6)
    if [[ -z "$home_dir" ]]; then
      radp_log_error "User '$target_user' not found"
      return 1
    fi
  fi

  # Check if yadm repo already exists
  local yadm_repo_dir="${home_dir}/.local/share/yadm/repo.git"
  if [[ -d "$yadm_repo_dir" ]]; then
    radp_log_warn "yadm repository already exists for user '$target_user', skipping: $yadm_repo_dir"
    return 0
  fi

  # Prepare clone
  local final_url="$repo_url"
  local env_prefix=""
  local clone_opts="--no-bootstrap"

  if _configure_yadm_is_ssh_url "$repo_url"; then
    # SSH clone
    local ssh_cmd
    ssh_cmd=$(_configure_yadm_build_ssh_command "$ssh_key_file" "$ssh_host" "$ssh_port" "$strict_host_key")

    if ! _configure_yadm_test_ssh "$repo_url" "$ssh_cmd"; then
      radp_log_error "Cannot reach repository: $repo_url"
      return 1
    fi

    env_prefix="GIT_SSH_COMMAND=\"$ssh_cmd\""
  else
    # HTTPS clone
    final_url=$(_configure_yadm_build_https_url "$repo_url" "$https_user" "$https_token" "$https_token_file")
  fi

  # Set yadm class if specified
  if [[ -n "$yadm_class" ]]; then
    radp_log_info "Setting yadm class to: $yadm_class"
    if [[ "$current_user" == "root" && "$target_user" != "root" ]]; then
      su - "$target_user" -c "yadm config local.class \"$yadm_class\""
    else
      yadm config local.class "$yadm_class"
    fi
  fi

  # Execute yadm clone
  radp_log_info "Cloning yadm repository..."
  if [[ "$current_user" == "root" && "$target_user" != "root" ]]; then
    su - "$target_user" -c "$env_prefix yadm clone $clone_opts \"$final_url\""
  else
    eval "$env_prefix yadm clone $clone_opts \"$final_url\""
  fi

  radp_log_info "yadm clone completed for user '$target_user'"

  # Run yadm decrypt if requested
  if [[ -n "$decrypt" ]]; then
    radp_log_info "Running yadm decrypt for user '$target_user'..."
    if [[ "$current_user" == "root" && "$target_user" != "root" ]]; then
      su - "$target_user" -c "yadm decrypt" || {
        radp_log_warn "yadm decrypt failed - ensure GPG key is imported"
      }
    else
      yadm decrypt || {
        radp_log_warn "yadm decrypt failed - ensure GPG key is imported"
      }
    fi
  fi

  # Run yadm bootstrap if requested
  if [[ -n "$bootstrap" ]]; then
    radp_log_info "Running yadm bootstrap for user '$target_user'..."
    if [[ "$current_user" == "root" && "$target_user" != "root" ]]; then
      su - "$target_user" -c "yadm bootstrap" || {
        radp_log_warn "yadm bootstrap failed or not available"
      }
    else
      yadm bootstrap || {
        radp_log_warn "yadm bootstrap failed or not available"
      }
    fi
  fi

  radp_log_info "yadm setup completed for user '$target_user'"
}

_configure_yadm_install() {
  local yadm_url="https://github.com/yadm-dev/yadm/raw/master/yadm"
  local pm
  pm=$(radp_os_get_distro_pm)

  case "$pm" in
    apt|apt-get)
      radp_exec_sudo "Update apt cache" apt-get update -qq
      radp_exec_sudo "Install yadm" apt-get install -y -qq yadm 2>/dev/null || {
        radp_exec_sudo "Download yadm from GitHub" curl -fLo /usr/local/bin/yadm "$yadm_url"
        ${gr_sudo:-} chmod +x /usr/local/bin/yadm
      }
      ;;
    dnf)
      radp_exec_sudo "Install yadm" dnf install -y -q yadm 2>/dev/null || {
        radp_exec_sudo "Download yadm from GitHub" curl -fLo /usr/local/bin/yadm "$yadm_url"
        ${gr_sudo:-} chmod +x /usr/local/bin/yadm
      }
      ;;
    yum)
      radp_exec_sudo "Download yadm from GitHub" curl -fLo /usr/local/bin/yadm "$yadm_url"
      ${gr_sudo:-} chmod +x /usr/local/bin/yadm
      ;;
    pacman)
      radp_exec_sudo "Install yadm" pacman -S --noconfirm yadm
      ;;
    apk)
      radp_exec_sudo "Install yadm" apk add --quiet yadm 2>/dev/null || {
        radp_exec_sudo "Download yadm from GitHub" curl -fLo /usr/local/bin/yadm "$yadm_url"
        ${gr_sudo:-} chmod +x /usr/local/bin/yadm
      }
      ;;
    brew)
      radp_exec "Install yadm" brew install yadm
      ;;
    *)
      radp_log_info "Installing yadm from GitHub..."
      radp_exec_sudo "Download yadm from GitHub" curl -fLo /usr/local/bin/yadm "$yadm_url"
      ${gr_sudo:-} chmod +x /usr/local/bin/yadm
      ;;
  esac

  if ! command -v yadm &>/dev/null; then
    radp_log_error "Failed to install yadm"
    return 1
  fi

  radp_log_info "yadm installed successfully"
}

_configure_yadm_is_ssh_url() {
  local url="$1"
  [[ "$url" =~ ^git@ ]] || [[ "$url" =~ ^ssh:// ]]
}

_configure_yadm_build_ssh_command() {
  local key_file="$1"
  local host="$2"
  local port="$3"
  local strict="$4"

  local ssh_opts="-o BatchMode=yes"

  if [[ -z "$strict" ]]; then
    ssh_opts="$ssh_opts -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
  fi

  if [[ -n "$key_file" ]]; then
    ssh_opts="$ssh_opts -i $key_file"
  fi

  if [[ -n "$host" ]]; then
    ssh_opts="$ssh_opts -o HostName=$host"
  fi

  if [[ -n "$port" && "$port" != "22" ]]; then
    ssh_opts="$ssh_opts -o Port=$port"
  fi

  echo "ssh $ssh_opts"
}

_configure_yadm_build_https_url() {
  local url="$1"
  local user="$2"
  local token="$3"
  local token_file="$4"

  local resolved_token=""
  if [[ -n "$token" ]]; then
    resolved_token="$token"
  elif [[ -n "$token_file" ]]; then
    resolved_token=$(cat "$token_file")
  fi

  if [[ -n "$resolved_token" ]]; then
    if [[ -n "$user" ]]; then
      echo "$url" | sed "s|https://|https://${user}:${resolved_token}@|"
    else
      echo "$url" | sed "s|https://|https://${resolved_token}@|"
    fi
  else
    echo "$url"
  fi
}

_configure_yadm_test_ssh() {
  local url="$1"
  local ssh_cmd="$2"

  # Extract host from URL
  local host
  if [[ "$url" =~ ^git@([^:]+): ]]; then
    host="${BASH_REMATCH[1]}"
  elif [[ "$url" =~ ^ssh://[^@]+@([^/]+) ]]; then
    host="${BASH_REMATCH[1]}"
  else
    radp_log_warn "Could not extract host from URL, skipping connectivity test"
    return 0
  fi

  radp_log_info "Testing SSH connectivity to $host..."
  if $ssh_cmd -T "git@$host" 2>/dev/null || [[ $? -eq 1 ]]; then
    radp_log_info "SSH connectivity OK"
    return 0
  else
    radp_log_error "SSH connectivity failed to $host"
    return 1
  fi
}
