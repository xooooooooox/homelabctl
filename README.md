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

## Prerequisites

homelabctl requires radp-bash-framework to be installed:

```shell
brew tap xooooooooox/radp
brew install radp-bash-framework
```

Or see: https://github.com/xooooooooox/radp-bash-framework#installation

## Installation

### Script (curl / wget / fetch)

```shell
curl -fsSL https://raw.githubusercontent.com/xooooooooox/homelabctl/main/install.sh | bash
```

Or:

```shell
wget -qO- https://raw.githubusercontent.com/xooooooooox/homelabctl/main/install.sh | bash
```

Optional variables:

```shell
HOMELABCTL_VERSION=vX.Y.Z \
  HOMELABCTL_REF=main \
  HOMELABCTL_INSTALL_DIR="$HOME/.local/lib/homelabctl" \
  HOMELABCTL_BIN_DIR="$HOME/.local/bin" \
  HOMELABCTL_ALLOW_ANY_DIR=1 \
  bash -c "$(curl -fsSL https://raw.githubusercontent.com/xooooooooox/homelabctl/main/install.sh)"
```

### Homebrew

```shell
brew tap xooooooooox/radp
brew install homelabctl
```

### RPM (Fedora/RHEL/CentOS via COPR)

```shell
# dnf
sudo dnf install -y dnf-plugins-core
sudo dnf copr enable -y xooooooooox/radp
sudo dnf install -y homelabctl

# yum
sudo yum install -y epel-release
sudo yum install -y yum-plugin-copr
sudo yum copr enable -y xooooooooox/radp
sudo yum install -y homelabctl
```

### OBS repository (dnf / yum / apt)

Replace `<DISTRO>` with the target distribution (e.g., `CentOS_7`, `openSUSE_Tumbleweed`, `xUbuntu_24.04`).

```shell
# CentOS/RHEL (yum)
sudo yum-config-manager --add-repo https://download.opensuse.org/repositories/home:/xooooooooox:/radp/ <DISTRO >/radp.repo
sudo yum install -y homelabctl

# Debian/Ubuntu (apt)
echo 'deb http://download.opensuse.org/repositories/home:/xooooooooox:/radp/<DISTRO>/ /' |
  sudo tee /etc/apt/sources.list.d/home:xooooooooox:radp.list
curl -fsSL https://download.opensuse.org/repositories/home:xooooooooox:radp/ <DISTRO >/Release.key | gpg --dearmor |
  sudo tee /etc/apt/trusted.gpg.d/home_xooooooooox_radp.gpg >/dev/null
sudo apt update
sudo apt install homelabctl

# Fedora/RHEL/CentOS (dnf)
sudo dnf config-manager --add-repo https://download.opensuse.org/repositories/home:/xooooooooox:/radp/ <DISTRO >/radp.repo
sudo dnf install -y homelabctl
```

## Usage

```shell
# Show help
homelabctl --help

# Show version
homelabctl version

# Vagrant passthrough
homelabctl vg up
homelabctl vg ssh

# Vagrant framework commands
homelabctl vf init
homelabctl vf info
homelabctl vf dump-config
homelabctl vf generate

# Generate shell completion
homelabctl completion bash >~/.local/share/bash-completion/completions/homelabctl
homelabctl completion zsh >~/.zfunc/_homelabctl

# Verbose mode (show banner and info logs)
homelabctl -v vf info
homelabctl --verbose vg status

# Debug mode (show banner, debug logs, and detailed output)
homelabctl --debug vf info
```

## Global Options

| Option            | Description                                |
|-------------------|--------------------------------------------|
| `-v`, `--verbose` | Enable verbose output (banner + info logs) |
| `--debug`         | Enable debug output (banner + debug logs)  |

By default, homelabctl runs in quiet mode (no banner, only error logs).

## Commands

| Command              | Description                             |
|----------------------|-----------------------------------------|
| `vg <cmd>`           | Vagrant command passthrough             |
| `vf init`            | Initialize a vagrant project            |
| `vf info`            | Show environment information            |
| `vf dump-config`     | Export merged configuration (JSON)      |
| `vf generate`        | Generate standalone Vagrantfile         |
| `vf version`         | Show radp-vagrant-framework version     |
| `version`            | Show homelabctl version                 |
| `completion <shell>` | Generate shell completion script        |

## Environment Variables

| Variable                  | Description                                        |
|---------------------------|----------------------------------------------------|
| `RADP_VF_HOME`            | Path to radp-vagrant-framework installation        |
| `RADP_VAGRANT_CONFIG_DIR` | Configuration directory path (default: `./config`) |
| `RADP_VAGRANT_ENV`        | Override environment name                          |

## CI/CD

This project includes GitHub Actions workflows for automated releases.

### Workflow Chain

```
release-prep (manual trigger)
       │
       ▼
   PR merged
       │
       ▼
create-version-tag
       │
       ├──────────────────────┬──────────────────────┐
       ▼                      ▼                      ▼
update-spec-version    update-homebrew-tap    (GitHub Release)
       │
       ├──────────────┐
       ▼              ▼
build-copr-package  build-obs-package
```

### Release Process

1. Trigger `release-prep` workflow with bump_type (patch/minor/major/manual)
2. Review and merge the generated PR
3. Subsequent workflows run automatically

### Required Secrets

Configure these secrets in your GitHub repository settings (`Settings > Secrets and variables > Actions`):

#### Homebrew Tap (required for `update-homebrew-tap`)

| Secret               | Description                                                                 |
|----------------------|-----------------------------------------------------------------------------|
| `HOMEBREW_TAP_TOKEN` | GitHub Personal Access Token with `repo` scope for homebrew-radp repository |

#### COPR (required for `build-copr-package`)

| Secret          | Description                                                    |
|-----------------|----------------------------------------------------------------|
| `COPR_LOGIN`    | COPR API login (from <https://copr.fedorainfracloud.org/api/>) |
| `COPR_TOKEN`    | COPR API token                                                 |
| `COPR_USERNAME` | COPR username                                                  |
| `COPR_PROJECT`  | COPR project name (e.g., `radp`)                               |

#### OBS (required for `build-obs-package`)

| Secret         | Description                                                    |
|----------------|----------------------------------------------------------------|
| `OBS_USERNAME` | OBS username                                                   |
| `OBS_PASSWORD` | OBS password or API token                                      |
| `OBS_PROJECT`  | OBS project name                                               |
| `OBS_PACKAGE`  | OBS package name                                               |
| `OBS_API_URL`  | (Optional) OBS API URL, defaults to `https://api.opensuse.org` |

### Skipping Workflows

If you don't need certain distribution channels:

- Delete the corresponding workflow file from `.github/workflows/`
- Or leave secrets unconfigured (workflow will skip with missing secrets)

## License

MIT
