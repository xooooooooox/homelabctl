# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

homelabctl is a CLI tool for managing homelab infrastructure, built on top of radp-bash-framework. It provides a unified interface for orchestrating various homelab components, starting with radp-vagrant-framework integration.

## Commands

### Running homelabctl
```bash
# Ensure radp-bash-framework is in PATH
export PATH="/path/to/radp-bash-framework/src/main/shell/bin:$PATH"

./bin/homelabctl --help
./bin/homelabctl vf info
./bin/homelabctl vg up
```

### Available Commands
- `vg <cmd>` - Vagrant command passthrough
- `vf init` - Initialize a vagrant project
- `vf info` - Show environment information
- `vf dump-config` - Export merged configuration
- `vf generate` - Generate standalone Vagrantfile
- `version` - Show version
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
│   │   │   ├── dump-config.sh
│   │   │   └── generate.sh
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
│   └── obs/
│       ├── homelabctl.spec     # RPM spec for OBS
│       └── debian/             # Debian packaging files
├── tools/
│   └── install.sh              # Universal installer script
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
- radp-bash-framework (required)
- radp-vagrant-framework (for vf commands)
- vagrant (for vg commands)
