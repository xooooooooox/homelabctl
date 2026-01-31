# homelabctl

```
    __                         __      __         __  __
   / /_  ____  ____ ___  ___  / /___ _/ /_  _____/ /_/ /
  / __ \/ __ \/ __ `__ \/ _ \/ / __ `/ __ \/ ___/ __/ /
 / / / / /_/ / / / / / /  __/ / /_/ / /_/ / /__/ /_/ /
/_/ /_/\____/_/ /_/ /_/\___/_/\__,_/_.___/\___/\__/_/


```

[![GitHub Release](https://img.shields.io/github/v/release/xooooooooox/homelabctl?label=Release)](https://github.com/xooooooooox/homelabctl/releases)
[![Copr build status](https://copr.fedorainfracloud.org/coprs/xooooooooox/radp/package/homelabctl/status_image/last_build.png)](https://copr.fedorainfracloud.org/coprs/xooooooooox/radp/package/radp-bash-framework/)
[![OBS package build status](https://build.opensuse.org/projects/home:xooooooooox:radp/packages/homelabctl/badge.svg)](https://build.opensuse.org/package/show/home:xooooooooox:radp/radp-bash-framework)
[![CI: COPR](https://img.shields.io/github/actions/workflow/status/xooooooooox/homelabctl/build-copr-package.yml?label=CI%3A%20COPR)](https://github.com/xooooooooox/radp-bash-framework/actions/workflows/build-copr-package.yml)
[![CI: OBS](https://img.shields.io/github/actions/workflow/status/xooooooooox/homelabctl/build-obs-package.yml?label=CI%3A%20OBS)](https://github.com/xooooooooox/radp-bash-framework/actions/workflows/build-obs-package.yml)
[![CI: Homebrew](https://img.shields.io/github/actions/workflow/status/xooooooooox/homelabctl/update-homebrew-tap.yml?label=Homebrew%20tap)](https://github.com/xooooooooox/radp-bash-framework/actions/workflows/update-homebrew-tap.yml)

[![COPR packages](https://img.shields.io/badge/COPR-packages-4b8bbe)](https://download.copr.fedorainfracloud.org/results/xooooooooox/radp/)
[![OBS packages](https://img.shields.io/badge/OBS-packages-4b8bbe)](https://software.opensuse.org//download.html?project=home%3Axooooooooox%3Aradp&package=radp-bash-framework)

A CLI tool for managing homelab infrastructure, built
on [radp-bash-framework](https://github.com/xooooooooox/radp-bash-framework).

## Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [Supported Platforms](#supported-platforms)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Commands](#commands)
- [Global Options](#global-options)
- [Shell Completion](#shell-completion)
- [Documentation](#documentation)
- [Contributing](#contributing)

## Features

- **Vagrant Integration** - Passthrough to Vagrant commands with automatic Vagrantfile detection
- **RADP Vagrant Framework** - Initialize, configure, and manage multi-VM environments
- **Software Setup** - Install 40+ CLI tools, languages, and DevOps tools across platforms
- **Profiles** - Batch install packages via profiles for reproducible environments
- **Shell Completion** - Bash and Zsh completion with dynamic suggestions

## Requirements

- **Bash** 4.0+ (macOS users: `brew install bash`)
- **Git** (for manual installation)
- **radp-bash-framework** (auto-installed by install script)

## Supported Platforms

| OS                 | Architecture          | Package Manager | Notes                         |
|--------------------|-----------------------|-----------------|-------------------------------|
| macOS              | Intel (x86_64)        | Homebrew        | Requires `bash` from Homebrew |
| macOS              | Apple Silicon (arm64) | Homebrew        | Requires `bash` from Homebrew |
| Fedora/RHEL/CentOS | x86_64, aarch64       | DNF/YUM (COPR)  | RHEL 8+, Fedora 38+           |
| Ubuntu/Debian      | amd64, arm64          | APT (OBS)       | Ubuntu 20.04+, Debian 11+     |
| openSUSE           | x86_64                | Zypper (OBS)    | Tumbleweed, Leap 15.4+        |

## Installation

### Quick Install

```shell
curl -fsSL https://raw.githubusercontent.com/xooooooooox/homelabctl/main/install.sh | bash
```

### Homebrew (macOS)

```shell
brew tap xooooooooox/radp
brew install homelabctl
```

### RPM (Fedora/RHEL/CentOS)

```shell
sudo dnf copr enable -y xooooooooox/radp
sudo dnf install -y radp-bash-framework homelabctl
```

See [Installation Guide](docs/installation.md) for more options including Debian/Ubuntu, manual installation, and
upgrading.

## Quick Start

```shell
# Show help
homelabctl --help

# Install development tools
homelabctl setup install fzf
homelabctl setup install nodejs -v 20
homelabctl setup profile apply recommend

# Manage Vagrant VMs (requires radp-vagrant-framework)
homelabctl vf init myproject --template k8s-cluster
homelabctl vg up
```

## Commands

### Vagrant Integration (vg, vf)

| Command                 | Description                     |
|-------------------------|---------------------------------|
| `vg <cmd>`              | Vagrant command passthrough     |
| `vf init [dir]`         | Initialize a vagrant project    |
| `vf list`               | List clusters and guests        |
| `vf info`               | Show environment information    |
| `vf validate`           | Validate YAML configuration     |
| `vf dump-config`        | Export merged configuration     |
| `vf generate`           | Generate standalone Vagrantfile |
| `vf template list/show` | List or show templates          |
| `vf version`            | Show framework version          |

Requires [radp-vagrant-framework](https://github.com/xooooooooox/radp-vagrant-framework). See [Vagrant Guide](docs/vagrant-guide.md) for details.

### Software Setup (setup)

| Command                      | Description                |
|------------------------------|----------------------------|
| `setup list`                 | List available packages    |
| `setup info <name>`          | Show package details       |
| `setup deps <name>`          | Show dependency tree       |
| `setup install <name>`       | Install a package          |
| `setup profile list`         | List available profiles    |
| `setup profile show <name>`  | Show profile details       |
| `setup profile apply <name>` | Apply a profile            |
| `setup configure list`       | List system configurations |
| `setup configure <name>`     | Run a configuration task   |

**Available categories:** system, shell, editors, languages, devops, vcs, security, search, dev-tools, utilities

**System configurations:** chrony, expand-lvm, gpg-import, gpg-preset, yadm

See [Setup Guide](docs/setup-guide.md) for architecture details, full package list, and custom extensions.

## Global Options

| Option            | Description                                |
|-------------------|--------------------------------------------|
| `-v`, `--verbose` | Enable verbose output (banner + info logs) |
| `--debug`         | Enable debug output (banner + debug logs)  |
| `-h`, `--help`    | Show help                                  |
| `--version`       | Show version                               |

By default, homelabctl runs in quiet mode (no banner, only error logs).

## Shell Completion

Shell completion is automatically configured during installation. To regenerate manually:

```shell
# Bash
mkdir -p ~/.local/share/bash-completion/completions
homelabctl completion bash >~/.local/share/bash-completion/completions/homelabctl

# Zsh
mkdir -p ~/.zfunc
homelabctl completion zsh >~/.zfunc/_homelabctl
```

## Documentation

- [Installation Guide](docs/installation.md) - Full installation options, upgrade, uninstall
- [Setup Guide](docs/setup-guide.md) - Package installation, profiles, custom extensions
- [Vagrant Guide](docs/vagrant-guide.md) - VM management, templates, configuration
- [Configuration](docs/configuration.md) - YAML configuration system

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup, adding packages, and release process.

## License

[MIT](LICENSE)
