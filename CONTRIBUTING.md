# Contributing

## Development Setup

1. Clone the repository:

```shell
git clone https://github.com/xooooooooox/homelabctl.git
cd homelabctl
```

2. Ensure radp-bash-framework is installed and in PATH:

```shell
export PATH="/path/to/radp-bash-framework/src/main/shell/bin:$PATH"
```

3. Set radp-vagrant-framework home (for vf commands):

```shell
export RADP_VF_HOME="/path/to/radp-vagrant-framework"
```

4. Run homelabctl:

```shell
./bin/homelabctl --help
./bin/homelabctl vf info
```

## Project Structure

```
homelabctl/
├── bin/
│   └── homelabctl              # CLI entry point
├── completions/
│   ├── homelabctl.bash         # Bash completion
│   └── homelabctl.zsh          # Zsh completion
├── src/main/shell/
│   ├── commands/               # Command implementations
│   │   ├── vg.sh               # homelabctl vg <cmd>
│   │   ├── vf/                 # homelabctl vf <subcommand>
│   │   │   ├── init.sh
│   │   │   ├── info.sh
│   │   │   ├── list.sh
│   │   │   └── ...
│   │   ├── setup/              # homelabctl setup <subcommand>
│   │   │   ├── install.sh
│   │   │   ├── list.sh
│   │   │   ├── info.sh
│   │   │   └── profile/        # homelabctl setup profile <subcommand>
│   │   │       ├── list.sh
│   │   │       ├── show.sh
│   │   │       └── apply.sh
│   │   ├── version.sh
│   │   └── completion.sh
│   ├── config/
│   │   └── config.yaml         # YAML configuration
│   ├── libs/                   # Project-specific libraries
│   │   └── setup/              # Setup feature libraries
│   │       ├── _common.sh      # Shared helper functions
│   │       ├── registry.sh     # Registry management
│   │       ├── installer.sh    # Installer utilities
│   │       ├── registry.yaml   # Package registry
│   │       ├── profiles/       # Profile definitions
│   │       └── installers/     # Package installers
│   └── vars/
│       └── constants.sh        # Version constants
├── packaging/                  # Distribution packaging
└── install.sh                  # Universal installer
```

## Version Management

Version is stored in `src/main/shell/config/config.yaml`:

```yaml
radp:
  extend:
    homelabctl:
      version: v0.1.0
```

Available as `$gr_radp_extend_homelabctl_version` in shell. This is the single source of truth for release management.

## Release Process

### Workflow Chain

```
release-prep (manual trigger)
       │
       ▼
   PR merged
       │
       ▼
create-version-tag
       │
       ├──────────────────────┬──────────────────────┐
       ▼                      ▼                      ▼
update-spec-version    update-homebrew-tap    (GitHub Release)
       │
       ├──────────────┐
       ▼              ▼
build-copr-package  build-obs-package
       │              │
       └──────┬───────┘
              ▼
  attach-release-packages
```

### Steps

1. Trigger `release-prep` workflow with bump_type (patch/minor/major/manual)
2. Review and merge the generated PR
3. Subsequent workflows run automatically

## GitHub Actions Reference

| Workflow                      | Trigger            | Purpose                      |
|-------------------------------|--------------------|------------------------------|
| `release-prep.yml`            | Manual on `main`   | Create release branch and PR |
| `create-version-tag.yml`      | PR merge or manual | Validate and create git tag  |
| `update-spec-version.yml`     | After tag creation | Update spec Version field    |
| `build-copr-package.yml`      | After spec update  | Trigger COPR build           |
| `build-obs-package.yml`       | After spec update  | Sync to OBS and build        |
| `update-homebrew-tap.yml`     | Tag push           | Update Homebrew formula      |
| `attach-release-packages.yml` | Release published  | Upload packages to release   |

## Required Secrets

Configure these secrets in GitHub repository settings (`Settings > Secrets and variables > Actions`):

### Homebrew Tap

| Secret               | Description                                               |
|----------------------|-----------------------------------------------------------|
| `HOMEBREW_TAP_TOKEN` | GitHub PAT with `repo` scope for homebrew-radp repository |

### COPR

