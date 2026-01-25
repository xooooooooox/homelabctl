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
./bin/homelabctl vf info
./bin/homelabctl vg up
```

### Available Commands
- `vg <cmd>` - Vagrant command passthrough (sets VAGRANT_VAGRANTFILE automatically)
- `vf init` - Initialize a vagrant project (supports -t/--template, --set options)
- `vf info` - Show environment information (versions, paths, plugins)
- `vf list` - List clusters and guests (supports -v, --provisions, --synced-folders, --triggers)
- `vf validate` - Validate YAML configuration files
- `vf dump-config` - Export merged configuration (JSON/YAML, supports -f and -o options)
- `vf generate` - Generate standalone Vagrantfile
- `vf template list` - List available project templates
- `vf template show` - Show template details and variables
- `vf version` - Show radp-vagrant-framework version
- `version` - Show homelabctl version
- `completion <bash|zsh>` - Generate shell completion

## Architecture

### Directory Structure
```
homelabctl/
├── bin/
│   └── homelabctl              # CLI entry point
├── src/main/shell/
│   ├── commands/               # Command implementations
│   │   ├── vg.sh               # homelabctl vg <cmd>
│   │   ├── vf/                 # homelabctl vf <subcommand>
│   │   │   ├── init.sh
│   │   │   ├── info.sh
│   │   │   ├── list.sh
│   │   │   ├── validate.sh
│   │   │   ├── dump-config.sh
│   │   │   ├── generate.sh
│   │   │   ├── template/       # homelabctl vf template <subcommand>
│   │   │   │   ├── list.sh
│   │   │   │   └── show.sh
│   │   │   └── version.sh
│   │   ├── version.sh
│   │   └── completion.sh
│   ├── config/
│   │   └── config.yaml         # YAML configuration
│   ├── vars/
│   │   └── constants.sh        # Version constants (gr_homelabctl_version)
│   └── libs/                   # Project-specific libraries
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

Version is stored in `src/main/shell/vars/constants.sh`:
```bash
declare -gr gr_homelabctl_version=v0.1.0
```

This is the single source of truth for release management.

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

### Required Secrets
- `COPR_LOGIN`, `COPR_TOKEN`, `COPR_USERNAME`, `COPR_PROJECT` - COPR access
- `OBS_USERNAME`, `OBS_PASSWORD`, `OBS_PROJECT`, `OBS_PACKAGE` - OBS access
- `HOMEBREW_TAP_TOKEN` - GitHub token for homebrew-radp repository

## Dependencies
- radp-bash-framework (required) - CLI framework
- radp-vagrant-framework (for vf commands) - set `RADP_VF_HOME` env var
- vagrant (for vg commands) - Vagrant CLI

## Environment Variables
- `RADP_VF_HOME` - Path to radp-vagrant-framework (required for vf commands)
- `RADP_VAGRANT_CONFIG_DIR` - Override config directory (default: ./config)
- `RADP_VAGRANT_ENV` - Override environment name
