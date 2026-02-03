# Getting Started

This guide helps you get started with homelabctl.

## Installation

```shell
# Homebrew (macOS)
brew tap xooooooooox/radp
brew install homelabctl

# Quick install (any platform)
curl -fsSL https://raw.githubusercontent.com/xooooooooox/homelabctl/main/install.sh | bash
```

See [Installation Guide](installation.md) for more options.

## Basic Usage

### Show Help

```shell
homelabctl --help
homelabctl setup --help
homelabctl vf --help
```

### Install Software Packages

```shell
# List available packages
homelabctl setup list

# Show package info
homelabctl setup info fzf

# Install a package
homelabctl setup install fzf

# Install with specific version
homelabctl setup install nodejs -v 20
```

### Apply a Profile

Profiles let you install multiple packages at once:

```shell
# List available profiles
homelabctl setup profile list

# Preview what will be installed
homelabctl setup profile apply recommend --dry-run

# Apply the profile
homelabctl setup profile apply recommend
```

### System Configuration

```shell
# List available configurations
homelabctl setup configure list

# Configure time synchronization
homelabctl setup configure chrony --timezone "Asia/Shanghai"

# Clone dotfiles with yadm
homelabctl setup configure yadm --repo-url "git@github.com:user/dotfiles.git"
```

## Vagrant Integration

Requires [radp-vagrant-framework](https://github.com/xooooooooox/radp-vagrant-framework).

### Initialize a Project

```shell
# Default template
homelabctl vf init myproject

# With specific template
homelabctl vf init myproject --template k8s-cluster
```

### Manage VMs

```shell
# Check status
homelabctl vf vg status

# Start VMs by cluster
homelabctl vf vg up -C my-cluster

# SSH into a VM
homelabctl vf vg ssh dev-my-cluster-node-1

# Stop VMs
homelabctl vf vg halt -C my-cluster
```

## Configuration

homelabctl uses YAML configuration:

```yaml
# ~/.config/homelabctl/config.yaml
radp:
  extend:
    homelabctl:
      vf:
        config_dir: $HOME/.config/homelabctl/vagrant
        env: homelab
```

Show current configuration:

```shell
homelabctl --config
homelabctl --config --all  # Include extension configs
```

## Shell Completion

Enable shell completion for better experience:

```shell
# Bash
homelabctl completion bash > ~/.local/share/bash-completion/completions/homelabctl

# Zsh
homelabctl completion zsh > ~/.zfunc/_homelabctl
```

## Next Steps

- [Setup Guide](user-guide/setup-guide.md) - Deep dive into package installation
- [Vagrant Guide](user-guide/vagrant-guide.md) - VM management details
- [CLI Reference](reference/cli-reference.md) - Complete command reference
