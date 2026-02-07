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
  radp_set_dry_run "${opt_dry_run:-}"

  local user_dir
  user_dir=$(_setup_get_user_dir)

  radp_log_raw "Initializing setup user configuration..."
  radp_log_raw "  Directory: $user_dir"

  # Create directory structure
  radp_exec "Create setup user directory" mkdir -p "$user_dir"/{profiles,installers}

  # Create README.md
  if [[ ! -f "$user_dir/README.md" ]] || [[ "$force" == "true" ]]; then
    _init_create_setup_readme "$user_dir/README.md"
  else
    radp_log_raw "  Skipping README.md (already exists, use --force to overwrite)"
  fi

  # Create sample registry.yaml
  if [[ ! -f "$user_dir/registry.yaml" ]] || [[ "$force" == "true" ]]; then
    _init_create_setup_registry "$user_dir/registry.yaml"
  else
    radp_log_raw "  Skipping registry.yaml (already exists, use --force to overwrite)"
  fi

  # Create .gitkeep files
  radp_exec "Create profiles .gitkeep" touch "$user_dir/profiles/.gitkeep"
  radp_exec "Create installers .gitkeep" touch "$user_dir/installers/.gitkeep"

  radp_log_raw "Setup user configuration initialized at: $user_dir"
  return 0
}

#######################################
# Create setup README.md
# Arguments:
#   1 - file path
#######################################
_init_create_setup_readme() {
  local file_path="$1"

  radp_log_raw "  Creating README.md"

  if radp_is_dry_run; then
    radp_log_raw "[dry-run] Would create: $file_path"
    return 0
  fi

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
# Create sample setup registry.yaml
# Arguments:
#   1 - file path
#######################################
_init_create_setup_registry() {
  local file_path="$1"

  radp_log_raw "  Creating registry.yaml"

  if radp_is_dry_run; then
    radp_log_raw "[dry-run] Would create: $file_path"
    return 0
  fi

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
