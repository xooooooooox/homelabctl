#!/usr/bin/env bash
# @cmd
# @desc Import GPG keys into user keyring
# @option --public-key <content> GPG public key content (ASCII-armored)
# @option --public-key-file <file> Path to GPG public key file
# @option --secret-key-file <file> Path to GPG secret key file
# @option --passphrase <pass> Passphrase for secret key
# @option --passphrase-file <file> Path to file containing passphrase
# @option --key-id <id> GPG key ID to fetch from keyserver
# @option --keyserver <url> Keyserver URL (default: keys.openpgp.org)
# @option --trust-level <level> Trust level (2=unknown, 3=marginal, 4=full, 5=ultimate)
# @option --ownertrust-file <file> Path to ownertrust file
# @option --user <name> Target user (default: current user, requires sudo for other users)
# @flag --dry-run Show what would be done without making changes
# @example setup configure gpg-import --secret-key-file ~/.secrets/key.asc --passphrase-file ~/.secrets/pass.txt
# @example setup configure gpg-import --public-key-file /path/to/colleague.asc --trust-level 4
# @example setup configure gpg-import --key-id 0x1234567890ABCDEF

cmd_setup_configure_gpg_import() {
  local public_key="${opt_public_key:-}"
  local public_key_file="${opt_public_key_file:-}"
  local secret_key_file="${opt_secret_key_file:-}"
  local passphrase="${opt_passphrase:-}"
  local passphrase_file="${opt_passphrase_file:-}"
  local key_id="${opt_key_id:-}"
  local keyserver="${opt_keyserver:-keys.openpgp.org}"
  local trust_level="${opt_trust_level:-}"
  local ownertrust_file="${opt_ownertrust_file:-}"
  local target_user="${opt_user:-}"

  # Set dry-run mode from flag
  radp_set_dry_run "${opt_dry_run:-}"

  # Validate input
  if [[ -z "$public_key" && -z "$public_key_file" && -z "$key_id" && -z "$secret_key_file" ]]; then
    radp_log_error "At least one key source must be provided:"
    radp_log_error "  --public-key, --public-key-file, --key-id, or --secret-key-file"
    return 1
  fi

  # Validate file existence
  for file_var in public_key_file secret_key_file passphrase_file ownertrust_file; do
    local file_path="${!file_var:-}"
    if [[ -n "$file_path" && ! -f "$file_path" ]]; then
      radp_log_error "File not found for --${file_var//_/-}: $file_path"
      return 1
    fi
  done

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

  radp_log_info "Configuring GPG key import for user '$target_user'..."

  # Install gnupg if needed
  if ! _common_is_command_available gpg; then
    radp_log_info "Installing gnupg..."
    radp_exec_sudo "Install gnupg" radp_os_install_pkgs gnupg --pm apt gnupg -- --pm yum gnupg2 -- --pm dnf gnupg2 --
  fi

  if radp_dry_run_skip "Import GPG keys for user '$target_user'"; then
    [[ -n "$public_key" ]] && radp_log_info "[dry-run]   - Import public key from content"
    [[ -n "$public_key_file" ]] && radp_log_info "[dry-run]   - Import public key from: $public_key_file"
    [[ -n "$key_id" ]] && radp_log_info "[dry-run]   - Fetch key $key_id from $keyserver"
    [[ -n "$secret_key_file" ]] && radp_log_info "[dry-run]   - Import secret key from: $secret_key_file"
    [[ -n "$ownertrust_file" ]] && radp_log_info "[dry-run]   - Import ownertrust from: $ownertrust_file"
    [[ -n "$trust_level" ]] && radp_log_info "[dry-run]   - Set trust level: $trust_level"
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

  # Create .gnupg directory if needed
  if [[ ! -d "$gnupg_dir" ]]; then
    mkdir -p "$gnupg_dir"
    chmod 700 "$gnupg_dir"
    radp_log_info "Created ${gnupg_dir}"
  fi

  local imported_key_id=""
  local import_output

  # Import public key from content
  if [[ -n "$public_key" ]]; then
    radp_log_info "Importing public key from content..."
    import_output=$(echo "$public_key" | gpg --homedir "$gnupg_dir" --batch --import 2>&1) || true
    imported_key_id=$(echo "$import_output" | grep -oP 'key \K[A-F0-9]+' | head -1) || true
    radp_log_info "Imported public key"
  fi

  # Import public key from file
  if [[ -n "$public_key_file" ]]; then
    radp_log_info "Importing public key from file: $public_key_file"
    import_output=$(gpg --homedir "$gnupg_dir" --batch --import "$public_key_file" 2>&1) || true
    imported_key_id=$(echo "$import_output" | grep -oP 'key \K[A-F0-9]+' | head -1) || true
    radp_log_info "Imported public key from file"
  fi

  # Fetch key from keyserver
  if [[ -n "$key_id" ]]; then
    radp_log_info "Fetching key '$key_id' from keyserver '$keyserver'..."
    gpg --homedir "$gnupg_dir" --batch --keyserver "$keyserver" --recv-keys "$key_id"
    imported_key_id="$key_id"
    radp_log_info "Fetched key from keyserver"
  fi

  # Import secret key from file
  if [[ -n "$secret_key_file" ]]; then
    radp_log_info "Importing secret key from file: $secret_key_file"

    # Get passphrase
    local pass=""
    if [[ -n "$passphrase" ]]; then
      pass="$passphrase"
    elif [[ -n "$passphrase_file" ]]; then
      pass=$(cat "$passphrase_file")
    fi

    if [[ -n "$pass" ]]; then
      import_output=$(gpg --homedir "$gnupg_dir" --batch --yes \
        --pinentry-mode loopback \
        --passphrase "$pass" \
        --import "$secret_key_file" 2>&1) || true
    else
      import_output=$(gpg --homedir "$gnupg_dir" --batch --yes \
        --import "$secret_key_file" 2>&1) || true
    fi
    imported_key_id=$(echo "$import_output" | grep -oP 'key \K[A-F0-9]+' | head -1) || true
    radp_log_info "Imported secret key from file"
  fi

  # Import ownertrust from file
  if [[ -n "$ownertrust_file" ]]; then
    radp_log_info "Importing ownertrust from file: $ownertrust_file"
    gpg --homedir "$gnupg_dir" --batch --import-ownertrust "$ownertrust_file"
    radp_log_info "Imported ownertrust"
  fi

  # Set trust level for imported key
  if [[ -n "$trust_level" && -n "$imported_key_id" && -z "$ownertrust_file" ]]; then
    radp_log_info "Setting trust level to '$trust_level' for key '$imported_key_id'..."
    local fingerprint
    fingerprint=$(gpg --homedir "$gnupg_dir" --batch --with-colons --fingerprint "$imported_key_id" \
      | awk -F: '/^fpr:/ { print $10; exit }')
    if [[ -n "$fingerprint" ]]; then
      echo "${fingerprint}:${trust_level}:" | gpg --homedir "$gnupg_dir" --batch --import-ownertrust
      radp_log_info "Trust level set"
    else
      radp_log_warn "Could not determine fingerprint for key, skipping trust"
    fi
  fi

  # Fix ownership if running as root for another user
  if [[ "$current_user" == "root" && "$target_user" != "root" ]]; then
    chown -R "${target_user}:$(id -gn "$target_user")" "$gnupg_dir"
  fi

  radp_log_info "GPG key import completed for user '$target_user'"
}
