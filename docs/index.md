# homelabctl Documentation

Welcome to the homelabctl documentation. homelabctl is a CLI tool for managing homelab infrastructure, built on radp-bash-framework.

## Quick Links

- [Getting Started](getting-started.md) - Quick start guide
- [Installation](installation.md) - Full installation options

## User Guide

- [Setup Guide](user-guide/setup-guide.md) - Package installation and profiles
- [Vagrant Guide](user-guide/vagrant-guide.md) - VM management with radp-vagrant-framework
- [Profiles](user-guide/profiles.md) - Using setup profiles

## Reference

- [CLI Reference](reference/cli-reference.md) - Complete command reference
- [Package List](reference/package-list.md) - Available packages
- [Configuration](configuration.md) - YAML configuration system

## Developer Guide

- [Architecture](developer/architecture.md) - Internal architecture
- [Adding Packages](developer/adding-packages.md) - How to add new packages

## Features

### Software Setup

Install 50+ CLI tools, languages, and DevOps tools across platforms:

```shell
homelabctl setup install fzf
homelabctl setup install nodejs -v 20
homelabctl setup profile apply recommend
```

### Vagrant Integration

Manage multi-VM environments with radp-vagrant-framework:

```shell
homelabctl vf init myproject --template k8s-cluster
homelabctl vf vg up -C my-cluster
```

## Related Projects

- [radp-bash-framework](https://github.com/xooooooooox/radp-bash-framework) - Bash CLI framework (dependency)
- [radp-vagrant-framework](https://github.com/xooooooooox/radp-vagrant-framework) - YAML-driven Vagrant framework
