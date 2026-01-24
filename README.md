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
curl -fsSL https://raw.githubusercontent.com/xooooooooox/homelabctl/main/tools/install.sh | bash
```

Or:

```shell
wget -qO- https://raw.githubusercontent.com/xooooooooox/homelabctl/main/tools/install.sh | bash
```

Optional variables:

```shell
HOMELABCTL_VERSION=vX.Y.Z \
  HOMELABCTL_REF=main \
  HOMELABCTL_INSTALL_DIR="$HOME/.local/lib/homelabctl" \
  HOMELABCTL_BIN_DIR="$HOME/.local/bin" \
  HOMELABCTL_ALLOW_ANY_DIR=1 \
  bash -c "$(curl -fsSL https://raw.githubusercontent.com/xooooooooox/homelabctl/main/tools/install.sh)"
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
homelabctl completion bash >~/.bash_completion.d/homelabctl
homelabctl completion zsh >~/.zfunc/_homelabctl
```

## Commands

| Command              | Description                      |
|----------------------|----------------------------------|
| `vg <cmd>`           | Vagrant command passthrough      |
| `vf init`            | Initialize a vagrant project     |
| `vf info`            | Show environment information     |
| `vf dump-config`     | Export merged configuration      |
| `vf generate`        | Generate standalone Vagrantfile  |
| `version`            | Show homelabctl version          |
| `completion <shell>` | Generate shell completion script |

## License

MIT
