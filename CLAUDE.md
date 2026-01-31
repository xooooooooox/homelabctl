# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

homelabctl is a CLI tool for managing homelab infrastructure, built on top of radp-bash-framework. It provides a unified interface for orchestrating various homelab components, starting with radp-vagrant-framework integration.

## Commands

### Running homelabctl
```bash
# Ensure radp-bash-framework is in PATH
export PATH="/path/to/radp-bash-framework/src/main/shell/bin:$PATH"

# Set radp-vagrant-framework home (for vf commands)
export RADP_VF_HOME="/path/to/radp-vagrant-framework"

./bin/homelabctl --help
./bin/homelabctl --config
./bin/homelabctl vf list
./bin/homelabctl vf vg up
```

### Available Commands
- `vf <cmd>` - Passthrough to radp-vf (all radp-vagrant-framework commands)
  - `vf init` - Initialize a vagrant project (supports -t/--template, --set options)
  - `vf info` - Show radp-vagrant-framework info
  - `vf list` - List clusters and guests (supports -v, --provisions, --synced-folders, --triggers)
  - `vf validate` - Validate YAML configuration files
  - `vf dump-config` - Export merged configuration (JSON/YAML, supports -f and -o options)
  - `vf generate` - Generate standalone Vagrantfile
  - `vf template list` - List available project templates
  - `vf template show` - Show template details and variables
  - `vf version` - Show radp-vagrant-framework version
  - `vf vg <cmd>` - Run vagrant commands (e.g., `vf vg up`, `vf vg status`)
- `setup install <name>` - Install a software package (-v version, --dry-run, --no-deps)
- `setup list` - List available packages (-c category, --installed, --categories)
- `setup info <name>` - Show package details (includes dependencies and conflicts)
- `setup deps <name>` - Show package dependency tree (--reverse for reverse deps)
- `setup profile list` - List available setup profiles
- `setup profile show <name>` - Show profile details
- `setup profile apply <name>` - Apply a profile (--dry-run, --continue, --skip-installed, --no-deps)
- `setup configure list` - List available system configurations
- `setup configure chrony` - Configure chrony time synchronization
- `setup configure expand-lvm` - Expand LVM partition and filesystem
- `setup configure gpg-import` - Import GPG keys into user keyring
- `setup configure gpg-preset` - Preset GPG passphrase in gpg-agent
- `setup configure yadm` - Clone dotfiles repository using yadm
- `version` - Show homelabctl version
- `completion <bash|zsh>` - Generate shell completion
- `--config` - Show homelabctl configuration (global option)
- `--config --json` - Show configuration in JSON format
- `--config --all` - Include extension configurations (vf settings, etc.)

## Architecture

