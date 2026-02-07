#!/usr/bin/env bash
# @cmd
# @desc Initialize setup user configuration directory
# @flag --force Overwrite existing files
# @flag --dry-run Show what would be created without making changes
# @example init setup
# @example init setup --dry-run
# @example init setup --force

cmd_init_setup() {
  local force="${opt_force:-false}"
  local dry_run="${opt_dry_run:-false}"
  radp_set_dry_run "${dry_run}"

  local user_dir
  user_dir=$(_setup_get_user_dir)
  local display_dir="${user_dir/#$HOME/~}"

  local created=0 skipped=0 overwritten=0

  # Print module header
  radp_log_raw "[setup] ${display_dir}/"

  # Create directory structure
  if ! radp_is_dry_run; then
    mkdir -p "$user_dir"/{profiles,installers}
  fi

  # Create README.md
  _init_process_file "$user_dir" "README.md" "$force" "$dry_run" \
    _init_create_setup_readme "$user_dir/README.md"

  # Create sample registry.yaml
  _init_process_file "$user_dir" "registry.yaml" "$force" "$dry_run" \
    _init_create_setup_registry "$user_dir/registry.yaml"

  # Create .gitkeep files (silent, not tracked in counts)
  if ! radp_is_dry_run; then
    touch "$user_dir/profiles/.gitkeep"
    touch "$user_dir/installers/.gitkeep"
  fi

  # Export counts for orchestrator
  _init_result_created=$created
  _init_result_skipped=$skipped
  _init_result_overwritten=$overwritten

  # Print summary (only when standalone)
  if [[ "${_init_orchestrated:-}" != "true" ]]; then
    radp_log_raw ""
    radp_log_raw "$(_init_format_summary "$dry_run")"
  fi

  return 0
}

#######################################
# Create setup README.md (silent file creator)
# Arguments:
#   1 - file path
#######################################
_init_create_setup_readme() {
  local file_path="$1"

  cat > "$file_path" << 'EOF'
# Setup User Configuration

This directory contains user-defined packages and profiles for `homelabctl setup`.

## Directory Structure

```
~/.config/homelabctl/setup/
├── README.md           # This file
├── registry.yaml       # User-defined package definitions
├── profiles/           # User-defined profiles
│   └── *.yaml
└── installers/         # User-defined installer scripts
    └── *.sh
```

## Usage

### Custom Package Definition

Add packages to `registry.yaml`:

```yaml
packages:
  my-tool:
    desc: "My custom tool"
    cmd: my-tool
    category: utilities
```

### Custom Installer

Create installer script in `installers/my-tool.sh`:

```bash
_setup_install_my_tool() {
  local version="${1:-latest}"
  # Installation logic here
}
```

### Custom Profile

Create profile in `profiles/my-profile.yaml`:

```yaml
name: my-profile
desc: "My custom profile"
platform: linux

packages:
  - name: my-tool
    desc: "Install my-tool"
```

## See Also

- `homelabctl setup list` - List available packages
- `homelabctl setup profile list` - List available profiles
- `homelabctl setup install <package>` - Install a package
EOF
}

#######################################
# Create sample setup registry.yaml (silent file creator)
# Arguments:
#   1 - file path
#######################################
_init_create_setup_registry() {
  local file_path="$1"

  cat > "$file_path" << 'EOF'
# User-defined packages for homelabctl setup
# These packages extend the builtin registry
#
# Example package definition:
#
# packages:
#   my-tool:
#     desc: "Description of my tool"
#     cmd: my-tool              # Command to check if installed
#     category: utilities       # Category: utilities, development, networking, etc.
#     requires:                 # Optional: required dependencies
#       - git
#     recommends:               # Optional: recommended packages
#       - fzf
#     conflicts:                # Optional: conflicting packages
#       - other-tool
#
# Note: Create corresponding installer in installers/my-tool.sh

packages: {}
EOF
}
