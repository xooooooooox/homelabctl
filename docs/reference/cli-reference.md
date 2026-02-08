# CLI Reference

Complete reference for `homelabctl` commands and options.

## Command Structure

```
homelabctl [global-options] <command> [command-options] [arguments]
```

## Global Options

| Option           | Description                                |
|------------------|--------------------------------------------|
| `-v, --verbose`  | Enable verbose output (banner + info logs) |
| `--debug`        | Enable debug output (banner + debug logs)  |
| `--config`       | Show configuration                         |
| `--config --all` | Include extension configurations           |
| `-h, --help`     | Show help                                  |
| `--version`      | Show version                               |

## Commands

### vf

Passthrough to radp-vagrant-framework.

```shell
homelabctl vf <radp-vf-command >[options]
```

| Subcommand      | Description                      |
|-----------------|----------------------------------|
| `vg <cmd>`      | Run vagrant commands             |
| `init [dir]`    | Initialize a vagrant project     |
| `list`          | List clusters and guests         |
| `info`          | Show radp-vagrant-framework info |
| `validate`      | Validate YAML configuration      |
| `dump-config`   | Export merged configuration      |
| `generate`      | Generate standalone Vagrantfile  |
| `template list` | List available templates         |
| `template show` | Show template details            |
| `version`       | Show framework version           |

**vg options:**

| Option                  | Description                     |
|-------------------------|---------------------------------|
| `-C, --cluster <names>` | Cluster names (comma-separated) |
| `-G, --guest-ids <ids>` | Guest IDs (requires --cluster)  |
| `-c, --config <dir>`    | Configuration directory         |
| `-e, --env <name>`      | Override environment            |

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

| Option                  | Description                  |
|-------------------------|------------------------------|
| `-c, --category <name>` | Filter by category           |
| `--installed`           | Show only installed packages |
| `--categories`          | Show category list           |

### setup info

Show package details.

```shell
homelabctl setup info <name>
```

Shows: description, category, homepage, dependencies, conflicts.

### setup deps

Show dependency tree.

```shell
homelabctl setup deps <name >[options]
```

| Option      | Description               |
|-------------|---------------------------|
| `--reverse` | Show reverse dependencies |

### setup install

Install a package.

```shell
homelabctl setup install <name >[options]
```

| Option                | Description                |
|-----------------------|----------------------------|
| `-v, --version <ver>` | Specific version           |
| `--dry-run`           | Preview without installing |
| `--no-deps`           | Skip dependencies          |

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

Show profile details including description, platform, source, and package list with install status.
If the profile uses `extends`, the `Extends:` field is displayed and the package list includes inherited packages.

```shell
homelabctl setup profile show <name>
```

### setup profile apply

Apply a profile.

```shell
homelabctl setup profile apply <name >[options]
```

| Option             | Description                |
|--------------------|----------------------------|
| `--dry-run`        | Preview without installing |
| `--continue`       | Continue on errors         |
| `--skip-installed` | Skip already installed     |
| `--no-deps`        | Skip dependencies          |

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

| Option             | Description                   |
|--------------------|-------------------------------|
| `--servers <list>` | NTP servers (comma-separated) |
| `--timezone <tz>`  | Timezone to set               |
| `--dry-run`        | Preview changes               |

### setup configure expand-lvm

Expand LVM partition and filesystem.

```shell
homelabctl setup configure expand-lvm [options]
```

| Option              | Description                    |
|---------------------|--------------------------------|
| `--partition <dev>` | LVM partition (auto-detected)  |
| `--vg <name>`       | Volume group (auto-detected)   |
| `--lv <name>`       | Logical volume (auto-detected) |
| `--dry-run`         | Preview changes                |

### setup configure gpg-import

Import GPG keys.

```shell
homelabctl setup configure gpg-import [options]
```

| Option                     | Description                    |
|----------------------------|--------------------------------|
| `--public-key-file <path>` | Path to public key             |
| `--secret-key-file <path>` | Path to secret key             |
| `--key-id <id>`            | Key ID to fetch from keyserver |
| `--passphrase-file <path>` | Path to passphrase             |
| `--keyserver <url>`        | Keyserver URL                  |
| `--dry-run`                | Preview changes                |

### setup configure gpg-preset

Preset GPG passphrase in gpg-agent.

```shell
homelabctl setup configure gpg-preset [options]
```

| Option                     | Description        |
|----------------------------|--------------------|
| `--key-uid <email>`        | Key UID (email)    |
| `--passphrase-file <path>` | Path to passphrase |
| `--dry-run`                | Preview changes    |