### Directory Structure
```
homelabctl/
├── bin/
│   └── homelabctl              # CLI entry point
├── completions/
│   ├── homelabctl.bash         # Bash completion script
│   └── homelabctl.zsh          # Zsh completion script
├── src/main/shell/
│   ├── commands/               # Command implementations
│   │   ├── vf.sh               # homelabctl vf <cmd> (passthrough to radp-vf)
│   │   ├── setup/              # homelabctl setup <subcommand>
│   │   │   ├── install.sh
│   │   │   ├── list.sh
│   │   │   ├── info.sh
│   │   │   ├── deps.sh         # homelabctl setup deps <name>
│   │   │   ├── profile/        # homelabctl setup profile <subcommand>
│   │   │   │   ├── list.sh
│   │   │   │   ├── show.sh
│   │   │   │   └── apply.sh
│   │   │   └── configure/      # homelabctl setup configure <subcommand>
│   │   │       ├── list.sh     # Dynamic list from @desc annotations
│   │   │       ├── chrony.sh
│   │   │       ├── expand-lvm.sh
│   │   │       ├── gpg-import.sh
│   │   │       ├── gpg-preset.sh
│   │   │       └── yadm.sh
│   │   ├── version.sh
│   │   └── completion.sh
│   ├── config/
│   │   ├── _ide.sh             # IDE code completion support
│   │   └── config.yaml         # YAML configuration
│   └── libs/                   # Project-specific libraries
│       └── setup/              # Setup feature libraries
│           ├── _common.sh      # Shared helper functions
│           ├── registry.sh     # Registry management
│           ├── installer.sh    # Installer utilities
│           ├── registry.yaml   # Package registry
│           ├── profiles/       # Profile definitions
│           │   └── recommend.yaml
│           └── installers/     # Package installers (44 files)
│               ├── ansible.sh
│               ├── bat.sh
│               ├── docker.sh
│               ├── eza.sh
│               ├── fastfetch.sh
│               ├── fd.sh
│               ├── fzf.sh
│               ├── fzf-tab-completion.sh
│               ├── git-credential-manager.sh
│               ├── git.sh
│               ├── gitlab-runner.sh
│               ├── gnu-getopt.sh
│               ├── go.sh
│               ├── gpg.sh
│               ├── helm.sh
│               ├── homebrew.sh
│               ├── jdk.sh
│               ├── jq.sh
│               ├── kubecm.sh
│               ├── kubectl.sh
│               ├── lazygit.sh
│               ├── markdownlint-cli.sh
│               ├── mc.sh
│               ├── mvn.sh
│               ├── neovim.sh
│               ├── nodejs.sh
│               ├── ohmyzsh.sh
│               ├── pass.sh
│               ├── pinentry.sh
│               ├── python.sh
│               ├── ripgrep.sh
│               ├── ruby.sh
│               ├── rust.sh
│               ├── shellcheck.sh
│               ├── starship.sh
│               ├── terraform.sh
│               ├── tig.sh
│               ├── tmux.sh
│               ├── vagrant.sh
│               ├── vfox.sh
│               ├── vim.sh
│               ├── yadm.sh
│               ├── zoxide.sh
│               └── zsh.sh
├── packaging/
│   ├── copr/
│   │   └── homelabctl.spec     # RPM spec for COPR
│   ├── homebrew/
│   │   └── homelabctl.rb       # Homebrew formula template
│   └── obs/
│       ├── homelabctl.spec     # RPM spec for OBS
│       └── debian/             # Debian packaging files
├── install.sh                  # Universal installer script
└── .github/workflows/          # CI/CD workflows
```

### Version Management

Version is stored in `src/main/shell/commands/version.sh`:
```bash
declare -gr gr_app_version="v0.1.0"
```

Available as `$gr_app_version` in shell. This is the single source of truth for release management.

### Command Definition Pattern
Commands are defined using comment-based metadata:
```bash
# @cmd
# @desc Command description
# @arg name! Required argument
# @arg opts~ Variadic arguments
# @option -e, --env <name> Environment name
# @example vf init -d ~/lab

cmd_vf_init() {
    # Access options via opt_* variables
    local dir="${opt_dir:-.}"
    # Implementation...
}
```

### Naming Conventions
- Command files: `commands/<cmd>.sh` or `commands/<group>/<subcmd>.sh`
- Command functions: `cmd_<name>()` or `cmd_<group>_<subcmd>()`
- Options accessed via: `$opt_<long_name>` (dashes converted to underscores)

## CI/CD

### Release Process
1. Trigger `release-prep` workflow with bump_type (patch/minor/major/manual)
2. Review/merge the generated PR
3. `create-version-tag` auto-creates and pushes the tag
4. `update-spec-version` syncs spec files
5. `build-copr-package` and `build-obs-package` build the packages
6. `update-homebrew-tap` updates the Homebrew formula
7. `attach-release-packages` uploads built packages to GitHub Release

### Branch Cleanup
- `cleanup-branches` workflow automatically deletes stale `workflow/v*` branches
- Runs weekly (Sunday 00:00 UTC) or can be triggered manually
- Default: deletes branches older than 14 days
- Supports dry-run mode to preview deletions

### Required Secrets
- `COPR_LOGIN`, `COPR_TOKEN`, `COPR_USERNAME`, `COPR_PROJECT` - COPR access
- `OBS_USERNAME`, `OBS_PASSWORD`, `OBS_PROJECT`, `OBS_PACKAGE` - OBS access
- `HOMEBREW_TAP_TOKEN` - GitHub token for homebrew-radp repository

