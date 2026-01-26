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

### Homebrew

```shell
brew uninstall homelabctl
```

### DNF

```shell
sudo dnf remove homelabctl
```

### Manual

Remove the cloned directory and any PATH/completion configurations.

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
