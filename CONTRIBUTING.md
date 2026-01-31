# Contributing

## Development Setup

1. Clone the repository:

```shell
git clone https://github.com/xooooooooox/homelabctl.git
cd homelabctl
```

2. Ensure radp-bash-framework is installed and in PATH:

```shell
export PATH="/path/to/radp-bash-framework/src/main/shell/bin:$PATH"
```

3. Set radp-vagrant-framework home (for vf commands):

```shell
export RADP_VF_HOME="/path/to/radp-vagrant-framework"
```

4. Run homelabctl:

```shell
./bin/homelabctl --help
./bin/homelabctl vf info
```

## Project Structure

```
homelabctl/
├── bin/
│   └── homelabctl              # CLI entry point
├── completions/
│   ├── homelabctl.bash         # Bash completion
│   └── homelabctl.zsh          # Zsh completion
├── src/main/shell/
│   ├── commands/               # Command implementations
│   │   ├── vg.sh               # homelabctl vg <cmd>
│   │   ├── vf/                 # homelabctl vf <subcommand>
│   │   ├── setup/              # homelabctl setup <subcommand>
│   │   ├── version.sh          # Version command (contains version constant)
│   │   └── completion.sh
│   ├── config/
│   │   └── config.yaml         # YAML configuration
│   └── libs/                   # Project-specific libraries
│       └── setup/              # Setup feature libraries
│           ├── registry.yaml   # Package registry
│           ├── profiles/       # Profile definitions
│           └── installers/     # Package installers
├── docs/                       # Documentation
├── packaging/                  # Distribution packaging
└── install.sh                  # Universal installer
```

## Version Management

Version is stored in `src/main/shell/commands/version.sh`:

```bash
declare -gr gr_app_version="v0.1.0"
```

Available as `$gr_app_version` in shell. This is the single source of truth for release management.

## Adding Packages and Profiles

For detailed instructions on adding custom packages and profiles, see the [Setup Guide](docs/setup-guide.md):

- [Adding a Custom Package](docs/setup-guide.md#adding-a-custom-package)
- [Adding a Custom Profile](docs/setup-guide.md#adding-a-custom-profile)
- [Registry YAML Schema](docs/setup-guide.md#registry-yaml-schema)
- [Profile YAML Schema](docs/setup-guide.md#profile-yaml-schema)

### Quick Reference

**Package definition** (`src/main/shell/libs/setup/registry.yaml`):

```yaml
packages:
  my-tool:
    desc: "My tool description"
    category: utilities
    check-cmd: my-tool
```

**Installer** (`src/main/shell/libs/setup/installers/my-tool.sh`):

```bash
_setup_install_my_tool() {
  local version="${1:-}"
  # Platform-specific installation logic
}
```

**Profile** (`src/main/shell/libs/setup/profiles/my-profile.yaml`):

```yaml
name: my-profile
desc: "Profile description"
platform: any
packages:
  - name: fzf
  - name: bat
```

### Testing

```bash
# List packages
./bin/homelabctl setup list

# Show package info
./bin/homelabctl setup info fzf

# Dry-run installation
./bin/homelabctl setup install my-tool --dry-run

# Test profile
./bin/homelabctl setup profile show my-profile
./bin/homelabctl setup profile apply my-profile --dry-run
```

## Code Style

- Use `shellcheck` for shell script linting
- Follow existing naming conventions:
    - Command files: `commands/<cmd>.sh` or `commands/<group>/<subcmd>.sh`
    - Command functions: `cmd_<name>()` or `cmd_<group>_<subcmd>()`
    - Internal functions: prefix with `_` (e.g., `_setup_install_<name>`)
- Options accessed via: `$opt_<long_name>` (dashes converted to underscores)

## Release Process

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
       │              │
       └──────┬───────┘
              ▼
  attach-release-packages
```

### Steps

1. Trigger `release-prep` workflow with bump_type (patch/minor/major/manual)
2. Review and merge the generated PR
3. Subsequent workflows run automatically

## GitHub Actions Reference

| Workflow                      | Trigger            | Purpose                      |
|-------------------------------|--------------------|------------------------------|
| `release-prep.yml`            | Manual on `main`   | Create release branch and PR |
| `create-version-tag.yml`      | PR merge or manual | Validate and create git tag  |
| `update-spec-version.yml`     | After tag creation | Update spec Version field    |
| `build-copr-package.yml`      | After spec update  | Trigger COPR build           |
| `build-obs-package.yml`       | After spec update  | Sync to OBS and build        |
| `update-homebrew-tap.yml`     | Tag push           | Update Homebrew formula      |
| `attach-release-packages.yml` | Release published  | Upload packages to release   |

## Required Secrets

Configure these secrets in GitHub repository settings (`Settings > Secrets and variables > Actions`):

### Homebrew Tap

| Secret               | Description                                               |
|----------------------|-----------------------------------------------------------|
| `HOMEBREW_TAP_TOKEN` | GitHub PAT with `repo` scope for homebrew-radp repository |

### COPR

| Secret          | Description                                                  |
|-----------------|--------------------------------------------------------------|
| `COPR_LOGIN`    | COPR API login (from https://copr.fedorainfracloud.org/api/) |
| `COPR_TOKEN`    | COPR API token                                               |
| `COPR_USERNAME` | COPR username                                                |
| `COPR_PROJECT`  | COPR project name (e.g., `radp`)                             |

### OBS

| Secret         | Description                                                    |
|----------------|----------------------------------------------------------------|
| `OBS_USERNAME` | OBS username                                                   |
| `OBS_PASSWORD` | OBS password or API token                                      |
| `OBS_PROJECT`  | OBS project name                                               |
| `OBS_PACKAGE`  | OBS package name                                               |
| `OBS_API_URL`  | (Optional) OBS API URL, defaults to `https://api.opensuse.org` |

## Skipping Workflows

If you don't need certain distribution channels:

- Delete the corresponding workflow file from `.github/workflows/`
- Or leave secrets unconfigured (workflow will skip with missing secrets)
