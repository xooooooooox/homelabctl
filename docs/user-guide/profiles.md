# Profiles

Profiles let you install multiple packages at once for reproducible environments.

## Using Profiles

### List Available Profiles

```shell
homelabctl setup profile list
```

### Show Profile Details

```shell
homelabctl setup profile show recommend
```

### Apply a Profile

```shell
# Preview what will be installed
homelabctl setup profile apply recommend --dry-run

# Apply the profile
homelabctl setup profile apply recommend

# Continue on errors
homelabctl setup profile apply recommend --continue

# Skip already installed packages
homelabctl setup profile apply recommend --skip-installed
```

## Profile Options

| Option | Description |
|--------|-------------|
| `--dry-run` | Preview without installing |
| `--continue` | Continue on errors |
| `--skip-installed` | Skip already installed packages |
| `--no-deps` | Skip dependencies |

## Built-in Profiles

### recommend

A recommended set of CLI tools for development:

- Shell: zsh, ohmyzsh, starship, tmux
- Search: fzf, ripgrep, fd, zoxide
- Tools: bat, eza, jq, neovim
- VCS: git, lazygit, tig

## Creating Custom Profiles

Create profile files in `~/.config/homelabctl/setup/profiles/`:

### Profile YAML Schema

```yaml
name: my-profile
desc: My custom development environment
platform: any              # any | linux | darwin

packages:
  - name: git
  - name: fzf
  - name: nodejs
    version: "20"          # Optional: specific version
  - name: jdk
    version: "17"
```

### Platform Constraint

| Value | Description |
|-------|-------------|
| `any` | All platforms (default) |
| `linux` | Linux only |
| `darwin` | macOS only |

### Example: Web Development Profile

```yaml
# ~/.config/homelabctl/setup/profiles/webdev.yaml
name: webdev
desc: Web development environment
platform: any

packages:
  - name: nodejs
    version: "20"
  - name: git
  - name: fzf
  - name: ripgrep
  - name: jq
  - name: bat
```

### Example: DevOps Profile

```yaml
# ~/.config/homelabctl/setup/profiles/devops.yaml
name: devops
desc: DevOps tools
platform: linux

packages:
  - name: docker
  - name: kubectl
  - name: helm
  - name: terraform
  - name: ansible
```

## Profile Discovery

Profiles are discovered from:

1. `~/.config/homelabctl/setup/profiles/` (user profiles)
2. `$RADP_APP_ROOT/src/main/shell/libs/setup/profiles/` (builtin profiles)

User profiles with the same name override builtin profiles.

## See Also

- [Setup Guide](setup-guide.md) - Package installation details
- [Package List](../reference/package-list.md) - Available packages
