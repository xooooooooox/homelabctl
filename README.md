# homelabctl

```
    __                         __      __         __  __
   / /_  ____  ____ ___  ___  / /___ _/ /_  _____/ /_/ /
  / __ \/ __ \/ __ `__ \/ _ \/ / __ `/ __ \/ ___/ __/ /
 / / / / /_/ / / / / / /  __/ / /_/ / /_/ / /__/ /_/ /
/_/ /_/\____/_/ /_/ /_/\___/_/\__,_/_.___/\___/\__/_/


```

A CLI tool for managing homelab infrastructure, built
on [radp-bash-framework](https://github.com/xooooooooox/radp-bash-framework).

## Features

- **Vagrant Integration** - Passthrough to Vagrant commands with automatic Vagrantfile detection
- **RADP Vagrant Framework** - Initialize, configure, and manage multi-VM environments
- **Template System** - Create projects from predefined templates (`k8s-cluster`, `single-node`, etc.)
- **Shell Completion** - Bash and Zsh completion support
- **Verbose/Debug Modes** - Configurable output levels for troubleshooting

## Prerequisites

homelabctl requires radp-bash-framework to be installed:

```shell
brew tap xooooooooox/radp
brew install radp-bash-framework
```

Or see: https://github.com/xooooooooox/radp-bash-framework#installation

## Installation

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

See [Installation Guide](docs/installation.md) for more options (OBS, manual install, upgrade).

## Usage

```shell
# Show help
homelabctl --help

# Vagrant passthrough
homelabctl vg up
homelabctl vg ssh
homelabctl vg status

# Vagrant framework commands
homelabctl vf init myproject
homelabctl vf init myproject --template k8s-cluster
homelabctl vf list
homelabctl vf info
homelabctl vf dump-config

# Shell completion
homelabctl completion bash > ~/.local/share/bash-completion/completions/homelabctl
homelabctl completion zsh > ~/.zfunc/_homelabctl

# Verbose/Debug modes
homelabctl -v vf info      # Verbose output
homelabctl --debug vg up   # Debug output
```

## Commands

| Command | Description |
|---------|-------------|
| `vg <cmd>` | Vagrant command passthrough |
| `vf init [dir]` | Initialize a vagrant project |
| `vf list` | List clusters and guests |
| `vf info` | Show environment information |
| `vf validate` | Validate YAML configuration |
| `vf dump-config` | Export merged configuration |
| `vf generate` | Generate standalone Vagrantfile |
| `vf template list` | List available templates |
| `vf template show` | Show template details |
| `version` | Show homelabctl version |
| `completion <shell>` | Generate shell completion |

## Global Options

| Option | Description |
|--------|-------------|
| `-v`, `--verbose` | Enable verbose output (banner + info logs) |
| `--debug` | Enable debug output (banner + debug logs) |

By default, homelabctl runs in quiet mode (no banner, only error logs).

## Environment Variables

| Variable | Description |
|----------|-------------|
| `RADP_VF_HOME` | Path to radp-vagrant-framework installation |
| `RADP_VAGRANT_CONFIG_DIR` | Configuration directory path (default: `./config`) |
| `RADP_VAGRANT_ENV` | Override environment name |

## Documentation

- [Installation Guide](docs/installation.md) - Full installation options, upgrade, shell completion
- [Configuration](docs/configuration.md) - YAML configuration system

For vagrant VM configuration, see [radp-vagrant-framework Configuration Reference](https://github.com/xooooooooox/radp-vagrant-framework/blob/main/docs/configuration-reference.md).

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup, testing, and release process.

## License

[MIT](LICENSE)
