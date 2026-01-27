# CHANGELOG

## v0.0.17 - 2026-01-27

### chore
- 286eee3 customize banner

## v0.0.16 - 2026-01-27

### fix
- 27b85a4 subshell problem

### chore
- 44eca29 Optimize install.sh
- a1891be Optimize install.sh

### docs
- 826cee9 Add badges

## v0.0.15 - 2026-01-27

### fix
- 023cb47 default user config path

## v0.0.14 - 2026-01-27

### fix
- 1d3afb4 setup cmd
- 5b4f704 setup cmd
- 918cebb setup cmd

## v0.0.13 - 2026-01-27

### fix
- 85aecbe setup cmd

## v0.0.12 - 2026-01-26

- TODO: no commits found; add summary manually.

## v0.0.11 - 2026-01-26

### fix
- f3de509 ensure #compdef is first line for zsh completion

## v0.0.10 - 2026-01-26

### fix
- f0c4e98 ensure #compdef is first line for zsh completion

## v0.0.9 - 2026-01-26

### fix
- 2f0f772 vg cmd

### chore
- a2159b4 use latest release of radp-bash-framework

## v0.0.8 - 2026-01-26

### feat
- c64adb0 enhance setup commands with dynamic shell completions
- e5f85b2 add shell completion helper functions for setup commands
- 9c3a2e7 enhance shell completions with dynamic suggestions
- 116d590 add setup commands for profile and package management

### chore
- 140402c debug workflow
- 1f36b0f debug workflow

### docs
- f356135 expand CONTRIBUTING.md with setup feature details
- 05f5453 update CLAUDE.md with detailed setup feature documentation
- bdf01da update README and README_CN with revamped structure and feature details
- dc89581 add IDE code completion reference for shell scripts

### refactor
- 6906d07 simplify and modernize shell completion scripts for dynamic completions

### other
- 5134856 install radp-bash-framework from main branch for latest fixes before release
- 34aa5e3 format code

## v0.0.7 - 2026-01-26

### docs
- a8104fc update README with enhanced structure and detailed feature list
- 9a40423 add detailed guides for configuration, installation, and contribution

## v0.0.6 - 2026-01-26

### feat
- fa1a1c6 regenerate completion scripts before create PR
- 48b77d1 Add rebuild zsh completion cache instructions

## v0.0.5 - 2026-01-26

### feat
- c04259b Optimize brew formula to support install completion
- a359ece Add shell completion file for bash and zsh

### other
- 363da95 docs; Update CLAUDE.md

## v0.0.4 - 2026-01-25

### docs
- aeb5110 refine CLAUDE.md to detail `vf template list` and `vf template show` subcommands

### refactor
- 3f2632c split `vf template` command into dedicated `list` and `show` subcommands

## v0.0.3 - 2026-01-25

### feat
- f4a0dc7 add template support to `vf init` and new `vf template` command for managing project templates

### docs
- 955d4d3 update CLAUDE.md to include `vf template` command and enhancements to `vf init`

## v0.0.2 - 2026-01-25

### feat
- e06791b add auto-detection of RADP_VF_HOME and improve Vagrantfile path resolution

## v0.0.1 - 2026-01-25

### feat
- 559fb37 improve CLI argument handling for vf list and homelabctl commands
- 4d8c5d1 add support for package manager detection and installation options in install script
- 9081bcc enhance vf list command with verbose mode, filtering, and additional display options
- a607ace add vf list and vf validate commands with environment override support
- 32934cd add format and output options to vf dump-config command for enhanced flexibility
- 8a5d2c1 enhance vf shell commands with improved CLI argument handling, version display, and environment overrides
- a4364df add global option parsing for homelabctl with verbose and debug modes
- d830a78 add Homebrew formula reference in CLAUDE.md and update default version
- f9606f4 add Homebrew formula for homelabctl to streamline installation
- e9e73ed Add vg and vf subcmd for radp-vagrant-framework
- d9cde44 add GitHub workflows for release and package builds
- 87484de init project
- dd9b286 init project

### fix
- 4c117bb handle empty args in homelabctl by adding safeguards and help output
- aec9c81 handle initial release in release-prep workflow
- 2ff9904 update version constant to v0.0.1

### chore
- 61647a3 ensure all shell scripts use consistent shebang (`#!/usr/bin/env bash`)
- 6d67e55 simplify formula update logic in Homebrew tap workflow
- 15078b4 default disable banner-mode
- d53794b format doc

### docs
- 5385cf5 update CLAUDE.md to reflect new vf list options (verbose, provisions, synced-folders, triggers)
- 93023a6 update CLAUDE.md with vf list and vf validate command details
- e368dd9 update README and README_CN with verbose and debug mode details
- 2d77c94 expand README with environment variables, installation methods, and CI/CD workflows
- 062f48e update CLAUDE.md with vf/vg enhancements and environment setup details

### refactor
- 267699f move installer script to project root and update references

### other
- 4999d84 Initial commit