## Dependencies
- radp-bash-framework (required) - CLI framework
- radp-vagrant-framework (for vf commands) - set `RADP_VF_HOME` env var or install in PATH
- vagrant (for vf vg commands) - Vagrant CLI

## Environment Variables
- `RADP_VF_HOME` - Path to radp-vagrant-framework (required for vf commands)
- `RADP_VAGRANT_CONFIG_DIR` - Override config directory (default: ./config)
- `RADP_VAGRANT_ENV` - Override environment name

## Setup Feature

The setup command manages software installation across different platforms.

### Architecture

The setup install system is composed of four layers:

```
commands/setup/install.sh        Entry point (cmd_setup_install)
        |
libs/setup/registry.sh           Package metadata (name, desc, category, check-cmd)
libs/setup/registry.yaml          + user ~/.config/homelabctl/setup/registry.yaml
        |
libs/setup/installer.sh          Loader & runner (_setup_run_installer)
        |
libs/setup/installers/<name>.sh  Per-package install logic (_setup_install_<name>)
libs/setup/_common.sh            Shared helpers (arch/os detection, vfox PATH refresh)
```

**Key source files:**

| File | Role |
|------|------|
| `commands/setup/install.sh` | CLI entry: parse args, resolve dependencies, call `_setup_run_installer` |
| `libs/setup/registry.sh` | Load & query `registry.yaml` (builtin + user merge), dependency getters |
| `libs/setup/installer.sh` | `_setup_load_installer` (source `.sh`), `_setup_run_installer` (call function), `_setup_install_binary` (copy binary to `/usr/local/bin`) |
| `libs/setup/_common.sh` | `_setup_is_installed`, `_setup_get_arch`, `_setup_get_os`, `_setup_vfox_refresh_path`, `_setup_get_install_order` (dependency resolution) |
| `libs/setup/installers/*.sh` | Each file exports `_setup_install_<name>(version)` |

### Install Flow

```mermaid
flowchart TD
    A["homelabctl setup install &lt;name&gt; [-v version]"] --> B[_setup_registry_init]
    B --> B1[Load builtin registry.yaml]
    B1 --> B2[Merge user registry.yaml]
    B2 --> C{Package in registry?}
    C -- No --> C1[ERROR: Unknown package]
    C -- Yes --> D{Already installed<br/>& version=latest?}
    D -- Yes --> D1[INFO: already installed<br/>return 0]
    D -- No --> E[_setup_run_installer name version]

    E --> F[_setup_load_installer name]
    F --> F1{User installer<br/>~/.config/.../installers/name.sh?}
    F1 -- Yes --> F3[source user installer]
    F1 -- No --> F2{Builtin installer<br/>libs/setup/installers/name.sh?}
    F2 -- Yes --> F3B[source builtin installer]
    F2 -- No --> F4[ERROR: No installer found]

    F3 --> G[Call _setup_install_name version]
    F3B --> G

    G --> H{Detect platform<br/>radp_os_get_distro_pm}
    H -- brew --> I1[brew install]
    H -- dnf/yum --> I2[dnf install<br/>or binary release fallback]
    H -- apt --> I3[apt install<br/>or binary release fallback]
    H -- vfox available --> I4["vfox install sdk@ver<br/>vfox use --global<br/>_setup_vfox_refresh_path"]
    H -- other --> I5[Binary from GitHub release<br/>or official install script]

    I1 --> J{Success?}
    I2 --> J
    I3 --> J
    I4 --> J
    I5 --> J
    J -- Yes --> K[INFO: installed successfully]
    J -- No --> L[ERROR: Failed to install]
```

### Installer Design Patterns

Each installer (`libs/setup/installers/<name>.sh`) follows a consistent pattern:

