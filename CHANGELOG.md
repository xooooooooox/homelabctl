# CHANGELOG

## v0.2.6

### feat

- Improve `init vf` command
  - Now uses passthrough mode to support all radp-vf options
  - Sets `RADP_VAGRANT_CONFIG_DIR` and `RADP_VAGRANT_ENV` from homelabctl config
  - Supports all radp-vf init options (--force, --dry-run, --template, --set)
- Improve `init all` command
  - Uses `RADP_VF_INIT_RESULT_FILE` to get the actual VF config directory
  - Displays accurate VF config path in summary
- Add `gitlab` command group for complete GitLab management
  - `gitlab install` - Install GitLab (CE/EE) via linux_package
  - `gitlab init` - Initialize GitLab after installation
  - `gitlab status` - Show GitLab status and version info
  - `gitlab healthcheck` - Run GitLab health checks
  - `gitlab start/stop/restart` - Service management
  - `gitlab reset-password` - Reset GitLab user password
  - `gitlab backup create` - Create data and/or config backup
  - `gitlab backup list` - List available backups
  - `gitlab backup cleanup` - Clean old backups
  - `gitlab restore` - Restore from backup
- Add `gitlab runner install` command - Install GitLab Runner
- Add `init` command group for user configuration initialization
  - `init setup` - Initialize setup user configuration directory
  - `init k8s` - Initialize k8s user configuration directory
  - `init all` - Initialize all user configuration directories
  - `init vf` - Initialize vagrant project (passthrough to radp-vf)
- Add `k8s` command group for complete Kubernetes management
  - `k8s health` - Check Kubernetes cluster health
  - `k8s install` - Install Kubernetes (kubeadm, kubelet, kubectl)
  - `k8s init master` - Initialize Kubernetes master node
  - `k8s init worker` - Initialize Kubernetes worker node
  - `k8s addon install` - Install a Kubernetes addon
  - `k8s addon uninstall` - Uninstall a Kubernetes addon
  - `k8s addon list` - List available Kubernetes addons
  - `k8s addon quickstart` - Install recommended addons
  - `k8s addon profile list` - List available addon profiles
  - `k8s addon profile show` - Show addon profile details
  - `k8s addon profile apply` - Apply an addon profile
  - `k8s token create` - Create a new join token
  - `k8s token get` - Get current valid token
  - `k8s backup create` - Create etcd backup
  - `k8s backup list` - List available etcd backups
  - `k8s backup restore` - Restore etcd from backup
- Add `setup configure docker` subcommands
  - `setup configure docker rootless` - Configure Docker for non-root user access
  - `setup configure docker acceleration` - Configure Docker proxy or registry mirrors
- Add `setup uninstall` command - Uninstall software packages with optional purge
- Add new installers
  - `containerd` - Container runtime for Kubernetes
  - `docker-compose` - Docker Compose plugin

### removed

- Remove `gitlab-runner` installer (migrated to `gitlab` command group)

### fix

- Fix potential `set -e` exit on `((var++))` when var is 0
  - Changed `((var++))` to `((++var))` in multiple files
  - Affected: `init/all.sh`, `k8s/addon/list.sh`, `k8s/addon/profile/list.sh`, `k8s/addon/_installer.sh`

## v0.1.32

### feat

- Support targeting VMs by cluster name via `vf vg` command (requires radp-vagrant-framework v0.2.22+)
  - `homelabctl vf vg up -C my-cluster` - start all VMs in a cluster
  - `homelabctl vf vg up -C my-cluster -G 1,2` - start specific guests in a cluster
  - `homelabctl vf vg up -C cluster1,cluster2` - multiple clusters
  - Shell completion for cluster names and guest IDs works automatically via delegation
- Add directory and file check support for `check-cmd` in registry
  - New syntax: `"dir:<path>"` to check if directory exists
  - New syntax: `"file:<path>"` to check if file exists
  - Supports `~` expansion (e.g., `"dir:~/.fzf-tab-completion"`)
  - Useful for packages installed as directories rather than commands
- Optimize generated completion script, sets local _RADP_VF_DELEGATED=1 before calling `_radp_vf`
- Add installer `tealder`
- Add platform dependency support for OS+architecture combinations (e.g., `linux-arm64`, `darwin-amd64`)
  - Lookup chain: `os-arch` → `os` → base (e.g., `linux-arm64` → `linux` → base)
  - Enables architecture-specific dependencies (e.g., `git-credential-manager` requires `dotnet-sdk` on Linux ARM64)
- Add `setup deps <name>` command to show package dependency tree
- Add `setup deps <name> --reverse` to show reverse dependencies
- Add installer: dotnet-sdk
- Add `setup configure` command group for system configuration tasks
  - `setup configure list` - Dynamically list available configurations from directory
  - `setup configure chrony` - Configure chrony for time synchronization
  - `setup configure expand-lvm` - Expand LVM partition and filesystem
  - `setup configure gpg-import` - Import GPG keys into user keyring
  - `setup configure gpg-preset` - Preset GPG passphrase in gpg-agent
  - `setup configure yadm` - Clone dotfiles repository using yadm
- All configure commands use framework's `radp_exec()` for cleaner dry-run support
- Configure commands use sudo for privileged operations (no need to run as root)
- Display accurate version info when installed via `--ref <branch>` or `--ref <sha>`
- Generate `.install-version` file during manual installation
- Use framework's `radp_get_install_version()` helper in banner
- Optimize package categories
- Optimize builtin profiles
- Add installer: pinentry, ansible, docker, eza, go, python, ripgrep, rust, starship, terraform
- Add installer: git, git-credential-manager, gpg, lazygit, markdownlint-cli, mvn, ohmyzsh, pass, shellcheck, tig, tmux,
  vim, yadm, zoxide
