# Adding Packages

This guide explains how to add new packages to homelabctl's setup feature.

## Overview

Adding a package requires two files:
1. **Registry entry** - Package metadata in `registry.yaml`
2. **Installer script** - Installation logic in `installers/<name>.sh`

## Adding a Builtin Package

### 1. Add Registry Entry

Edit `src/main/shell/libs/setup/registry.yaml`:

```yaml
packages:
  my-tool:
    desc: My awesome tool
    category: dev-tools
    check-cmd: my-tool              # Command to check if installed
    homepage: https://example.com   # Optional
    requires: git                   # Optional: dependencies
```

### 2. Create Installer

Create `src/main/shell/libs/setup/installers/my-tool.sh`:

```bash
#!/usr/bin/env bash
_setup_install_my_tool() {
    local version="${1:-latest}"

    # Skip if already installed
    if _setup_is_installed my-tool && [[ "$version" == "latest" ]]; then
        radp_log_info "my-tool is already installed"
        return 0
    fi

    # Detect platform
    local pm
    pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

    case "$pm" in
        brew)
            brew install my-tool
            ;;
        dnf|yum)
            sudo dnf install -y my-tool
            ;;
        apt)
            sudo apt-get install -y my-tool
            ;;
        *)
            # Binary fallback from GitHub
            local arch os
            arch=$(_setup_get_arch)
            os=$(_setup_get_os)

            local url="https://github.com/example/my-tool/releases/latest/download/my-tool-${os}-${arch}"
            curl -fsSL "$url" -o /tmp/my-tool
            _setup_install_binary /tmp/my-tool my-tool
            ;;
    esac
}
```

## Adding a User Package

Users can add custom packages in `~/.config/homelabctl/setup/`:

### 1. Create User Registry

```yaml
# ~/.config/homelabctl/setup/registry.yaml
packages:
  my-custom-tool:
    desc: My custom tool
    category: utilities
    check-cmd: my-custom-tool
    requires: git nodejs
```

### 2. Create User Installer

```bash
# ~/.config/homelabctl/setup/installers/my-custom-tool.sh
_setup_install_my_custom_tool() {
    local version="${1:-latest}"
    # Installation logic
}
```

## Registry Schema

```yaml
packages:
  <name>:
    # Required
    desc: <string>                 # Short description
    category: <category>           # Must match defined category

    # Optional
    check-cmd: <spec>              # How to check if installed
                                   # Formats:
                                   #   <command>     - command -v check
                                   #   dir:<path>    - directory exists
                                   #   file:<path>   - file exists
    homepage: <url>                # Project URL

    # Dependencies
    requires: <pkg1> <pkg2>        # Auto-installed before target
    recommends: <pkg1> <pkg2>      # Shown as hint after install
    conflicts: <pkg1> <pkg2>       # Blocks install if present

    # Platform-specific
    platform:
      linux:
        requires: <pkg>            # Appends to base requires
      darwin:
        recommends: "!pkg"         # Replaces base recommends
```

## Install Strategy Priority

1. **Version manager** (vfox) - For language runtimes
2. **Native package manager** - brew, dnf, apt
3. **Binary release** - GitHub Releases / CDN
4. **Source build** - Last resort

## Helper Functions

| Function | Description |
|----------|-------------|
| `_setup_is_installed <cmd>` | Check if command exists |
| `_setup_get_arch` | Get architecture (amd64, arm64) |
| `_setup_get_os` | Get OS (linux, darwin) |
| `_setup_install_binary <src> <name>` | Copy binary to /usr/local/bin |
| `_setup_vfox_refresh_path` | Refresh PATH after vfox install |

## Testing

```bash
# List packages (verify registry)
homelabctl setup list

# Show package info
homelabctl setup info my-tool

# Dry run
homelabctl setup install my-tool --dry-run

# Install
homelabctl setup install my-tool
```

## See Also

- [Architecture](architecture.md) - Internal architecture
- [Package List](../reference/package-list.md) - Existing packages