```bash
_setup_install_<name>() {
  local version="${1:-latest}"

  # 1. Early return if already installed
  if _setup_is_installed <cmd> && [[ "$version" == "latest" ]]; then
    radp_log_info "<name> is already installed"
    return 0
  fi

  # 2. Detect platform
  local pm
  pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

  # 3. Platform-specific install strategy
  case "$pm" in
  brew)     ... ;;           # macOS: Homebrew
  dnf|yum)  ... ;;           # RHEL/CentOS: native PM, fallback to binary
  apt)      ... ;;           # Debian/Ubuntu: native PM, fallback to binary
  *)        ... ;;           # Fallback: GitHub release binary or official script
  esac
}
```

**Install strategy priority:**

1. **Version manager** (vfox) -- for language runtimes (nodejs, jdk, ruby, go, python). After vfox install, calls `_setup_vfox_refresh_path` to inject `~/.version-fox/sdks/*/bin` into current shell PATH via `eval "$(vfox env -s bash)"`, ensuring subsequent installers can find the tools (e.g., markdownlint-cli needs npm from nodejs).
2. **Native package manager** -- brew on macOS, dnf/apt on Linux
3. **Binary release fallback** -- download from GitHub Releases / official CDN
4. **Source build** -- last resort for tools without pre-built binaries (tig, tmux, pass, git, zsh)

**User extension:** Users can override any builtin installer by placing `<name>.sh` in `~/.config/homelabctl/setup/installers/`. User installers are loaded with higher priority than builtin ones.

### Usage Examples
```bash
# List available packages
homelabctl setup list
homelabctl setup list -c search
homelabctl setup list --installed

# Show package info
homelabctl setup info fzf

# Install packages
homelabctl setup install fzf
homelabctl setup install nodejs -v 20.10.0
homelabctl setup install jdk -v 17

# Profiles
homelabctl setup profile list
homelabctl setup profile show recommend
homelabctl setup profile apply recommend --dry-run
homelabctl setup profile apply recommend --continue
```

### User Extensions

Users can extend the setup feature by adding custom packages and profiles in `~/.config/homelabctl/setup/`:

```
~/.config/homelabctl/setup/
├── registry.yaml           # Custom package definitions
├── profiles/               # Custom profiles
│   └── my-profile.yaml
└── installers/             # Custom installers
    └── my-tool.sh
```

User files take precedence over builtin files.

### Registry YAML Schema

The `registry.yaml` file defines packages and categories. Complete field reference:

```yaml
# Package registry for homelabctl setup
packages:
  <package-name>:                    # Package identifier (alphanumeric, hyphens, underscores)
    # Required fields
    desc: <string>                   # Short description
    category: <category-name>        # Must match a category defined below

    # Optional fields
    check-cmd: <command>             # Command to check if installed (default: package name)
    homepage: <url>                  # Project homepage URL

    # Dependency fields (space-separated package names)
    requires: <pkg1> <pkg2>          # Required dependencies, auto-installed
    recommends: <pkg1> <pkg2>        # Recommended packages, shown as hint
    conflicts: <pkg1> <pkg2>         # Mutually exclusive packages, blocks install

    # Platform-specific dependencies (nested format)
    # Supported platform keys:
    #   - OS only: linux, darwin, freebsd (from `uname -s`, lowercased)
    #   - OS-arch: linux-amd64, linux-arm64, darwin-arm64, etc.
    # Lookup chain: os-arch → os → (none)
    #   - If os-arch exists, use it exclusively (no fallback to os)
    #   - If os-arch not found, fall back to os
    # Default behavior: platform values are APPENDED to base values
    # Override syntax: prefix with ! to REPLACE base values
    platform:
      linux:
        requires: <pkg>              # Linux (all arch): appended to base
        recommends: <pkg>
      linux-arm64:
        requires: <pkg>              # Linux ARM64 only: overrides linux key
      darwin:
        recommends: "!pkg"           # Override: replaces base recommends on macOS
        # "!" alone clears base, returns empty

categories:
  <category-name>:                   # Category identifier
    desc: <string>                   # Category description
```

**Platform Lookup Chain:**

The system uses a priority-based lookup: `os-arch` → `os` → (none). Only ONE platform value is selected, then merged with base.