### setup configure yadm

Clone dotfiles repository using yadm.

```shell
homelabctl setup configure yadm [options]
```

| Option                  | Description        |
|-------------------------|--------------------|
| `--repo-url <url>`      | Repository URL     |
| `--ssh-key-file <path>` | SSH key file       |
| `--bootstrap`           | Run yadm bootstrap |
| `--dry-run`             | Preview changes    |

### gitlab install

Install GitLab (gitlab-ce or gitlab-ee) via linux_package.

```shell
homelabctl gitlab install [options]
```

| Option                | Description                                                    |
|-----------------------|----------------------------------------------------------------|
| `-t, --type <type>`   | GitLab type: `gitlab-ce` or `gitlab-ee` (default: `gitlab-ce`) |
| `-v, --version <ver>` | GitLab version (default: latest)                               |
| `--data-dir <path>`   | Custom data directory (symlink target)                         |
| `--skip-postfix`      | Skip postfix installation                                      |
| `--dry-run`           | Show what would be done                                        |

**Examples:**

```shell
homelabctl gitlab install
homelabctl gitlab install -t gitlab-ee
homelabctl gitlab install -t gitlab-ce -v 17.0
homelabctl gitlab install --data-dir /data/gitlab
```

### gitlab init

Initialize GitLab after installation.

```shell
homelabctl gitlab init [options]
```

| Option                     | Description                                      |
|----------------------------|--------------------------------------------------|
| `--user-config <path>`     | User's custom GitLab config file                 |
| `--backup-schedule <cron>` | Backup crontab schedule (default: `"0 4 * * *"`) |
| `--skip-crontab`           | Skip automatic backup crontab setup              |
| `--skip-reconfigure`       | Skip reconfigure and restart                     |
| `--dry-run`                | Show what would be done                          |

**Examples:**

```shell
homelabctl gitlab init
homelabctl gitlab init --user-config /data/homelab_gitlab.rb
homelabctl gitlab init --skip-crontab
homelabctl gitlab init --backup-schedule "0 2 * * *"
```

### gitlab status

Show GitLab status and version info.

```shell
homelabctl gitlab status [options]
```

| Option       | Description                     |
|--------------|---------------------------------|
| `--services` | Show all service status details |

**Examples:**

```shell
homelabctl gitlab status
homelabctl gitlab status --services
```

### gitlab healthcheck

Run GitLab health checks.

```shell
homelabctl gitlab healthcheck [options]
```

| Option            | Description             |
|-------------------|-------------------------|
| `--verbose`       | Show detailed output    |
| `--check-secrets` | Also run secrets doctor |
| `--dry-run`       | Show what would be done |

**Examples:**

```shell
homelabctl gitlab healthcheck
homelabctl gitlab healthcheck --verbose
homelabctl gitlab healthcheck --verbose --check-secrets
```

### gitlab start

Start GitLab services.

```shell
homelabctl gitlab start [options]
```

| Option             | Description                                     |
|--------------------|-------------------------------------------------|
| `--service <name>` | Specific service to start (puma, sidekiq, etc.) |
| `--dry-run`        | Show what would be done                         |

**Examples:**

```shell
homelabctl gitlab start
homelabctl gitlab start --service puma
homelabctl gitlab start --service sidekiq
```

### gitlab stop

Stop GitLab services.

```shell
homelabctl gitlab stop [options]
```

| Option             | Description                                    |
|--------------------|------------------------------------------------|
| `--service <name>` | Specific service to stop (puma, sidekiq, etc.) |
| `--dry-run`        | Show what would be done                        |

**Examples:**

```shell
homelabctl gitlab stop
homelabctl gitlab stop --service puma
```

### gitlab restart

Restart GitLab services.

```shell
homelabctl gitlab restart [options]
```

| Option             | Description                                       |
|--------------------|---------------------------------------------------|
| `--service <name>` | Specific service to restart (puma, sidekiq, etc.) |
| `--dry-run`        | Show what would be done                           |

**Examples:**

```shell
homelabctl gitlab restart
homelabctl gitlab restart --service puma
```

### gitlab reset-password

Reset GitLab user password.

```shell
homelabctl gitlab reset-password <username >[options]
```

| Option      | Description              |
|-------------|--------------------------|
| `--force`   | Skip confirmation prompt |
| `--dry-run` | Show what would be done  |

**Examples:**

```shell
homelabctl gitlab reset-password root
homelabctl gitlab reset-password admin --force
```

