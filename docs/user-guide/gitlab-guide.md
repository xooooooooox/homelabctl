# GitLab Guide

The `gitlab` command group provides complete GitLab management for homelab environments. It supports installation,
initialization, service management, backup/restore operations, and health monitoring.

## Table of Contents

- [Quick Start](#quick-start)
- [Installation](#installation)
- [Configuration](#configuration)
- [Service Management](#service-management)
- [Backup and Restore](#backup-and-restore)
- [Maintenance](#maintenance)
- [Configuration Reference](#configuration-reference)

## Quick Start

```shell
# Install GitLab Community Edition
homelabctl gitlab install

# Initialize with your custom config
homelabctl gitlab init --user-config /data/homelab_gitlab.rb

# Check status
homelabctl gitlab status

# Create a backup
homelabctl gitlab backup create
```

## Installation

### Basic Installation

Install GitLab Community Edition with default settings:

```shell
homelabctl gitlab install
```

### Enterprise Edition

Install GitLab Enterprise Edition:

```shell
homelabctl gitlab install -t gitlab-ee
```

### Specific Version

Install a specific GitLab version:

```shell
homelabctl gitlab install -v 17.0
homelabctl gitlab install -t gitlab-ee -v 16.11
```

### Custom Data Directory

Store GitLab data on an external disk or NAS mount:

```shell
homelabctl gitlab install --data-dir /data/gitlab
```

This creates a symlink from `/var/opt/gitlab` to your specified directory.

### Installation Options

| Option           | Description                                       |
|------------------|---------------------------------------------------|
| `-t, --type`     | GitLab type: `gitlab-ce` (default) or `gitlab-ee` |
| `-v, --version`  | Specific version to install (default: latest)     |
| `--data-dir`     | Custom data directory for GitLab data             |
| `--skip-postfix` | Skip postfix mail server installation             |
| `--dry-run`      | Preview installation steps without executing      |

### What Installation Does

1. Checks system requirements (CPU, RAM)
2. Disables SELinux and firewalld (for RHEL-based systems)
3. Installs postfix for email notifications
4. Adds GitLab package repository
5. Sets up data directory symlink (if specified)
6. Installs GitLab package

### Post-Installation

After installation, get the initial root password:

```shell
sudo cat /etc/gitlab/initial_root_password
```

This password is valid for 24 hours after installation.

## Configuration

### Initialize GitLab

After installation, initialize GitLab with your custom configuration:

```shell
homelabctl gitlab init --user-config /data/homelab_gitlab.rb
```

### Custom Configuration File

Create a custom GitLab configuration file (e.g., `/data/homelab_gitlab.rb`):

```ruby
# External URL
external_url 'https://gitlab.example.com'

# HTTPS settings
nginx['redirect_http_to_https'] = true
nginx['ssl_certificate'] = "/etc/gitlab/ssl/gitlab.crt"
nginx['ssl_certificate_key'] = "/etc/gitlab/ssl/gitlab.key"

# Email settings
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp.example.com"
gitlab_rails['smtp_port'] = 587

# Backup settings
gitlab_rails['backup_path'] = "/var/opt/gitlab/backups"
gitlab_rails['backup_keep_time'] = 604800 # 7 days
```

The `gitlab init` command uses GitLab's `from_file` directive to include your configuration, preserving the original
`gitlab.rb` as a template.

### Initialization Options

| Option               | Description                                                  |
|----------------------|--------------------------------------------------------------|
| `--user-config`      | Path to your custom GitLab config file                       |
| `--backup-schedule`  | Cron schedule for automatic backups (default: `"0 4 * * *"`) |
| `--skip-crontab`     | Don't set up automatic backup crontab                        |
| `--skip-reconfigure` | Skip reconfigure and restart (only setup directories)        |
| `--dry-run`          | Preview changes without executing                            |

### What Initialization Does

1. Creates config backup directory
2. Saves original `gitlab.rb` as a version-tagged template
3. Adds `from_file` directive to reference your custom config
4. Runs `gitlab-ctl reconfigure`
5. Restarts GitLab services
6. Sets up automatic backup crontab

## Service Management

### Check Status

View GitLab installation status and recent backup information:

```shell
homelabctl gitlab status
```

Show detailed service status:

```shell
homelabctl gitlab status --services
```

### Health Checks

Run GitLab health checks:

```shell
homelabctl gitlab healthcheck
homelabctl gitlab healthcheck --verbose
homelabctl gitlab healthcheck --verbose --check-secrets
```

### Start/Stop/Restart

Manage all GitLab services:

```shell
homelabctl gitlab start
homelabctl gitlab stop
homelabctl gitlab restart
```

Manage specific services:

```shell
homelabctl gitlab restart --service puma
homelabctl gitlab restart --service sidekiq
homelabctl gitlab stop --service gitaly
```

### Reset User Password

Reset a GitLab user's password:

```shell
homelabctl gitlab reset-password root
homelabctl gitlab reset-password admin --force
```

This opens the GitLab Rails console to set a new password interactively.

## Backup and Restore

### Create Backup

Create a full backup (data + configuration):

```shell
homelabctl gitlab backup create
```

Create specific backup types:

```shell
homelabctl gitlab backup create --type data # Data only
homelabctl gitlab backup create --type config # Config only
```

Copy backup to a custom location:

```shell
homelabctl gitlab backup create --target /mnt/nas/backups
```

Skip remote backup location:

```shell
homelabctl gitlab backup create --skip-remote
```

### List Backups

List available backups:

```shell
homelabctl gitlab backup list
homelabctl gitlab backup list --type data
homelabctl gitlab backup list --type config
```

### Cleanup Old Backups

Remove old backups:

```shell
homelabctl gitlab backup cleanup
homelabctl gitlab backup cleanup --keep-days 7
homelabctl gitlab backup cleanup --dry-run
```

### Restore from Backup

Restore everything (data + config):

```shell
homelabctl gitlab restore
```

Restore specific components:

```shell
homelabctl gitlab restore --type data
homelabctl gitlab restore --type config
```

Restore from a specific backup file:

```shell
homelabctl gitlab restore /path/to/backup.tar --force
```

Search for backups in a specific location:

```shell
homelabctl gitlab restore --source /mnt/nas/backups
```

### Automatic Backups

The `gitlab init` command sets up automatic daily backups via crontab:

- **Daily backup**: Runs at 4 AM (configurable with `--backup-schedule`)
- **Weekly cleanup**: Runs Saturdays at 8 PM, removes backups older than configured retention period

View the backup crontab:

```shell
crontab -l | grep gitlab
```

## Maintenance

### Regular Maintenance Tasks

```shell
# Check system health
homelabctl gitlab healthcheck --verbose

# View status and recent backups
homelabctl gitlab status

# Create manual backup before maintenance
homelabctl gitlab backup create

# Restart services after configuration changes
homelabctl gitlab restart
```

### Upgrading GitLab

Before upgrading:

1. Create a full backup:
   ```shell
   homelabctl gitlab backup create
   ```

2. Check current version:
   ```shell
   homelabctl gitlab status
   ```

3. Follow GitLab's upgrade path documentation

### Troubleshooting

Check service logs:

```shell
sudo gitlab-ctl tail
sudo gitlab-ctl tail puma
sudo gitlab-ctl tail sidekiq
```

Run health checks with secrets doctor:

```shell
homelabctl gitlab healthcheck --verbose --check-secrets
```

Reconfigure after config changes:

```shell
sudo gitlab-ctl reconfigure
homelabctl gitlab restart
```

## Configuration Reference

### homelabctl Configuration

GitLab settings in `~/.config/homelabctl/config.yaml`:

```yaml
radp:
  extend:
    homelabctl:
      gitlab:
        # Default GitLab type (gitlab-ce or gitlab-ee)
        type: gitlab-ce
        # Default version (empty for latest)
        version: ""
        # External data directory (for symlink)
        external_data_dir: ""
        # User config file path
        user_config_file: ""
        # Backup schedule (cron format)
        backup_schedule: "0 4 * * *"
        # Backup retention days
        backup_keep_days: 30
        # Remote backup location (NAS, etc.)
        backup_home_remote: ""
```

### Directory Paths

| Path                         | Description                    |
|------------------------------|--------------------------------|
| `/etc/gitlab/`               | GitLab configuration directory |
| `/etc/gitlab/gitlab.rb`      | Main configuration file        |
| `/var/opt/gitlab/`           | GitLab data directory          |
| `/var/opt/gitlab/backups/`   | Default backup location        |
| `/etc/gitlab/config_backup/` | Config backup directory        |

### Common Services

| Service      | Description              |
|--------------|--------------------------|
| `puma`       | GitLab web server        |
| `sidekiq`    | Background job processor |
| `gitaly`     | Git RPC service          |
| `postgresql` | Database server          |
| `redis`      | In-memory data store     |
| `nginx`      | Reverse proxy            |

## See Also

- [CLI Reference - GitLab Commands](../reference/cli-reference.md#gitlab-install)
- [GitLab Official Documentation](https://docs.gitlab.com/)
- [GitLab Backup and Restore](https://docs.gitlab.com/ee/administration/backup_restore/)