| Secret          | Description                                                  |
|-----------------|--------------------------------------------------------------|
| `COPR_LOGIN`    | COPR API login (from https://copr.fedorainfracloud.org/api/) |
| `COPR_TOKEN`    | COPR API token                                               |
| `COPR_USERNAME` | COPR username                                                |
| `COPR_PROJECT`  | COPR project name (e.g., `radp`)                             |

### OBS

| Secret         | Description                                                    |
|----------------|----------------------------------------------------------------|
| `OBS_USERNAME` | OBS username                                                   |
| `OBS_PASSWORD` | OBS password or API token                                      |
| `OBS_PROJECT`  | OBS project name                                               |
| `OBS_PACKAGE`  | OBS package name                                               |
| `OBS_API_URL`  | (Optional) OBS API URL, defaults to `https://api.opensuse.org` |

## Skipping Workflows

If you don't need certain distribution channels:

- Delete the corresponding workflow file from `.github/workflows/`
- Or leave secrets unconfigured (workflow will skip with missing secrets)

## Setup Feature

The `setup` command manages software installation across different platforms.

### Directory Structure

```
src/main/shell/libs/setup/
├── _common.sh              # Shared helper functions (prefixed with _)
├── registry.sh             # Registry management functions
├── installer.sh            # Installer utilities
├── registry.yaml           # Package registry definitions
├── profiles/               # Profile definitions
│   └── recommend.yaml
└── installers/             # Package installers
    ├── fzf.sh
    ├── bat.sh
    └── ...
```

### Adding a New Package

1. **Add package definition** to `src/main/shell/libs/setup/registry.yaml`:

```yaml
packages:
  my-tool:
    desc: "My tool description"
    category: utilities        # Category for grouping
    homepage: https://...      # Optional
    check-cmd: my-tool         # Command to check if installed
    # Or use check-path for non-command packages:
    # check-path: ~/.my-tool/bin
```

2. **Create installer** at `src/main/shell/libs/setup/installers/my-tool.sh`:

```bash
#!/usr/bin/env bash

# Required function: _setup_install_<package_name>
# Arguments:
#   $1 - version (may be empty for latest)
# Returns:
#   0 - success
#   1 - failure
_setup_install_my_tool() {
    local version="${1:-}"

    # Use helper functions from _common.sh:
    # - _setup_detect_os        # Returns: darwin, linux
    # - _setup_detect_arch      # Returns: x86_64, arm64, aarch64
    # - _setup_log_info "msg"   # Info logging
    # - _setup_log_error "msg"  # Error logging
    # - _setup_download_file url dest  # Download with curl/wget
    # - _setup_extract_archive file dest  # Extract tar.gz/zip
    # - _setup_ensure_dir dir   # Create directory if not exists
    # - _setup_add_to_path dir  # Add to PATH in shell config

    local os arch
    os="$(_setup_detect_os)"
    arch="$(_setup_detect_arch)"

    _setup_log_info "Installing my-tool ${version:-latest} for $os/$arch"

    # Installation logic here...

    return 0
}
```

### Adding a New Profile

Create profile at `src/main/shell/libs/setup/profiles/my-profile.yaml`:

```yaml
name: my-profile
desc: "Profile description"
platform: any                 # any, darwin, linux

packages:
  - name: fzf
  - name: bat
  - name: my-tool
    version: "1.0.0"          # Optional: specific version
```

### User Extensions

Users can extend the setup feature by creating files in `~/.config/homelabctl/setup/`:

```
~/.config/homelabctl/setup/
├── registry.yaml           # Custom package definitions (merged with builtin)
├── profiles/               # Custom profiles
│   └── my-profile.yaml
└── installers/             # Custom installers
    └── my-tool.sh
```

User files take precedence over builtin files when names conflict.

### Testing

```bash
# List packages
./bin/homelabctl setup list
./bin/homelabctl setup list -c search

# Show package info
./bin/homelabctl setup info fzf

# Dry-run installation
./bin/homelabctl setup install my-tool --dry-run

# Test profile
./bin/homelabctl setup profile show my-profile
./bin/homelabctl setup profile apply my-profile --dry-run
```
