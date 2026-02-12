# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

homelabctl is a CLI tool for managing homelab infrastructure, built on radp-bash-framework. It provides software package installation (setup feature) and Vagrant VM management (vf passthrough to radp-vagrant-framework).

## Key Commands

```bash
# Running homelabctl
./bin/homelabctl --help
./bin/homelabctl setup list
./bin/homelabctl setup install fzf
./bin/homelabctl setup profile apply recommend
./bin/homelabctl vf vg up -C my-cluster
```

### Available Commands

| Command | Description |
|---------|-------------|
| `init all` | Initialize all user configurations |
| `init setup` | Initialize setup configuration |
| `init k8s` | Initialize k8s configuration |
| `init vf` | Initialize VF configuration (passthrough to radp-vf) |
| `vf <cmd>` | Passthrough to radp-vf |
| `setup install <name>` | Install a package |
| `setup list` | List available packages |
| `setup info <name>` | Show package details |
| `setup deps <name>` | Show dependency tree |
| `setup profile list/show/apply` | Manage profiles |
| `setup configure <name>` | Run system configuration |
| `upgrade` | Upgrade homelabctl to the latest version |
| `version` | Show version |
| `completion <bash\|zsh>` | Generate completion |

### Init Commands

```bash
homelabctl init all          # Initialize all configurations
homelabctl init all --force  # Force overwrite existing
homelabctl init vf           # Initialize VF config (uses config from config.yaml)
homelabctl init vf --force   # Force overwrite
```

## Architecture

### Directory Structure

```
homelabctl/
├── bin/homelabctl              # CLI entry point
├── completions/                # Shell completions
├── src/main/shell/
│   ├── commands/               # Command implementations
│   │   ├── vf.sh               # Passthrough to radp-vf
│   │   └── setup/              # Setup commands
│   │       ├── install.sh
│   │       ├── list.sh
│   │       ├── profile/
│   │       └── configure/
│   ├── config/config.yaml      # Framework config
│   └── libs/setup/             # Setup feature libraries
│       ├── _common.sh          # Shared helpers
│       ├── registry.sh         # Package registry
│       ├── installer.sh        # Installer loader
│       ├── registry.yaml       # Package definitions
│       ├── profiles/           # Profile definitions
│       └── installers/         # Per-package installers
└── packaging/                  # COPR, OBS, Homebrew specs
```

### Setup Feature Flow

```
commands/setup/install.sh    → Entry point
libs/setup/registry.sh       → Load registry.yaml (builtin + user)
libs/setup/installer.sh      → Load & run installer
libs/setup/installers/*.sh   → Per-package install logic
```

### Command Definition Pattern

```bash
# @cmd
# @desc Install a software package
# @arg name! Package name
# @option -v, --version <ver> Version to install
cmd_setup_install() {
    local name="${args_name}"
    local version="${opt_version:-latest}"
}
```

## Key Conventions

### Naming

- Command files: `commands/<cmd>.sh` or `commands/<group>/<subcmd>.sh`
- Command functions: `cmd_<name>()` or `cmd_<group>_<subcmd>()`
- Options: `$opt_<long_name>` (dashes → underscores)
- Installer functions: `_setup_install_<name>()`

### Installer Pattern

```bash
_setup_install_<name>() {
    local version="${1:-latest}"
    if _setup_is_installed <cmd> && [[ "$version" == "latest" ]]; then
        return 0
    fi
    local pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")
    case "$pm" in
        brew)    brew install <pkg> ;;
        dnf|yum) sudo dnf install -y <pkg> ;;
        apt)     sudo apt-get install -y <pkg> ;;
        *)       # Binary fallback ;;
    esac
}
```

### Version Management

Version in `src/main/shell/commands/version.sh`:
```bash
declare -gr gr_app_version="v0.1.0"
```

## Dependencies

- radp-bash-framework (required)
- radp-vagrant-framework (for vf commands)
- vagrant (for vf vg commands)

## Environment Variables

| Variable | Description |
|----------|-------------|
| `RADP_VF_HOME` | Path to radp-vagrant-framework |
| `RADP_VAGRANT_CONFIG_DIR` | Override config directory |
| `RADP_VAGRANT_ENV` | Override environment name |

## User Extensions

Users can extend in `~/.config/homelabctl/setup/`:

```
~/.config/homelabctl/setup/
├── registry.yaml       # Custom package definitions
├── profiles/           # Custom profiles
└── installers/         # Custom installers
```

## CI/CD Workflows

| Workflow | Purpose |
|----------|---------|
| `release-prep.yml` | Create release branch |
| `create-version-tag.yml` | Create version tag |
| `build-copr-package.yml` | COPR build |
| `build-obs-package.yml` | OBS build |
| `update-homebrew-tap.yml` | Update Homebrew |

## See Also

- [docs/developer/architecture.md](docs/developer/architecture.md) - Detailed architecture
- [docs/developer/adding-packages.md](docs/developer/adding-packages.md) - Add packages
- [docs/reference/cli-reference.md](docs/reference/cli-reference.md) - CLI reference
- [AGENTS.md](AGENTS.md) - Multi-agent guidelines
