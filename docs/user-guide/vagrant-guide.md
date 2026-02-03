# Vagrant Guide

homelabctl provides a unified interface for managing Vagrant virtual machines through integration
with [radp-vagrant-framework](https://github.com/xooooooooox/radp-vagrant-framework).

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Commands](#commands)
- [Project Templates](#project-templates)
- [Configuration](#configuration)
- [Environment Variables](#environment-variables)
- [Examples](#examples)
- [Troubleshooting](#troubleshooting)

## Prerequisites

1. **Vagrant** - Install from [vagrantup.com](https://www.vagrantup.com/)
2. **VirtualBox** or other Vagrant provider
3. **radp-vagrant-framework** - Install using one of these methods:

### Homebrew (Recommended)

```shell
brew tap xooooooooox/radp
brew install radp-vagrant-framework
```

### Script Installation

```shell
curl -fsSL https://raw.githubusercontent.com/xooooooooox/radp-vagrant-framework/main/install.sh | bash
```

### Manual Installation

```shell
git clone https://github.com/xooooooooox/radp-vagrant-framework.git
export PATH="$PWD/radp-vagrant-framework/bin:$PATH"

# Add to shell config for persistence
echo 'export PATH="/path/to/radp-vagrant-framework/bin:$PATH"' >>~/.bashrc
```

After installation, verify `radp-vf` is available:

```shell
radp-vf version
```

## Quick Start

```shell
# Initialize a new project
homelabctl vf init myproject
cd myproject

# Or use a template
homelabctl vf init myproject -t single-node

# Start VMs
homelabctl vf vg up

# Check status
homelabctl vf vg status

# SSH into a VM
homelabctl vf vg ssh

# Stop VMs
homelabctl vf vg halt

# Destroy VMs
homelabctl vf vg destroy

# Target VMs by cluster (instead of full machine name)
homelabctl vf vg up -C my-cluster
homelabctl vf vg up -C my-cluster -G 1,2
```

## Commands

### Vagrant Passthrough (vf vg)

The `vf vg` command passes arguments to `radp-vf vg`, which handles Vagrant integration.

```shell
homelabctl vf vg <vagrant-command >[options]
```

| Command            | Description             |
|--------------------|-------------------------|
| `vf vg up`         | Start and provision VMs |
| `vf vg halt`       | Stop VMs                |
| `vf vg destroy`    | Remove VMs              |
| `vf vg status`     | Show VM status          |
| `vf vg ssh [name]` | SSH into a VM           |
| `vf vg provision`  | Re-run provisioners     |
| `vf vg reload`     | Restart VMs             |
| `vf vg snapshot`   | Manage snapshots        |

The framework automatically sets `VAGRANT_VAGRANTFILE` and manages the Vagrant environment.

#### Targeting VMs by Cluster

Instead of typing full machine names like `homelab-gitlab-runner-1`, you can target VMs by cluster name:

```shell
# Start all VMs in a cluster
homelabctl vf vg up -C my-cluster
homelabctl vf vg up --cluster=my-cluster

# Start specific guests in a cluster (comma-separated)
homelabctl vf vg up -C my-cluster -G 1,2
homelabctl vf vg up --cluster=my-cluster --guest-ids=1,2

# Multiple clusters (comma-separated)
homelabctl vf vg up -C gitlab-runner,develop-centos9

# Original machine name syntax still works
homelabctl vf vg up homelab-gitlab-runner-1
```

**Options:**

| Option              | Short | Description                                       |
|---------------------|-------|---------------------------------------------------|
| `--cluster <names>` | `-C`  | Cluster names (comma-separated for multiple)      |
| `--guest-ids <ids>` | `-G`  | Guest IDs (comma-separated, requires `--cluster`) |

Shell completion is supported for cluster names, guest IDs, and machine names.

### Framework Commands (vf)

The `vf` commands interact with radp-vagrant-framework for project management.

| Command                   | Description                      |
|---------------------------|----------------------------------|
| `vf init [dir]`           | Initialize a new vagrant project |
| `vf list`                 | List clusters and guests         |
| `vf info`                 | Show environment information     |
| `vf validate`             | Validate YAML configuration      |
| `vf dump-config`          | Export merged configuration      |
| `vf generate`             | Generate standalone Vagrantfile  |
| `vf template list`        | List available templates         |
| `vf template show <name>` | Show template details            |
| `vf version`              | Show framework version           |

## Project Templates

Templates provide pre-configured project structures for common use cases.

### List Templates

```shell
homelabctl vf template list
```

### Show Template Details

```shell
homelabctl vf template show single-node
```

### Initialize from Template

```shell
# Use a template
homelabctl vf init myproject -t single-node

# With custom variables
homelabctl vf init myproject -t k8s-cluster --set cluster_name=homelab --set worker_count=3
```

### Built-in Templates

| Template      | Description                                |
|---------------|--------------------------------------------|
| `base`        | Minimal setup for getting started          |
| `single-node` | Enhanced single VM with common provisions  |
| `k8s-cluster` | Kubernetes cluster with master and workers |

**User templates** can be added to `~/.config/radp-vagrant/templates/` and will override built-in templates with the
same name.

## Configuration

Projects use YAML configuration files in the `config/` directory.

### Directory Structure

```
myproject/
├── config/
│   ├── vagrant.yaml          # Base configuration (must contain radp.env)
│   └── vagrant-{env}.yaml    # Environment-specific clusters
├── provisions/
│   ├── definitions/          # Provision definition files
│   └── scripts/              # Provision scripts
└── .vagrant/                 # Vagrant state (created by vagrant up)
```

### Configuration Files

**vagrant.yaml** - Base configuration (required):

```yaml
radp:
  env: dev                           # Required: determines which vagrant-{env}.yaml to load
  extend:
    vagrant:
      plugins:
        - name: vagrant-hostmanager
          required: true
          options:
            enabled: true
            manage_host: true
            manage_guest: true

      config:
        common: # Global settings inherited by all guests
          box:
            name: generic/ubuntu2204
            version: "4.3.12"
            check-update: false

          provider:
            type: virtualbox
            mem: 2048
            cpus: 2
            gui: false
```

**vagrant-dev.yaml** - Environment-specific clusters:

```yaml
radp:
  extend:
    vagrant:
      config:
        clusters:
          - name: my-cluster
            common: # Cluster-level common settings
              box:
                name: generic/centos9s
              provider:
                mem: 4096
                cpus: 4

            guests:
              - id: node-1
                enabled: true
                hostname: node-1.my-cluster.dev  # Default: {id}.{cluster}.{env}

                provider:
                  mem: 8192
                  cpus: 8

                network:
                  private-network:
                    enabled: true
                    type: static
                    ip: 172.16.10.10
                    netmask: 255.255.255.0

                  forwarded-ports:
                    - enabled: true
                      guest: 80
                      host: 8080
```

### Configuration Inheritance

Settings are inherited and merged in this order:

```
Global common → Cluster common → Guest
```

| Config Type              | Merge Behavior                                                             |
|--------------------------|----------------------------------------------------------------------------|
| box, provider, network   | Deep merge (guest overrides)                                               |
| provisions               | Phase-aware: global-pre → cluster-pre → guest → cluster-post → global-post |
| triggers, synced-folders | Concatenate                                                                |

### View Configuration

```shell
# List clusters and guests
homelabctl vf list
homelabctl vf list -v # Verbose
homelabctl vf list --provisions # Show provisioners
homelabctl vf list --synced-folders

# Export merged configuration
homelabctl vf dump-config
homelabctl vf dump-config -f yaml
homelabctl vf dump-config -o config.json

# Validate configuration
homelabctl vf validate
```

## Environment Variables

| Variable                  | Description                  | Default                               |
|---------------------------|------------------------------|---------------------------------------|
| `RADP_VAGRANT_CONFIG_DIR` | Configuration directory path | `./config`                            |
| `RADP_VAGRANT_ENV`        | Override environment name    | Value from `radp.env` in vagrant.yaml |

### Setting Environment

```shell
# Use specific environment
RADP_VAGRANT_ENV=prod homelabctl vf vg up

# Use custom config directory
RADP_VAGRANT_CONFIG_DIR=/path/to/config homelabctl vf list
```

**Priority for environment resolution:**

```
-e flag > RADP_VAGRANT_ENV > radp.env in vagrant.yaml
```

## Examples

### Basic Single VM

```shell
# Initialize project
homelabctl vf init myvm -t single-node
cd myvm

# Start VM
homelabctl vf vg up

# SSH into VM
homelabctl vf vg ssh

# Stop VM
homelabctl vf vg halt
```

### Multi-VM Cluster

```shell
# Initialize with template
homelabctl vf init mycluster -t k8s-cluster --set worker_count=3
cd mycluster

# View configuration
homelabctl vf list -v

# Start all VMs
homelabctl vf vg up

# SSH into specific VM
homelabctl vf vg ssh master

# Check status
homelabctl vf vg status
```

### Working with Snapshots

```shell
# Create snapshot
homelabctl vf vg snapshot save clean-state

# List snapshots
homelabctl vf vg snapshot list

# Restore snapshot
homelabctl vf vg snapshot restore clean-state

# Delete snapshot
homelabctl vf vg snapshot delete clean-state
```

### Generate Standalone Vagrantfile

```shell
# Generate a self-contained Vagrantfile
homelabctl vf generate

# Generate to specific location
homelabctl vf generate -o /path/to/Vagrantfile
```

This creates a standalone Vagrantfile that doesn't require radp-vagrant-framework at runtime.

## Built-in Provisions

The framework includes ready-to-use provisions (prefix with `radp:`):

| Name                                | Description                         |
|-------------------------------------|-------------------------------------|
| `radp:time/chrony-sync`             | Configure chrony for NTP time sync  |
| `radp:system/expand-lvm`            | Expand LVM partition and filesystem |
| `radp:ssh/host-trust`               | Add host SSH key to guest           |
| `radp:ssh/cluster-trust`            | SSH trust between VMs in cluster    |
| `radp:crypto/gpg-import`            | Import GPG keys                     |
| `radp:crypto/gpg-preset-passphrase` | Preset GPG passphrase in gpg-agent  |
| `radp:git/clone`                    | Clone git repository                |
| `radp:yadm/clone`                   | Clone dotfiles using yadm           |
| `radp:nfs/external-nfs-mount`       | Mount external NFS shares           |

## Troubleshooting

### "radp-vf not found in PATH"

The framework is not installed or not in PATH:

```shell
# Check if radp-vf is available
which radp-vf

# Install via Homebrew
brew install radp-vagrant-framework

# Or add manual installation to PATH
export PATH="/path/to/radp-vagrant-framework/bin:$PATH"
```

### "Vagrantfile not found"

Ensure you're in a project directory with valid config:

```shell
# Initialize a new project
homelabctl vf init myproject
cd myproject

# Or check current directory has config/
ls config/vagrant.yaml
```

### VM fails to start

Check VirtualBox/provider status and logs:

```shell
# Check VM status
homelabctl vf vg status

# View Vagrant debug output
VAGRANT_LOG=debug homelabctl vf vg up
```

### Configuration validation errors

Validate your YAML configuration:

```shell
homelabctl vf validate
```

Common issues:

- Clusters must be in `vagrant-{env}.yaml`, not in base `vagrant.yaml`
- Duplicate cluster names or guest IDs within same environment
- Missing `radp.env` in base `vagrant.yaml`

## Further Reading

For detailed VM configuration options, see the radp-vagrant-framework documentation:

- [Configuration Reference](https://github.com/xooooooooox/radp-vagrant-framework/blob/main/docs/configuration.md) - Box, provider, network, synced folders
- [Provisions Guide](https://github.com/xooooooooox/radp-vagrant-framework/blob/main/docs/user-guide/provisions.md) - Shell provisions and builtin provisions
- [Triggers Guide](https://github.com/xooooooooox/radp-vagrant-framework/blob/main/docs/user-guide/triggers.md) - Before/after triggers
- [Plugins Guide](https://github.com/xooooooooox/radp-vagrant-framework/blob/main/docs/user-guide/plugins.md) - vagrant-hostmanager, vagrant-vbguest, etc.
- [Templates Guide](https://github.com/xooooooooox/radp-vagrant-framework/blob/main/docs/user-guide/templates.md) - Project templates
