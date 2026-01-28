# homelabctl

```
    __                         __      __         __  __
   / /_  ____  ____ ___  ___  / /___ _/ /_  _____/ /_/ /
  / __ \/ __ \/ __ `__ \/ _ \/ / __ `/ __ \/ ___/ __/ /
 / / / / /_/ / / / / / /  __/ / /_/ / /_/ / /__/ /_/ /
/_/ /_/\____/_/ /_/ /_/\___/_/\__,_/_.___/\___/\__/_/


```

[![Copr build status](https://copr.fedorainfracloud.org/coprs/xooooooooox/radp/package/homelabctl/status_image/last_build.png)](https://copr.fedorainfracloud.org/coprs/xooooooooox/radp/package/radp-bash-framework/)
[![OBS package build status](https://build.opensuse.org/projects/home:xooooooooox:radp/packages/homelabctl/badge.svg)](https://build.opensuse.org/package/show/home:xooooooooox:radp/radp-bash-framework)
[![CI: COPR](https://img.shields.io/github/actions/workflow/status/xooooooooox/homelabctl/build-copr-package.yml?label=CI%3A%20COPR)](https://github.com/xooooooooox/radp-bash-framework/actions/workflows/build-copr-package.yml)
[![CI: OBS](https://img.shields.io/github/actions/workflow/status/xooooooooox/homelabctl/build-obs-package.yml?label=CI%3A%20OBS)](https://github.com/xooooooooox/radp-bash-framework/actions/workflows/build-obs-package.yml)
[![CI: Homebrew](https://img.shields.io/github/actions/workflow/status/xooooooooox/homelabctl/update-homebrew-tap.yml?label=Homebrew%20tap)](https://github.com/xooooooooox/radp-bash-framework/actions/workflows/update-homebrew-tap.yml)

[![COPR packages](https://img.shields.io/badge/COPR-packages-4b8bbe)](https://download.copr.fedorainfracloud.org/results/xooooooooox/radp/)
[![OBS packages](https://img.shields.io/badge/OBS-packages-4b8bbe)](https://software.opensuse.org//download.html?project=home%3Axooooooooox%3Aradp&package=radp-bash-framework)

A CLI tool for managing homelab infrastructure, built
on [radp-bash-framework](https://github.com/xooooooooox/radp-bash-framework).

## Features

- **Vagrant Integration** - Passthrough to Vagrant commands with automatic Vagrantfile detection
- **RADP Vagrant Framework** - Initialize, configure, and manage multi-VM environments
- **Software Setup** - Install CLI tools, languages, and DevOps tools across platforms with profiles
- **Shell Completion** - Bash and Zsh completion with dynamic package/profile suggestions

## Installation

### Prerequisites

homelabctl requires radp-bash-framework:

```shell
brew tap xooooooooox/radp
brew install radp-bash-framework
```

### Homebrew (Recommended)

```shell
brew tap xooooooooox/radp
brew install homelabctl
```

### Script (curl)

```shell
curl -fsSL https://raw.githubusercontent.com/xooooooooox/homelabctl/main/install.sh | bash
```

### RPM (Fedora/RHEL/CentOS)

```shell
sudo dnf copr enable -y xooooooooox/radp
sudo dnf install -y homelabctl
```

See [Installation Guide](docs/installation.md) for more options.

## Quick Start

```shell
# Show help
homelabctl --help

# Install development tools
homelabctl setup install fzf
homelabctl setup profile apply osx-dev

# Manage Vagrant VMs
homelabctl vf init myproject --template k8s-cluster
homelabctl vg up
```

## Commands

### Vagrant Integration (vg, vf)

Manage Vagrant virtual machines with automatic Vagrantfile detection and multi-VM configuration.

| Command            | Description                     |
|--------------------|---------------------------------|
| `vg <cmd>`         | Vagrant command passthrough     |
| `vf init [dir]`    | Initialize a vagrant project    |
| `vf list`          | List clusters and guests        |
| `vf info`          | Show environment information    |
| `vf validate`      | Validate YAML configuration     |
| `vf dump-config`   | Export merged configuration     |
| `vf generate`      | Generate standalone Vagrantfile |
| `vf template list` | List available templates        |
| `vf template show` | Show template details           |
| `vf version`       | Show framework version          |

**Examples:**

```shell
# Vagrant passthrough
homelabctl vg up
homelabctl vg ssh
homelabctl vg status

# Initialize project from template
homelabctl vf init myproject
homelabctl vf init myproject --template k8s-cluster

# View configuration
homelabctl vf list
homelabctl vf info
homelabctl vf dump-config -f yaml
```

**Environment Variables:**

| Variable                  | Description                                        |
|---------------------------|----------------------------------------------------|
| `RADP_VF_HOME`            | Path to radp-vagrant-framework installation        |
| `RADP_VAGRANT_CONFIG_DIR` | Configuration directory path (default: `./config`) |
| `RADP_VAGRANT_ENV`        | Override environment name                          |

For VM configuration details,
see [radp-vagrant-framework Configuration Reference](https://github.com/xooooooooox/radp-vagrant-framework/blob/main/docs/configuration-reference.md).

### Software Setup (setup)

Install and manage software packages across different platforms. Supports individual package installation and batch
installation via profiles.

| Command                      | Description             |
|------------------------------|-------------------------|
| `setup list`                 | List available packages |
| `setup info <name>`          | Show package details    |
| `setup install <name>`       | Install a package       |
| `setup profile list`         | List available profiles |
| `setup profile show <name>`  | Show profile details    |
| `setup profile apply <name>` | Apply a profile         |

**Examples:**

```shell
# List and search packages
homelabctl setup list
homelabctl setup list -c cli-tools
homelabctl setup list --installed

# Install packages
homelabctl setup install fzf
homelabctl setup install nodejs -v 20
homelabctl setup install jdk -v 17

# Work with profiles
homelabctl setup profile list
homelabctl setup profile show osx-dev
homelabctl setup profile apply osx-dev --dry-run
homelabctl setup profile apply linux-dev --continue
```

**How It Works:**

```mermaid
flowchart TD
    A["homelabctl setup install &lt;name&gt;"] --> B["Registry Lookup<br/>(builtin + user registry.yaml)"]
    B --> C["Load Installer<br/>(user ~/.config/.../ or builtin installers/name.sh)"]
    C --> D["Detect Platform<br/>(brew / dnf / apt / ...)"]
    D --> E1["macOS: Homebrew"]
    D --> E2["Linux: native PM<br/>+ binary release fallback"]
    D --> E3["Language runtimes:<br/>vfox + PATH refresh"]
```

The install system uses a layered architecture: a **registry** (`registry.yaml`) defines available packages and metadata, an **installer loader** (`installer.sh`) dynamically sources per-package scripts, and each **installer** (`installers/<name>.sh`) implements platform-specific install strategies. Users can extend both the registry and installers via `~/.config/homelabctl/setup/`.

For language runtimes (nodejs, jdk, ruby, go, python), [vfox](https://github.com/version-fox/vfox) is preferred when available. After a vfox-based install, the current shell PATH is refreshed via `vfox env` so that dependent tools (e.g., markdownlint-cli needs npm) can be installed in the same session.

**Available Categories:**

- **system** - System prerequisites and package managers (homebrew, gnu-getopt)
- **cli-tools** - Command line utilities (fzf, bat, fd, jq, ripgrep, eza, zoxide, mc, fastfetch, lazygit, tig, gpg, pinentry, pass, shellcheck, git, git-credential-manager, markdownlint-cli, yadm)
- **editors** - Text editors (neovim, vim)
- **languages** - Programming languages (nodejs, jdk, python, go, rust, ruby, vfox, mvn)
- **devops** - DevOps tools (kubectl, helm, kubecm, vagrant, docker, terraform, ansible)
- **shell** - Shell utilities (zsh, ohmyzsh, tmux, starship, zoxide)

**Built-in Profiles:**

| Profile     | Description                     |
|-------------|---------------------------------|
| `osx-dev`   | macOS development environment   |
| `linux-dev` | Linux development environment   |
| `devops`    | DevOps and infrastructure tools |

**User Extensions:**

Add custom packages and profiles in `~/.config/homelabctl/setup/`:

```
~/.config/homelabctl/setup/
├── registry.yaml      # Custom package definitions
├── profiles/          # Custom profiles
└── installers/        # Custom installers
```

## Global Options

| Option            | Description                                |
|-------------------|--------------------------------------------|
| `-v`, `--verbose` | Enable verbose output (banner + info logs) |
| `--debug`         | Enable debug output (banner + debug logs)  |
| `-h`, `--help`    | Show help                                  |
| `--version`       | Show version                               |

By default, homelabctl runs in quiet mode (no banner, only error logs).

## Shell Completion

```shell
# Bash
homelabctl completion bash >~/.local/share/bash-completion/completions/homelabctl

# Zsh
homelabctl completion zsh >~/.zfunc/_homelabctl
```

Completions include dynamic suggestions for package names, profile names, and categories.

## Documentation

- [Installation Guide](docs/installation.md) - Full installation options, upgrade, shell completion
- [Configuration](docs/configuration.md) - YAML configuration system

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup, testing, and release process.

## License

[MIT](LICENSE)
