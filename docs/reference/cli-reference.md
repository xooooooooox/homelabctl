# CLI Reference

Complete reference for `homelabctl` commands and options.

## Command Structure

```
homelabctl [global-options] <command> [command-options] [arguments]
```

## Global Options

| Option | Description |
|--------|-------------|
| `-v, --verbose` | Enable verbose output (banner + info logs) |
| `--debug` | Enable debug output (banner + debug logs) |
| `--config` | Show configuration |
| `--config --all` | Include extension configurations |
| `-h, --help` | Show help |
| `--version` | Show version |

## Commands

### vf

Passthrough to radp-vagrant-framework.

```shell
homelabctl vf <radp-vf-command> [options]
```

| Subcommand | Description |
|------------|-------------|
| `vg <cmd>` | Run vagrant commands |
| `init [dir]` | Initialize a vagrant project |
| `list` | List clusters and guests |
| `info` | Show radp-vagrant-framework info |
| `validate` | Validate YAML configuration |
| `dump-config` | Export merged configuration |
| `generate` | Generate standalone Vagrantfile |
| `template list` | List available templates |
| `template show` | Show template details |
| `version` | Show framework version |

**vg options:**

| Option | Description |
|--------|-------------|
| `-C, --cluster <names>` | Cluster names (comma-separated) |
| `-G, --guest-ids <ids>` | Guest IDs (requires --cluster) |
| `-c, --config <dir>` | Configuration directory |
| `-e, --env <name>` | Override environment |

**Examples:**

```shell
homelabctl vf vg status
homelabctl vf vg up -C my-cluster
homelabctl vf vg up -C my-cluster -G 1,2
homelabctl vf init myproject --template k8s-cluster
```

### setup list

List available packages.

```shell
homelabctl setup list [options]
```

| Option | Description |
|--------|-------------|
| `-c, --category <name>` | Filter by category |
| `--installed` | Show only installed packages |
| `--categories` | Show category list |

### setup info

Show package details.

```shell
homelabctl setup info <name>
```

Shows: description, category, homepage, dependencies, conflicts.

### setup deps

Show dependency tree.

```shell
homelabctl setup deps <name> [options]
```

| Option | Description |
|--------|-------------|
| `--reverse` | Show reverse dependencies |

### setup install

Install a package.

```shell
homelabctl setup install <name> [options]
```

| Option | Description |
|--------|-------------|
| `-v, --version <ver>` | Specific version |
| `--dry-run` | Preview without installing |
| `--no-deps` | Skip dependencies |

**Examples:**

```shell
homelabctl setup install fzf
homelabctl setup install nodejs -v 20
homelabctl setup install fzf --dry-run
```

### setup profile list

List available profiles.

```shell
homelabctl setup profile list
```

### setup profile show

Show profile details.

```shell
homelabctl setup profile show <name>
```

### setup profile apply

Apply a profile.

```shell
homelabctl setup profile apply <name> [options]
```

| Option | Description |
|--------|-------------|
| `--dry-run` | Preview without installing |
| `--continue` | Continue on errors |
| `--skip-installed` | Skip already installed |
| `--no-deps` | Skip dependencies |

### setup configure list

List available system configurations.

```shell
homelabctl setup configure list
```

### setup configure chrony

Configure chrony for NTP time synchronization.

```shell
homelabctl setup configure chrony [options]
```

| Option | Description |
|--------|-------------|
| `--servers <list>` | NTP servers (comma-separated) |
| `--timezone <tz>` | Timezone to set |
| `--dry-run` | Preview changes |

### setup configure expand-lvm

Expand LVM partition and filesystem.

```shell
homelabctl setup configure expand-lvm [options]
```

| Option | Description |
|--------|-------------|
| `--partition <dev>` | LVM partition (auto-detected) |
| `--vg <name>` | Volume group (auto-detected) |
| `--lv <name>` | Logical volume (auto-detected) |
| `--dry-run` | Preview changes |

### setup configure gpg-import

Import GPG keys.

```shell
homelabctl setup configure gpg-import [options]
```

| Option | Description |
|--------|-------------|
| `--public-key-file <path>` | Path to public key |
| `--secret-key-file <path>` | Path to secret key |
| `--key-id <id>` | Key ID to fetch from keyserver |
| `--passphrase-file <path>` | Path to passphrase |
| `--keyserver <url>` | Keyserver URL |
| `--dry-run` | Preview changes |

### setup configure gpg-preset

Preset GPG passphrase in gpg-agent.

```shell
homelabctl setup configure gpg-preset [options]
```

| Option | Description |
|--------|-------------|
| `--key-uid <email>` | Key UID (email) |
| `--passphrase-file <path>` | Path to passphrase |
| `--dry-run` | Preview changes |

### setup configure yadm

Clone dotfiles repository using yadm.

```shell
homelabctl setup configure yadm [options]
```

| Option | Description |
|--------|-------------|
| `--repo-url <url>` | Repository URL |
| `--ssh-key-file <path>` | SSH key file |
| `--bootstrap` | Run yadm bootstrap |
| `--dry-run` | Preview changes |

### version

Show homelabctl version.

```shell
homelabctl version
```

### completion

Generate shell completion script.

```shell
homelabctl completion <bash|zsh>
```

## Environment Variables

| Variable | Description |
|----------|-------------|
| `RADP_VF_HOME` | Path to radp-vagrant-framework |
| `RADP_VAGRANT_CONFIG_DIR` | Override config directory |
| `RADP_VAGRANT_ENV` | Override environment name |

## See Also

- [Getting Started](../getting-started.md) - Quick start guide
- [Setup Guide](../user-guide/setup-guide.md) - Setup feature details
- [Vagrant Guide](../user-guide/vagrant-guide.md) - VM management