### gitlab backup create

Create GitLab backup (data and/or configuration).

```shell
homelabctl gitlab backup create [options]
```

| Option            | Description                                           |
|-------------------|-------------------------------------------------------|
| `--target <path>` | Target directory for backup                           |
| `--type <type>`   | Backup type: `all`, `data`, `config` (default: `all`) |
| `--skip-remote`   | Skip copy to remote/NAS location                      |
| `--dry-run`       | Show what would be done                               |

**Examples:**

```shell
homelabctl gitlab backup create
homelabctl gitlab backup create --type data
homelabctl gitlab backup create --type config --skip-remote
homelabctl gitlab backup create --target /mnt/nas/backups
```

### gitlab backup list

List available GitLab backups.

```shell
homelabctl gitlab backup list [options]
```

| Option          | Description                                           |
|-----------------|-------------------------------------------------------|
| `--type <type>` | Backup type: `all`, `data`, `config` (default: `all`) |

**Examples:**

```shell
homelabctl gitlab backup list
homelabctl gitlab backup list --type data
```

### gitlab backup cleanup

Clean old GitLab backups.

```shell
homelabctl gitlab backup cleanup [options]
```

| Option            | Description                                 |
|-------------------|---------------------------------------------|
| `--keep-days <n>` | Days to keep backups (default: from config) |
| `--dry-run`       | Show what would be done                     |

**Examples:**

```shell
homelabctl gitlab backup cleanup
homelabctl gitlab backup cleanup --keep-days 7
homelabctl gitlab backup cleanup --dry-run
```

### gitlab restore

Restore GitLab data and/or configuration from backup.

```shell
homelabctl gitlab restore [backup_file] [options]
```

| Option            | Description                                            |
|-------------------|--------------------------------------------------------|
| `--type <type>`   | Restore type: `all`, `data`, `config` (default: `all`) |
| `--source <path>` | Source directory to search for backups                 |
| `--force`         | Skip confirmation prompts                              |
| `--dry-run`       | Show what would be done                                |

**Examples:**

```shell
homelabctl gitlab restore
homelabctl gitlab restore --type data
homelabctl gitlab restore --type config
homelabctl gitlab restore /path/to/backup.tar --force
homelabctl gitlab restore --source /mnt/nas/backups
```

### init setup

Initialize setup user configuration directory.

```shell
homelabctl init setup [options]
```

| Option      | Description                |
|-------------|----------------------------|
| `--force`   | Overwrite existing files   |
| `--dry-run` | Show what would be created |

**Examples:**

```shell
homelabctl init setup
homelabctl init setup --dry-run
homelabctl init setup --force
```

### init k8s

Initialize k8s user configuration directory.

```shell
homelabctl init k8s [options]
```

| Option      | Description                |
|-------------|----------------------------|
| `--force`   | Overwrite existing files   |
| `--dry-run` | Show what would be created |

**Examples:**

```shell
homelabctl init k8s
homelabctl init k8s --dry-run
```

### init all

Initialize all user configuration directories (setup + k8s).

```shell
homelabctl init all [options]
```

| Option      | Description                |
|-------------|----------------------------|
| `--force`   | Overwrite existing files   |
| `--dry-run` | Show what would be created |

### init vf

Initialize vagrant project (passthrough to radp-vf init).

```shell
homelabctl init vf [radp-vf-init-options]
```

All arguments are passed through to `radp-vf init`.

**Examples:**

```shell
homelabctl init vf myproject
homelabctl init vf myproject -t k8s-cluster
homelabctl init vf --list-templates
```

### k8s health

Check Kubernetes cluster health.

```shell
homelabctl k8s health [options]
```

| Option      | Description           |
|-------------|-----------------------|
| `--verbose` | Show detailed output  |

**Examples:**

```shell
homelabctl k8s health
homelabctl k8s health --verbose
```

### k8s install

Install Kubernetes (kubeadm, kubelet, kubectl).

```shell
homelabctl k8s install [options]
```

| Option                     | Description                               |
|----------------------------|-------------------------------------------|
| `-t, --type <type>`        | Install type: kubeadm or minikube         |
| `-v, --version <ver>`      | Kubernetes version (default: 1.30)        |
| `--skip-prerequisites`     | Skip prerequisites configuration          |
| `--skip-container-runtime` | Skip container runtime installation       |
| `--dry-run`                | Show what would be done                   |

**Examples:**