| Current Platform | Lookup Order | Example |
|------------------|--------------|---------|
| linux-arm64 | `linux-arm64` → `linux` | If `linux-arm64` exists, use it; else fallback to `linux` |
| linux-amd64 | `linux-amd64` → `linux` | If `linux-amd64` not found, use `linux` |
| darwin-arm64 | `darwin-arm64` → `darwin` | Apple Silicon: check `darwin-arm64` first |

**Platform Dependency Merge Rules:**

| Platform Value | Behavior | Example |
|----------------|----------|---------|
| `pkg1 pkg2` | Appends to base | base `a b` + platform `c` = `a b c` |
| `!pkg1 pkg2` | Replaces base | base `a b` + platform `!c d` = `c d` |
| `!` | Clears (empty) | base `a b` + platform `!` = (empty) |

**Complete Example:**
```yaml
packages:
  git-credential-manager:
    desc: Cross-platform Git credential storage
    category: vcs
    requires: git
    platform:
      linux:
        recommends: pass gpg         # Linux AMD64: uses prebuilt binary
      linux-arm64:
        requires: dotnet-sdk         # Linux ARM64: needs dotnet tool
        recommends: pass gpg

  my-tool:
    desc: My custom development tool
    category: dev-tools
    check-cmd: mytool
    homepage: https://github.com/example/my-tool
    requires: git nodejs
    recommends: fzf bat
    conflicts: old-tool legacy-tool
    platform:
      linux:
        requires: libssl-dev         # Linux: git nodejs libssl-dev
        recommends: pass             # Linux: fzf bat pass
      darwin:
        recommends: "!"              # macOS: (no recommends, cleared)

categories:
  dev-tools:
    desc: Development and code quality tools
```

### Adding a Custom Package

1. Define the package in `~/.config/homelabctl/setup/registry.yaml`:
```yaml
packages:
  my-tool:
    desc: My custom tool
    category: utilities
    check-cmd: my-tool
    requires: git                    # Optional: dependencies
    homepage: https://example.com    # Optional: project URL
    platform:                        # Optional: platform-specific deps
      linux:
        requires: libsecret-tools
```

2. Create installer at `~/.config/homelabctl/setup/installers/my-tool.sh`:
```bash
#!/usr/bin/env bash
_setup_install_my_tool() {
    local version="${1:-latest}"
    # Installation logic here
}
```

### Profile YAML Schema

Profile files define a set of packages to install together:

```yaml
# Profile definition
name: <profile-name>                 # Profile identifier
desc: <string>                       # Profile description

# Platform constraint
# platform: any | linux | darwin | freebsd | ...
# - any: all platforms (default)
# - linux: Linux only
# - darwin: macOS only
# - other values from `uname -s` (lowercased)
platform: any

packages:
  - name: <package-name>             # Package from registry
    version: "<version>"             # Optional: specific version (default: latest)
  - name: <another-package>
```

**Example:**
```yaml
name: my-profile
desc: My custom development environment
platform: linux

packages:
  - name: git
  - name: fzf
  - name: nodejs
    version: "20"
  - name: jdk
    version: "17"
```

### Package Dependencies

**Dependency types:**

| Field | Behavior |
|-------|----------|
| `requires` | Auto-installed before target. Fails if dependency fails. |
| `recommends` | Hint displayed after install (if not installed). |
| `conflicts` | Blocks install if any conflicting package is installed. |

**Platform-specific dependencies:**

Use nested `platform` block for platform-specific dependencies. Supports both OS-only keys (`linux`, `darwin`) and OS-arch keys (`linux-arm64`, `darwin-amd64`):

```yaml
git-credential-manager:
  requires: git                      # All platforms
  platform:
    linux:
      recommends: pass gpg           # Linux AMD64: prebuilt binary available
    linux-arm64:
      requires: dotnet-sdk           # Linux ARM64: no prebuilt, use dotnet tool
      recommends: pass gpg
    # darwin omitted = macOS uses Homebrew + system keychain
```

**Lookup chain:** `os-arch` → `os` → (none). If `linux-arm64` key exists, it's used exclusively (doesn't inherit from `linux`).

