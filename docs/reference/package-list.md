# Package List

Available packages for `homelabctl setup install`.

## Categories

| Category | Description |
|----------|-------------|
| system | System utilities |
| shell | Shell and terminal |
| editors | Text editors |
| languages | Programming languages |
| devops | DevOps and cloud tools |
| vcs | Version control |
| security | Security tools |
| search | Search and find tools |
| dev-tools | Development tools |
| utilities | General utilities |

## Packages by Category

### system

| Package | Description |
|---------|-------------|
| gnu-getopt | GNU getopt for macOS |

### shell

| Package | Description |
|---------|-------------|
| zsh | Z shell |
| ohmyzsh | Oh My Zsh framework |
| starship | Cross-shell prompt |
| tmux | Terminal multiplexer |
| fzf-tab-completion | FZF tab completion |

### editors

| Package | Description |
|---------|-------------|
| neovim | Hyperextensible Vim-based editor |
| vim | Vi improved |

### languages

| Package | Description |
|---------|-------------|
| nodejs | Node.js JavaScript runtime |
| jdk | Java Development Kit |
| go | Go programming language |
| python | Python interpreter |
| ruby | Ruby programming language |
| rust | Rust programming language |

### devops

| Package | Description |
|---------|-------------|
| docker | Container runtime |
| kubectl | Kubernetes CLI |
| kubecm | Kubernetes context manager |
| helm | Kubernetes package manager |
| terraform | Infrastructure as code |
| ansible | IT automation |
| vagrant | Development environments |
| jenkins | CI/CD automation server |

### vcs

| Package | Description |
|---------|-------------|
| git | Distributed version control |
| git-credential-manager | Cross-platform Git credential storage |
| tig | Text-mode interface for Git |
| lazygit | Terminal UI for Git |
| yadm | Yet Another Dotfiles Manager |

### security

| Package | Description |
|---------|-------------|
| gpg | GNU Privacy Guard |
| pass | Password manager |
| pinentry | GnuPG PIN entry |

### search

| Package | Description |
|---------|-------------|
| fzf | Fuzzy finder |
| ripgrep | Fast grep alternative |
| fd | Fast find alternative |
| zoxide | Smarter cd command |

### dev-tools

| Package | Description |
|---------|-------------|
| jq | JSON processor |
| bat | Cat with syntax highlighting |
| eza | Modern ls replacement |
| shellcheck | Shell script analyzer |
| glow | Render Markdown on the CLI |
| markdownlint-cli | Markdown linter |
| vfox | Cross-platform version manager |

### utilities

| Package | Description |
|---------|-------------|
| fastfetch | System information tool |
| homebrew | macOS package manager |
| mc | Midnight Commander file manager |
| mvn | Apache Maven build tool |

## Dependencies

Some packages have dependencies that are auto-installed:

| Package | Requires |
|---------|----------|
| markdownlint-cli | nodejs |
| ohmyzsh | zsh |
| fzf-tab-completion | fzf |
| pass | gpg |
| git-credential-manager | git |
| jenkins | jdk |

## Platform Notes

- **macOS**: Most packages use Homebrew
- **Linux**: Uses native package managers (dnf/apt) or binary releases
- **vfox**: Used for language runtimes (nodejs, jdk, go, python, ruby)

## Viewing Package Info

```shell
# List all packages
homelabctl setup list

# List by category
homelabctl setup list -c languages

# Show package details
homelabctl setup info nodejs

# Show dependency tree
homelabctl setup deps markdownlint-cli
```

## See Also

- [Setup Guide](../user-guide/setup-guide.md) - How to use setup
- [Adding Packages](../developer/adding-packages.md) - Add custom packages