```shell
homelabctl k8s install
homelabctl k8s install -v 1.29
homelabctl k8s install -t kubeadm -v 1.30
```

### k8s init master

Initialize Kubernetes master node.

```shell
homelabctl k8s init master [options]
```

| Option                                | Description                            |
|---------------------------------------|----------------------------------------|
| `-a, --apiserver-advertise-address!`  | API server advertise address (required)|
| `-p, --pod-network-cidr <cidr>`       | Pod network CIDR (default: 10.244.0.0/16)|
| `--dry-run`                           | Show what would be done                |

**Examples:**

```shell
homelabctl k8s init master -a 192.168.1.100
homelabctl k8s init master -a 192.168.1.100 -p 10.244.0.0/16
```

### k8s init worker

Initialize Kubernetes worker node and join cluster.

```shell
homelabctl k8s init worker [options]
```

| Option                              | Description                                |
|-------------------------------------|--------------------------------------------|
| `-c, --control-plane! <host:port>`  | Control plane address (required)           |
| `-t, --token <token>`               | Join token (optional)                      |
| `--discovery-token-ca-cert-hash`    | CA cert hash (optional)                    |
| `--dry-run`                         | Show what would be done                    |

**Examples:**

```shell
homelabctl k8s init worker -c 192.168.1.100:6443
homelabctl k8s init worker -c 192.168.1.100:6443 -t abcdef.1234567890abcdef
```

### k8s addon install

Install a Kubernetes addon.

```shell
homelabctl k8s addon install <name> [options]
```

| Option                    | Description                      |
|---------------------------|----------------------------------|
| `-v, --version <ver>`     | Addon version                    |
| `-f, --values <file>`     | Custom values file for helm      |
| `--dry-run`               | Show what would be done          |

**Examples:**

```shell
homelabctl k8s addon install metallb
homelabctl k8s addon install ingress-nginx -v 4.11.1
homelabctl k8s addon install cert-manager -f /path/to/values.yaml
```

### k8s addon uninstall

Uninstall a Kubernetes addon.

```shell
homelabctl k8s addon uninstall <name> [options]
```

| Option      | Description             |
|-------------|-------------------------|
| `--dry-run` | Show what would be done |

**Examples:**

```shell
homelabctl k8s addon uninstall metallb
homelabctl k8s addon uninstall ingress-nginx
```

### k8s addon list

List available Kubernetes addons.

```shell
homelabctl k8s addon list [options]
```

| Option        | Description                |
|---------------|----------------------------|
| `--installed` | Show only installed addons |

**Examples:**

```shell
homelabctl k8s addon list
homelabctl k8s addon list --installed
```

### k8s addon quickstart

Install recommended addons (alias for 'profile apply quickstart').

```shell
homelabctl k8s addon quickstart [options]
```

| Option             | Description                     |
|--------------------|---------------------------------|
| `--dry-run`        | Show what would be done         |
| `--continue`       | Continue on error               |
| `--skip-installed` | Skip already installed addons   |

### k8s addon profile list

List available addon profiles.

```shell
homelabctl k8s addon profile list [options]
```

| Option         | Description                        |
|----------------|------------------------------------|
| `--names-only` | Output profile names only          |

### k8s addon profile show

Show addon profile details.

```shell
homelabctl k8s addon profile show <name>
```

**Examples:**

```shell
homelabctl k8s addon profile show quickstart
homelabctl k8s addon profile show production
```

### k8s addon profile apply

Apply an addon profile (install multiple addons).

```shell
homelabctl k8s addon profile apply <name> [options]
```

| Option             | Description                     |
|--------------------|---------------------------------|
| `--dry-run`        | Show what would be installed    |
| `--continue`       | Continue on error               |
| `--skip-installed` | Skip already installed addons   |

**Examples:**

```shell
homelabctl k8s addon profile apply quickstart
homelabctl k8s addon profile apply quickstart --dry-run
homelabctl k8s addon profile apply production --continue
```

### k8s token create

Create a new Kubernetes join token.

```shell
homelabctl k8s token create [options]
```

| Option                  | Description                           |
|-------------------------|---------------------------------------|
| `--print-join-command`  | Print full join command after creation|

**Examples:**

```shell
homelabctl k8s token create
homelabctl k8s token create --print-join-command
```

### k8s token get

Get current valid Kubernetes token.

```shell
homelabctl k8s token get [options]
```

| Option           | Description                              |
|------------------|------------------------------------------|
| `--create`       | Create new token if no valid token exists|
| `--join-command` | Print full join command instead of token |

**Examples:**

