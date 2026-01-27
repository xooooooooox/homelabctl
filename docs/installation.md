# Installation Guide

## Prerequisites

homelabctl requires radp-bash-framework to be installed:

```shell
brew tap xooooooooox/radp
brew install radp-bash-framework
```

Or see: https://github.com/xooooooooox/radp-bash-framework#installation

## Installation Methods

### Homebrew (macOS/Linux)

```shell
brew tap xooooooooox/radp
brew install homelabctl
```

### Script (curl)

```shell
curl -fsSL https://raw.githubusercontent.com/xooooooooox/homelabctl/main/install.sh | bash
```

Or with wget:

```shell
wget -qO- https://raw.githubusercontent.com/xooooooooox/homelabctl/main/install.sh | bash
```

#### Script Options

```shell
bash install.sh --ref main
bash install.sh --ref v0.2.0-rc1
bash install.sh --mode manual
bash install.sh --mode dnf

curl -fsSL https://raw.githubusercontent.com/xooooooooox/homelabctl/main/install.sh | bash -s -- --ref main
```

| Option              | Description                                                              | Default                   |
|---------------------|--------------------------------------------------------------------------|---------------------------|
| `--ref <ref>`       | Install from a git ref (branch, tag, SHA). Implies manual install.       | latest release            |
| `--mode <mode>`     | `auto`, `manual`, or specific: `homebrew`, `dnf`, `yum`, `apt`, `zypper` | `auto`                    |
| `--install-dir <d>` | Manual install location                                                  | `~/.local/lib/homelabctl` |
| `--bin-dir <d>`     | Symlink location                                                         | `~/.local/bin`            |

Environment variables (`HOMELABCTL_REF`, `HOMELABCTL_VERSION`, `HOMELABCTL_INSTALL_MODE`, `HOMELABCTL_INSTALL_DIR`,
`HOMELABCTL_BIN_DIR`) are also supported as fallbacks.

When `--ref` is used and a package-manager version is already installed, the script automatically removes it first to
avoid conflicts.

### RPM (Fedora/RHEL/CentOS)

**Via COPR:**

```shell
sudo dnf copr enable -y xooooooooox/radp
sudo dnf install -y homelabctl
```

**Via OBS (openSUSE Build Service):**

```shell
# Fedora
sudo dnf config-manager --add-repo https://download.opensuse.org/repositories/home:/xooooooooox:/radp/Fedora_$(rpm -E %fedora)/home:xooooooooox:radp.repo
sudo dnf install -y homelabctl

# openSUSE
sudo zypper addrepo https://download.opensuse.org/repositories/home:/xooooooooox:/radp/openSUSE_Tumbleweed/home:xooooooooox:radp.repo
sudo zypper install homelabctl
```

### Manual Installation

```shell
git clone https://github.com/xooooooooox/homelabctl.git
cd homelabctl

# Add to PATH
export PATH="$PWD/bin:$PATH"

# Optionally install completions
cp completions/homelabctl.bash ~/.local/share/bash-completion/completions/homelabctl
cp completions/homelabctl.zsh ~/.zfunc/_homelabctl
```

## Verification

```shell
homelabctl version
homelabctl --help
```

## Upgrading

### Homebrew

```shell
brew upgrade homelabctl
```

### DNF (COPR)

```shell
sudo dnf upgrade homelabctl
```

### Script

Re-run the installation script:

```shell
curl -fsSL https://raw.githubusercontent.com/xooooooooox/homelabctl/main/install.sh | bash
```

## Uninstalling

### Uninstall Script (Recommended)

```shell
bash uninstall.sh
bash uninstall.sh --yes # Skip confirmation
bash uninstall.sh --deps --yes # Also remove radp-bash-framework
```

The script auto-detects both package-manager and manual installations and removes them.

| Option   | Description                        |
|----------|------------------------------------|
| `--deps` | Also uninstall radp-bash-framework |
| `--yes`  | Skip confirmation prompt           |

### Homebrew

```shell
brew uninstall homelabctl
```

### DNF

```shell
sudo dnf remove homelabctl
```

### Manual

Remove the install directory and symlink:

```shell
rm -rf ~/.local/lib/homelabctl
rm -f ~/.local/bin/homelabctl
```

## Shell Completion

### Bash

```shell
homelabctl completion bash >~/.local/share/bash-completion/completions/homelabctl
```

### Zsh

```shell
homelabctl completion zsh >~/.zfunc/_homelabctl
# Add to ~/.zshrc: fpath=(~/.zfunc $fpath)
```
