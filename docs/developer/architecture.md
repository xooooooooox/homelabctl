# Architecture

This document describes the internal architecture of homelabctl.

## Overview

homelabctl is built on radp-bash-framework and provides:
- Software package installation (setup feature)
- Vagrant VM management (vf passthrough to radp-vagrant-framework)
- System configuration tasks

## Directory Structure

```
homelabctl/
├── bin/
│   └── homelabctl              # CLI entry point
├── completions/
│   ├── homelabctl.bash         # Bash completion
│   └── homelabctl.zsh          # Zsh completion
├── src/main/shell/
│   ├── commands/               # Command implementations
│   │   ├── vf.sh               # Passthrough to radp-vf
│   │   ├── setup/
│   │   │   ├── install.sh
│   │   │   ├── list.sh
│   │   │   ├── info.sh
│   │   │   ├── deps.sh
│   │   │   ├── profile/
│   │   │   │   ├── list.sh
│   │   │   │   ├── show.sh
│   │   │   │   └── apply.sh
│   │   │   └── configure/
│   │   │       ├── list.sh
│   │   │       ├── chrony.sh
│   │   │       ├── expand-lvm.sh
│   │   │       └── ...
│   │   ├── version.sh
│   │   └── completion.sh
│   ├── config/
│   │   └── config.yaml         # Framework config
│   └── libs/
│       └── setup/              # Setup feature libraries
│           ├── _common.sh      # Shared helpers
│           ├── registry.sh     # Package registry
│           ├── installer.sh    # Installer loader
│           ├── registry.yaml   # Package definitions
│           ├── profiles/       # Profile definitions
│           └── installers/     # Per-package installers
└── packaging/                  # Package specs (COPR, OBS, Homebrew)
```

## Command Definition Pattern

Commands use annotation-based metadata:

```bash
# @cmd
# @desc Command description
# @arg name! Required argument
# @option -v, --version <ver> Version to install
# @example setup install fzf

cmd_setup_install() {
    local name="${args_name}"
    local version="${opt_version:-latest}"
    # Implementation...
}
```

## Setup Feature Architecture

```
commands/setup/install.sh        Entry point
        |
libs/setup/registry.sh           Package metadata
libs/setup/registry.yaml          + user ~/.config/homelabctl/setup/registry.yaml
        |
libs/setup/installer.sh          Loader & runner
        |
libs/setup/installers/<name>.sh  Per-package install logic
libs/setup/_common.sh            Shared helpers
```

### Install Flow

1. Load registry (builtin + user merge)
2. Check if package exists
3. Resolve dependencies (requires field)
4. Load installer script
5. Call `_setup_install_<name>(version)`
6. Platform-specific installation (brew/dnf/apt/binary)

### Installer Pattern

```bash
_setup_install_<name>() {
    local version="${1:-latest}"

    # Skip if already installed
    if _setup_is_installed <cmd> && [[ "$version" == "latest" ]]; then
        radp_log_info "<name> is already installed"
        return 0
    fi

    # Detect platform
    local pm
    pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

    # Platform-specific install
    case "$pm" in
        brew)     brew install <package> ;;
        dnf|yum)  sudo dnf install -y <package> ;;
        apt)      sudo apt-get install -y <package> ;;
        *)        # Binary fallback
    esac
}
```

## Version Management

Version is stored in `src/main/shell/commands/version.sh`:

```bash
declare -gr gr_app_version="v0.1.0"
```

## VF Completion Integration

The `homelabctl vf` command delegates completion to `radp-vf`:

1. Read config from homelabctl's config file
2. Set `RADP_VAGRANT_CONFIG_DIR` and `RADP_VAGRANT_ENV`
3. Delegate to `_radp_vf` completion with `_RADP_VF_DELEGATED=1`

## Configuration

### Framework Config

```yaml
# src/main/shell/config/config.yaml
radp:
  app:
    name: homelabctl
```

### User Config

```yaml
# ~/.config/homelabctl/config.yaml
radp:
  extend:
    homelabctl:
      vf:
        config_dir: $HOME/.config/homelabctl/vagrant
        env: homelab
```

## See Also

- [Adding Packages](adding-packages.md) - How to add new packages
- [CLI Reference](../reference/cli-reference.md) - Command reference
