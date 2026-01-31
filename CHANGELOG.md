# CHANGELOG

## v0.1.15

### feat

- Add installer: gitlab-runner
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
- Add installer: git, git-credential-manager, gpg, lazygit, markdownlint-cli, mvn, ohmyzsh, pass, shellcheck, tig, tmux, vim, yadm, zoxide
- Update entrypoint to use the latest bash framework
- Update completion help example
- Add global cli args

### fix

- Fix `setup list` showing no packages due to undefined `HOMELABCTL_ROOT` (should use `RADP_APP_ROOT`)
- Fix `version` and `vf info` commands showing inconsistent version with banner
- Fix tmux not working on CentOS Stream 9 due to missing perl dependency
- Fix zsh completion not showing package names for `setup install <tab>` (banner/log output was breaking completion)
- Fix apply.sh interrupt after package installed
- Fix installer.sh

### refactor

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
