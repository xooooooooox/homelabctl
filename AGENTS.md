# AGENTS.md

Guidelines for multi-agent collaboration when working on homelabctl.

## Project Overview

homelabctl is a CLI tool for managing homelab infrastructure, built on radp-bash-framework. It provides software package installation and Vagrant VM management via radp-vagrant-framework passthrough.

## Agent Roles

### Code Agent

Handles Shell code modifications:

- **Commands**: `src/main/shell/commands/`
- **Libraries**: `src/main/shell/libs/setup/`
- **Installers**: `src/main/shell/libs/setup/installers/`

### Config Agent

Handles configuration and registry:

- **Framework config**: `src/main/shell/config/config.yaml`
- **Package registry**: `src/main/shell/libs/setup/registry.yaml`
- **Profiles**: `src/main/shell/libs/setup/profiles/`

### Test Agent

Handles testing:

- Run commands manually: `./bin/homelabctl <command>`
- Test installers: `homelabctl setup install <pkg> --dry-run`

### Docs Agent

Handles documentation:

- **User docs**: `docs/`
- **Developer docs**: `docs/developer/`
- **Reference docs**: `docs/reference/`

## Key Conventions

### Command Definition

```bash
# @cmd
# @desc Command description
# @arg name! Required argument
# @option -v, --version <ver> Version option
cmd_setup_install() {
    local name="${args_name}"
    local version="${opt_version:-latest}"
}
```

### Naming

| Type | Convention | Example |
|------|------------|---------|
| Command files | snake_case | `install.sh` |
| Command functions | `cmd_<name>` | `cmd_setup_install` |
| Installer functions | `_setup_install_<name>` | `_setup_install_fzf` |
| Options | `opt_<name>` | `$opt_version` |

## File Ownership

| Path | Owner | Notes |
|------|-------|-------|
| `src/main/shell/commands/` | Code Agent | Command implementations |
| `src/main/shell/libs/setup/` | Code Agent | Setup libraries |
| `src/main/shell/libs/setup/registry.yaml` | Config Agent | Package definitions |
| `src/main/shell/libs/setup/profiles/` | Config Agent | Profile definitions |
| `docs/` | Docs Agent | Documentation |
| `completions/` | Code Agent | Shell completions |

## Coordination Rules

1. **New package**: Add to registry.yaml AND create installer
2. **New command**: Follow annotation pattern, update completions
3. **Profile changes**: Update profile YAML
4. **Breaking changes**: Update CHANGELOG.md

## Common Tasks

### Adding a Package

1. Add to `libs/setup/registry.yaml`:
   ```yaml
   packages:
     my-tool:
       desc: My tool
       category: utilities
   ```
2. Create `libs/setup/installers/my-tool.sh`
3. Update docs: `docs/reference/package-list.md`

### Adding a Profile

1. Create `libs/setup/profiles/my-profile.yaml`
2. Update docs if needed

### Adding a Configure Command

1. Create `commands/setup/configure/my-config.sh`
2. Use `@cmd`, `@desc` annotations
3. Update `docs/reference/cli-reference.md`

### Updating Completions

```bash
./bin/homelabctl completion bash > completions/homelabctl.bash
./bin/homelabctl completion zsh > completions/homelabctl.zsh
```

## See Also

- [CLAUDE.md](./CLAUDE.md) - AI assistant guidelines
- [Architecture](docs/developer/architecture.md) - Detailed architecture
- [Adding Packages](docs/developer/adding-packages.md) - Package guide
