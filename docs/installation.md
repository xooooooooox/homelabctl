# Installation Guide

## Requirements

Before installing homelabctl, ensure you have:

- **Bash 4.0+** - Required for associative arrays and other features
    - macOS ships with Bash 3.x; install newer version: `brew install bash`
    - Linux distributions typically have Bash 4.x or 5.x
- **Git** - Required for manual installation
- **curl or wget** - Required for script installation

The install script will automatically install **radp-bash-framework** as a dependency.

## Quick Install

The easiest way to install homelabctl:

```shell
curl -fsSL https://raw.githubusercontent.com/xooooooooox/homelabctl/main/install.sh | bash
```

The install script automatically:

- Detects your package manager (Homebrew, dnf, apt, etc.)
- Installs radp-bash-framework dependency
- Installs homelabctl
- Configures shell completion for your shell (bash/zsh)

## Installation Methods

### Homebrew (macOS) - Recommended

```shell
brew tap xooooooooox/radp
brew install homelabctl
```

Note: This also installs radp-bash-framework as a dependency.

### Script (curl/wget)

```shell
# Using curl
curl -fsSL https://raw.githubusercontent.com/xooooooooox/homelabctl/main/install.sh | bash

# Using wget
wget -qO- https://raw.githubusercontent.com/xooooooooox/homelabctl/main/install.sh | bash
```

#### Script Options

```shell
# Install from a specific branch or tag
bash install.sh --ref main
bash install.sh --ref v0.2.0-rc1

# Force manual installation (download from GitHub)
bash install.sh --mode manual

# Force specific package manager
bash install.sh --mode dnf
bash install.sh --mode homebrew

# With curl pipe
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
sudo dnf install -y radp-bash-framework homelabctl
```

**Via OBS (openSUSE Build Service):**

```shell
# Fedora
sudo dnf config-manager --add-repo https://download.opensuse.org/repositories/home:/xooooooooox:/radp/Fedora_$(rpm -E %fedora)/home:xooooooooox:radp.repo
sudo dnf install -y radp-bash-framework homelabctl

# openSUSE
sudo zypper addrepo https://download.opensuse.org/repositories/home:/xooooooooox:/radp/openSUSE_Tumbleweed/home:xooooooooox:radp.repo
sudo zypper install radp-bash-framework homelabctl
```

### Debian/Ubuntu

```shell
# Add OBS repository (replace with your Ubuntu/Debian version)
echo "deb http://download.opensuse.org/repositories/home:/xooooooooox:/radp/xUbuntu_22.04/ /" |
  sudo tee /etc/apt/sources.list.d/home:xooooooooox:radp.list
curl -fsSL https://download.opensuse.org/repositories/home:xooooooooox:radp/xUbuntu_22.04/Release.key | gpg --dearmor |
  sudo tee /etc/apt/trusted.gpg.d/home_xooooooooox_radp.gpg >/dev/null
sudo apt update
sudo apt install radp-bash-framework homelabctl
```

### Manual Installation (Git Clone)

```shell
git clone https://github.com/xooooooooox/homelabctl.git
cd homelabctl

# Add to PATH
export PATH="$PWD/bin:$PATH"

# Also need radp-bash-framework
git clone https://github.com/xooooooooox/radp-bash-framework.git
export PATH="$PWD/../radp-bash-framework/src/main/shell/bin:$PATH"
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

# Remove completions
rm -f ~/.local/share/bash-completion/completions/homelabctl
rm -f ~/.zfunc/_homelabctl
```

## Shell Completion

Shell completion is **automatically configured** during installation. If you need to regenerate or manually configure:

### Bash

```shell
# Ensure bash-completion is installed
# macOS: brew install bash-completion@2
# Fedora/RHEL: sudo dnf install bash-completion
# Debian/Ubuntu: sudo apt install bash-completion

# Create directory and generate completion
mkdir -p ~/.local/share/bash-completion/completions
homelabctl completion bash >~/.local/share/bash-completion/completions/homelabctl
```

### Zsh

```shell
# Create directory and generate completion
mkdir -p ~/.zfunc
homelabctl completion zsh >~/.zfunc/_homelabctl

# Add to ~/.zshrc if not already present:
# fpath=(~/.zfunc $fpath)
# autoload -Uz compinit && compinit
```

Completions include dynamic suggestions for package names, profile names, and categories.

## Troubleshooting

### "bash: homelabctl: command not found"

Ensure the installation directory is in your PATH:

```shell
# For manual installation
export PATH="$HOME/.local/bin:$PATH"

# Add to ~/.bashrc or ~/.zshrc
echo 'export PATH="$HOME/.local/bin:$PATH"' >>~/.bashrc
```

### "homelabctl: line X: declare: -A: invalid option"

This error indicates Bash 3.x is being used. homelabctl requires Bash 4.0+.

**macOS fix:**

```shell
# Install newer Bash
brew install bash

# Verify version
/opt/homebrew/bin/bash --version # Apple Silicon
/usr/local/bin/bash --version # Intel

# Option 1: Run homelabctl with Homebrew's bash
/opt/homebrew/bin/bash -c 'homelabctl --help'

# Option 2: Add Homebrew's bash to /etc/shells and change default shell
sudo bash -c 'echo /opt/homebrew/bin/bash >> /etc/shells'
chsh -s /opt/homebrew/bin/bash
```

### "radp: command not found" or framework errors

The radp-bash-framework dependency is missing or not in PATH.

**Reinstall with package manager:**

```shell
# Homebrew
brew reinstall radp-bash-framework

# DNF
sudo dnf reinstall radp-bash-framework
```

**Manual installation check:**

```shell
# Check if framework is installed
ls ~/.local/lib/radp-bash-framework

# Add to PATH if missing
export PATH="$HOME/.local/lib/radp-bash-framework/src/main/shell/bin:$PATH"
```

### Shell completion not working

**Bash:**

```shell
# Ensure bash-completion is installed and loaded
brew install bash-completion@2 # macOS
source /opt/homebrew/etc/profile.d/bash_completion.sh

# Regenerate completion
homelabctl completion bash >~/.local/share/bash-completion/completions/homelabctl
```

**Zsh:**

```shell
# Regenerate completion
homelabctl completion zsh >~/.zfunc/_homelabctl

# Rebuild completion cache
rm -f ~/.zcompdump*
compinit
```

### radp-vf not found (for vf/vg commands)

The `vf` and `vg` commands require radp-vagrant-framework to be installed:

```shell
# Option 1: Install via Homebrew (recommended)
brew tap xooooooooox/radp
brew install radp-vagrant-framework

# Option 2: Install via script
curl -fsSL https://raw.githubusercontent.com/xooooooooox/radp-vagrant-framework/main/install.sh | bash

# Option 3: Manual installation - add bin to PATH
git clone https://github.com/xooooooooox/radp-vagrant-framework.git
export PATH="$PWD/radp-vagrant-framework/bin:$PATH"
echo 'export PATH="/path/to/radp-vagrant-framework/bin:$PATH"' >> ~/.bashrc
```

For `vf` commands, you can alternatively set `RADP_VF_HOME`:

```shell
export RADP_VF_HOME="/path/to/radp-vagrant-framework"
```

See [Vagrant Guide](vagrant-guide.md) for more details.

### Package installation fails

If `homelabctl setup install` fails:

```shell
# Check if command exists (for already installed packages)
which <package-name>

# Try with verbose output
homelabctl setup install <package> --verbose

# Try dry-run first
homelabctl setup install <package> --dry-run
```

For platform-specific issues, check the [Setup Guide](setup-guide.md#platform-support).