```shell
homelabctl k8s token get
homelabctl k8s token get --create
homelabctl k8s token get --join-command
```

### k8s backup create

Create etcd backup.

```shell
homelabctl k8s backup create [options]
```

| Option           | Description                                          |
|------------------|------------------------------------------------------|
| `-d, --dir`      | Backup directory (default: /var/opt/k8s/backups/etcd)|
| `--dry-run`      | Show what would be done                              |

**Examples:**

```shell
homelabctl k8s backup create
homelabctl k8s backup create -d /backup/etcd
```

### k8s backup list

List available etcd backups.

```shell
homelabctl k8s backup list [options]
```

| Option      | Description                                          |
|-------------|------------------------------------------------------|
| `-d, --dir` | Backup directory (default: /var/opt/k8s/backups/etcd)|

### k8s backup restore

Restore etcd from backup.

```shell
homelabctl k8s backup restore <file> [options]
```

| Option           | Description                          |
|------------------|--------------------------------------|
| `--data-dir`     | etcd data directory (default: /var/lib/etcd)|
| `--dry-run`      | Show what would be done              |
| `--force`        | Skip confirmation prompt             |

**Examples:**

```shell
homelabctl k8s backup restore /var/opt/k8s/backups/etcd/etcd-snapshot-20240101120000.db
```

### setup uninstall

Uninstall a software package.

```shell
homelabctl setup uninstall <name> [options]
```

| Option      | Description                              |
|-------------|------------------------------------------|
| `--purge`   | Remove configuration files as well       |
| `--dry-run` | Show what would be uninstalled           |

**Examples:**

```shell
homelabctl setup uninstall docker
homelabctl setup uninstall docker --purge
homelabctl setup uninstall containerd --dry-run
```

### setup configure docker rootless

Configure Docker for non-root user access.

```shell
homelabctl setup configure docker rootless [options]
```

| Option           | Description                       |
|------------------|-----------------------------------|
| `-u, --user`     | Target user (default: current)    |
| `--dry-run`      | Show what would be done           |

**Examples:**

```shell
homelabctl setup configure docker rootless
homelabctl setup configure docker rootless -u vagrant
homelabctl setup configure docker rootless --dry-run
```

### setup configure docker acceleration

Configure Docker acceleration (proxy or registry mirrors).

```shell
homelabctl setup configure docker acceleration [options]
```

| Option             | Description                                  |
|--------------------|----------------------------------------------|
| `--proxy <url>`    | HTTP/HTTPS proxy URL                         |
| `--https-proxy`    | HTTPS proxy URL (default: same as --proxy)   |
| `--no-proxy`       | Hosts to bypass proxy (default: localhost,127.0.0.1)|
| `--mirrors <list>` | Comma-separated registry mirror URLs         |
| `--remove-proxy`   | Remove existing proxy configuration          |
| `--dry-run`        | Show what would be done                      |

**Examples:**

```shell
homelabctl setup configure docker acceleration --mirrors "https://mirror.ccs.tencentyun.com"
homelabctl setup configure docker acceleration --proxy "http://192.168.1.1:8080"
homelabctl setup configure docker acceleration --proxy "http://proxy:8080" --no-proxy "localhost,127.0.0.1,10.0.0.0/8"
homelabctl setup configure docker acceleration --remove-proxy
```

### gitlab runner install

Install GitLab Runner.

```shell
homelabctl gitlab runner install [options]
```

| Option      | Description             |
|-------------|-------------------------|
| `--dry-run` | Show what would be done |

**Examples:**

```shell
homelabctl gitlab runner install
homelabctl gitlab runner install --dry-run
```

### version

Show homelabctl version.

```shell
homelabctl version
```

### completion

Generate shell completion script.

```shell
homelabctl completion <bash | zsh>
```

## Environment Variables

| Variable                  | Description                    |
|---------------------------|--------------------------------|
| `RADP_VF_HOME`            | Path to radp-vagrant-framework |
| `RADP_VAGRANT_CONFIG_DIR` | Override config directory      |
| `RADP_VAGRANT_ENV`        | Override environment name      |

## See Also

- [Getting Started](../getting-started.md) - Quick start guide
- [Setup Guide](../user-guide/setup-guide.md) - Setup feature details
- [K8s Guide](../user-guide/k8s-guide.md) - Kubernetes management
- [GitLab Guide](../user-guide/gitlab-guide.md) - GitLab management
- [Vagrant Guide](../user-guide/vagrant-guide.md) - VM management
