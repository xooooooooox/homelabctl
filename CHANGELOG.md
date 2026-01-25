# CHANGELOG

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