- Update entrypoint to use the latest bash framework
- Update completion help example
- Add global cli args

### fix

- Fix bash completion syntax error causing completion to fail
  - Change `vf *)` to `'vf '*)` in case pattern (space must be inside quotes)
  - Same fix for nested `vf vg *)` pattern
- Fix `fzf-tab-completion` showing as not installed even when `~/.fzf-tab-completion/` exists
  - Changed `check-cmd` to `"dir:~/.fzf-tab-completion"`
- Fix `ohmyzsh` showing as not installed when running from bash
  - Changed `check-cmd` from `omz` (zsh function) to `"dir:~/.oh-my-zsh"`
- Fix shell completions not auto-loading when installed via package manager (apt/dnf)
  - Add completion files to deb/rpm packages
  - Completions now installed to `/usr/share/bash-completion/completions/` and `/usr/share/zsh/site-functions/`
- Fix `setup deps` command not showing dependency tree due to `set -e` exit on `((count++))` when count is 0
- Fix `setup info --all-platforms` not showing all platform entries due to `set -e` exit
- Fix `setup list` showing no packages due to undefined `HOMELABCTL_ROOT` (should use `RADP_APP_ROOT`)
- Fix `version` and `vf info` commands showing inconsistent version with banner
- Fix tmux not working on CentOS Stream 9 due to missing perl dependency
- Fix zsh completion not showing package names for `setup install <tab>` (banner/log output was breaking completion)
- Fix apply.sh interrupt after package installed
- Fix vfox-installed SDKs not available in PATH for subsequent installers
  - Problem: `vfox use --global` requires hook support and doesn't work in non-interactive scripts
  - Solution: Add verification step after vfox operations to explicitly find and add SDK bin directory to PATH
  - Affected installers: nodejs.sh, jdk.sh, go.sh, python.sh, ruby.sh
- Improve `_setup_vfox_find_sdk_bin` to use `-executable` flag with fallback to `-perm /111` for better compatibility

### refactor

- Simplify command structure: consolidate `vf` and `vg` into single `vf` passthrough to radp-vf
  - `homelabctl vf <cmd>` now passes all arguments directly to `radp-vf`
  - Vagrant commands via `homelabctl vf vg <cmd>` (e.g., `vf vg up`, `vf vg status`)
  - Remove duplicate subcommand definitions (init, list, validate, etc.)
- Remove `homelabctl info` command, replaced by `homelabctl --config`
  - Use `--config` for core configuration (paths, settings, log)
  - Use `--config --all` to include extension configurations (vf settings, etc.)
  - Use `--config --json` or `--config --all --json` for JSON output
- Move version from `vars/constants.sh` to `config/config.yaml` (`radp.extend.homelabctl.version`)
- Remove `vars` directory, add `config/_ide.sh` for IDE code completion support

### chore

- Optimize install and uninstall script

### docs

- Update install doc
- Introduce how to add user installer
- Update README.md and CLAUDE.md
- Update installation
- Update CLAUDE
- Update README

## v0.0.17

### feat

- Enhance setup commands with dynamic shell completions
- Add shell completion helper functions for setup commands
- Enhance shell completions with dynamic suggestions
- Add setup commands for profile and package management
- Regenerate completion scripts before create PR
- Add rebuild zsh completion cache instructions
- Optimize brew formula to support install completion
- Add shell completion file for bash and zsh
- Split `vf template` command into dedicated `list` and `show` subcommands
- Add template support to `vf init` and new `vf template` command for managing project templates
- Add auto-detection of RADP_VF_HOME and improve Vagrantfile path resolution
- Improve CLI argument handling for vf list and homelabctl commands
- Add support for package manager detection and installation options in install script
- Enhance vf list command with verbose mode, filtering, and additional display options
- Add vf list and vf validate commands with environment override support
- Add format and output options to vf dump-config command for enhanced flexibility
- Enhance vf shell commands with improved CLI argument handling, version display, and environment overrides
- Add global option parsing for homelabctl with verbose and debug modes
- Add Homebrew formula reference in CLAUDE.md and update default version
- Add Homebrew formula for homelabctl to streamline installation
- Add vg and vf subcmd for radp-vagrant-framework
- Add GitHub workflows for release and package builds
- Init project

### fix

- Subshell problem
- Default user config path
- Setup cmd
- Ensure #compdef is first line for zsh completion
- Vg cmd
- Handle empty args in homelabctl by adding safeguards and help output
- Handle initial release in release-prep workflow
- Update version constant to v0.0.1

### chore

- Optimize install.sh
- Use latest release of radp-bash-framework
- Debug workflow
- Ensure all shell scripts use consistent shebang (`#!/usr/bin/env bash`)
- Simplify formula update logic in Homebrew tap workflow
- Default disable banner-mode
- Format doc

### docs

- Add badges
- Expand CONTRIBUTING.md with setup feature details
- Update CLAUDE.md with detailed setup feature documentation
- Update README and README_CN with revamped structure and feature details
- Add IDE code completion reference for shell scripts
- Update README with enhanced structure and detailed feature list
- Add detailed guides for configuration, installation, and contribution
- Refine CLAUDE.md to detail `vf template list` and `vf template show` subcommands
- Update CLAUDE.md to include `vf template` command and enhancements to `vf init`
- Update CLAUDE.md with vf list and vf validate command details
- Update README to document new CLI options and commands
- Update CLAUDE.md with vf/vg enhancements and environment setup details
- Expand README with environment variables, installation methods, and CI/CD workflows

### refactor

- Simplify and modernize shell completion scripts for dynamic completions
- Move installer script to project root and update references

### other

- Install radp-bash-framework from main branch for latest fixes before release
- Format code
- Initial commit
