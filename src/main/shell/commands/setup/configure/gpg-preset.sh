#!/usr/bin/env bash
# @cmd
# @desc Preset GPG passphrase in gpg-agent cache for non-interactive operations
# @option --key-uid <uid> Key UID (email) to identify the key (e.g., user@example.com)
# @option --passphrase <pass> Passphrase content
# @option --passphrase-file <file> Path to file containing passphrase
# @option --user <name> Target user (default: current user, requires sudo for other users)
# @flag --no-auto-config Skip auto-configuring gpg-agent.conf with allow-preset-passphrase
# @flag --dry-run Show what would be done without making changes
# @example setup configure gpg-preset --key-uid "user@example.com" --passphrase-file ~/.secrets/pass.txt
# @example setup configure gpg-preset --key-uid "user@example.com" --passphrase "mypassphrase"

cmd_setup_configure_gpg_preset() {
  local key_uid="${opt_key_uid:-}"
  local passphrase="${opt_passphrase:-}"
  local passphrase_file="${opt_passphrase_file:-}"
  local target_user="${opt_user:-}"
  local no_auto_config="${opt_no_auto_config:-}"

  # Set dry-run mode from flag
  radp_set_dry_run "${opt_dry_run:-}"

  # Validate required variables
  if [[ -z "$key_uid" ]]; then
    radp_log_error "GPG key UID is required (--key-uid)"
    radp_log_error "Example: --key-uid \"user@example.com\""
    return 1
  fi

  # Validate passphrase source
  if [[ -z "$passphrase" && -z "$passphrase_file" ]]; then
    radp_log_error "Either --passphrase or --passphrase-file must be provided"
    return 1
  fi

  # Validate file existence
  if [[ -n "$passphrase_file" && ! -f "$passphrase_file" ]]; then
    radp_log_error "Passphrase file not found: $passphrase_file"
    return 1
  fi

  # Determine target user
  local current_user
  current_user=$(whoami)

  if [[ -z "$target_user" ]]; then
    target_user="$current_user"
  elif [[ "$target_user" != "$current_user" && "$current_user" != "root" ]]; then
    radp_log_error "Cannot configure GPG for user '$target_user' without root privileges"
    radp_log_error "Run with sudo or omit --user to use current user"
    return 1
  fi

  radp_log_info "Configuring GPG preset passphrase for user '$target_user'..."

  if radp_dry_run_skip "Preset GPG passphrase for user '$target_user'"; then
    radp_log_info "[dry-run]   - Key UID: $key_uid"
    [[ -n "$passphrase" ]] && radp_log_info "[dry-run]   - Passphrase: (from argument)"
    [[ -n "$passphrase_file" ]] && radp_log_info "[dry-run]   - Passphrase file: $passphrase_file"
    [[ -z "$no_auto_config" ]] && radp_log_info "[dry-run]   - Would configure allow-preset-passphrase in gpg-agent.conf"
    return 0
  fi

  # Get user's home directory
  local home_dir gnupg_dir
  if [[ "$target_user" == "root" ]]; then
    home_dir="/root"
  else
    home_dir=$(getent passwd "$target_user" | cut -d: -f6)
    if [[ -z "$home_dir" ]]; then
      radp_log_error "User '$target_user' not found"
      return 1
    fi
  fi
  gnupg_dir="${home_dir}/.gnupg"

  # Check if gnupg directory exists
  if [[ ! -d "$gnupg_dir" ]]; then
    radp_log_error "GPG directory not found for user '$target_user': $gnupg_dir"
    radp_log_error "Please import GPG keys first using: homelabctl setup configure gpg-import"
    return 1
  fi

  # Find gpg-preset-passphrase command
  local gpg_preset_cmd libexecdir
  libexecdir=$(gpgconf --list-dirs 2>/dev/null | awk -F: '/^libexecdir:/ {print $2}')

  if [[ -n "$libexecdir" && -x "${libexecdir}/gpg-preset-passphrase" ]]; then
    gpg_preset_cmd="${libexecdir}/gpg-preset-passphrase"
  elif _common_is_command_available gpg-preset-passphrase; then
    gpg_preset_cmd="gpg-preset-passphrase"
  else
    radp_log_error "gpg-preset-passphrase command not found"
    radp_log_error "Install gnupg2 or gnupg-agent package"
    return 1
  fi

  radp_log_info "Using gpg-preset-passphrase: $gpg_preset_cmd"

  # Configure gpg-agent.conf if needed
  local agent_conf="${gnupg_dir}/gpg-agent.conf"
  if [[ -z "$no_auto_config" ]]; then
    if [[ ! -f "$agent_conf" ]]; then
      echo "allow-preset-passphrase" > "$agent_conf"
      chmod 600 "$agent_conf"
      if [[ "$current_user" == "root" && "$target_user" != "root" ]]; then
        chown "${target_user}:$(id -gn "$target_user")" "$agent_conf"
      fi
      radp_log_info "Created $agent_conf with allow-preset-passphrase"
    elif ! grep -q "^allow-preset-passphrase" "$agent_conf"; then
      echo "allow-preset-passphrase" >> "$agent_conf"
      radp_log_info "Added allow-preset-passphrase to $agent_conf"
    else
      radp_log_info "allow-preset-passphrase already configured"
    fi
  fi

  # Reload gpg-agent
  radp_log_info "Reloading gpg-agent..."
  gpgconf --homedir "$gnupg_dir" --reload gpg-agent 2>/dev/null || {
    # Start gpg-agent if not running
    gpg-agent --homedir "$gnupg_dir" --daemon 2>/dev/null || true
  }

  # Get keygrip for the specified UID
  radp_log_info "Finding keygrip for UID: $key_uid"

  local keygrip
  # Get keygrip from the encryption subkey (ssb) associated with the UID
  keygrip=$(gpg --homedir "$gnupg_dir" --list-secret-keys --with-keygrip --with-colons 2>/dev/null | \
    awk -F: -v target_uid="$key_uid" '
      /^uid/ && $10 ~ target_uid { uid_found=1 }
      uid_found && /^ssb/ { ssb_found=1 }
      ssb_found && /^grp/ { print $10; ssb_found=0; uid_found=0 }
    ' | head -1)

  # If no subkey found, try the primary key
  if [[ -z "$keygrip" ]]; then
    keygrip=$(gpg --homedir "$gnupg_dir" --list-secret-keys --with-keygrip --with-colons 2>/dev/null | \
      awk -F: -v target_uid="$key_uid" '
        /^uid/ && $10 ~ target_uid { uid_found=1 }
        uid_found && /^grp/ { print $10; uid_found=0 }
      ' | head -1)
  fi

  if [[ -z "$keygrip" ]]; then
    radp_log_error "Could not find keygrip for UID: $key_uid"
    radp_log_error "Make sure the secret key is imported and the UID is correct"
    gpg --homedir "$gnupg_dir" --list-secret-keys --with-keygrip 2>/dev/null || true
    return 1
  fi

  radp_log_info "Found keygrip: $keygrip"

  # Verify keygrip exists in keyring
  if ! gpg --homedir "$gnupg_dir" --list-secret-keys --with-keygrip 2>/dev/null | grep -q "$keygrip"; then
    radp_log_error "Keygrip not found in secret keyring: $keygrip"
    return 1
  fi

  # Resolve passphrase
  local pass
  if [[ -n "$passphrase" ]]; then
    pass="$passphrase"
  elif [[ -n "$passphrase_file" ]]; then
    pass=$(cat "$passphrase_file")
  fi

  # Preset the passphrase
  radp_log_info "Presetting passphrase for keygrip: $keygrip"
  if echo "$pass" | "$gpg_preset_cmd" --homedir "$gnupg_dir" --preset "$keygrip"; then
    radp_log_info "Passphrase preset successfully for user '$target_user'"
  else
    radp_log_error "Failed to preset passphrase"
    return 1
  fi

  # Fix ownership
  if [[ "$current_user" == "root" && "$target_user" != "root" ]]; then
    chown -R "${target_user}:$(id -gn "$target_user")" "$gnupg_dir"
  fi

  radp_log_info "GPG preset passphrase configuration completed"
}