Platform values are **appended** to base by default. Use `!` prefix to **override** (replace) base values.

**Built-in dependencies:**

| Package | requires | recommends | conflicts |
|---------|----------|------------|-----------|
| markdownlint-cli | nodejs | - | - |
| ohmyzsh | zsh | - | - |
| fzf-tab-completion | fzf | - | - |
| pass | gpg | - | - |
| git-credential-manager | git | pass gpg (Linux) | - |
| git-credential-manager (linux-arm64) | git dotnet-sdk | pass gpg | - |

**CLI usage:**
```bash
# Install with dependencies (default)
homelabctl setup install markdownlint-cli --dry-run
# Output: nodejs, markdownlint-cli

# Skip dependencies
homelabctl setup install markdownlint-cli --no-deps --dry-run
# Output: markdownlint-cli only

# View package info with dependencies
homelabctl setup info markdownlint-cli
# Shows: Requires, Recommends, Conflicts, Required by

# View dependency tree
homelabctl setup deps markdownlint-cli
# markdownlint-cli
# └── nodejs

# View reverse dependency tree (what depends on this)
homelabctl setup deps nodejs --reverse
# nodejs
# └── markdownlint-cli
```

## Configure Feature

The `setup configure` command group provides ready-to-use system configuration tasks.

### Available Configurations

| Command | Description |
|---------|-------------|
| `chrony` | Configure chrony for NTP time synchronization |
| `expand-lvm` | Expand LVM partition and filesystem to use all disk space |
| `gpg-import` | Import GPG keys from file, content, or keyserver |
| `gpg-preset` | Preset GPG passphrase in gpg-agent for non-interactive operations |
| `yadm` | Clone dotfiles repository using yadm |

### Architecture

Configure commands are auto-discovered from `commands/setup/configure/`:

```
commands/setup/configure/
├── list.sh          # Dynamic list (scans @desc from other files)
├── chrony.sh        # homelabctl setup configure chrony
├── expand-lvm.sh    # homelabctl setup configure expand-lvm
├── gpg-import.sh    # homelabctl setup configure gpg-import
├── gpg-preset.sh    # homelabctl setup configure gpg-preset
└── yadm.sh          # homelabctl setup configure yadm
```

### Command Pattern

All configure commands follow a consistent pattern using framework's dry-run support:

```bash
cmd_setup_configure_example() {
  # Set dry-run mode from flag
  radp_set_dry_run "${opt_dry_run:-}"

  # Use radp_exec for commands that need sudo
  radp_exec_sudo "Install package" apt-get install -y package

  # Use radp_dry_run_skip for complex operations
  if radp_dry_run_skip "Configure complex settings"; then
    return 0
  fi
  # ... actual implementation ...
}
```

### Usage Examples

```bash
# List available configurations
homelabctl setup configure list

# Configure time synchronization
homelabctl setup configure chrony --servers "ntp.aliyun.com" --timezone "Asia/Shanghai"
homelabctl setup configure chrony --dry-run

# Expand LVM (auto-detects configuration)
homelabctl setup configure expand-lvm
homelabctl setup configure expand-lvm --partition /dev/sda3 --vg ubuntu-vg --lv ubuntu-lv

# Import GPG keys
homelabctl setup configure gpg-import --secret-key-file ~/.secrets/key.asc --passphrase-file ~/.secrets/pass.txt
homelabctl setup configure gpg-import --key-id 0x1234567890ABCDEF --keyserver keys.openpgp.org

# Preset GPG passphrase for automation
homelabctl setup configure gpg-preset --key-uid "user@example.com" --passphrase-file ~/.secrets/pass.txt

# Clone dotfiles with yadm
homelabctl setup configure yadm --repo-url "git@github.com:user/dotfiles.git" --ssh-key-file ~/.ssh/id_rsa --bootstrap
```

### Notes

- All commands support `--dry-run` to preview changes
- Commands use `sudo` for privileged operations (no need to run as root)
- `--user` option allows configuring for another user (requires sudo)
