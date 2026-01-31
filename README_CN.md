# homelabctl

```
    __                         __      __         __  __
   / /_  ____  ____ ___  ___  / /___ _/ /_  _____/ /_/ /
  / __ \/ __ \/ __ `__ \/ _ \/ / __ `/ __ \/ ___/ __/ /
 / / / / /_/ / / / / / /  __/ / /_/ / /_/ / /__/ /_/ /
/_/ /_/\____/_/ /_/ /_/\___/_/\__,_/_.___/\___/\__/_/


```

[![GitHub Release](https://img.shields.io/github/v/release/xooooooooox/homelabctl?label=Release)](https://github.com/xooooooooox/homelabctl/releases)
[![Copr build status](https://copr.fedorainfracloud.org/coprs/xooooooooox/radp/package/homelabctl/status_image/last_build.png)](https://copr.fedorainfracloud.org/coprs/xooooooooox/radp/package/radp-bash-framework/)
[![OBS package build status](https://build.opensuse.org/projects/home:xooooooooox:radp/packages/homelabctl/badge.svg)](https://build.opensuse.org/package/show/home:xooooooooox:radp/radp-bash-framework)

[![CI: COPR](https://img.shields.io/github/actions/workflow/status/xooooooooox/homelabctl/build-copr-package.yml?label=CI%3A%20COPR)](https://github.com/xooooooooox/radp-bash-framework/actions/workflows/build-copr-package.yml)
[![CI: OBS](https://img.shields.io/github/actions/workflow/status/xooooooooox/homelabctl/build-obs-package.yml?label=CI%3A%20OBS)](https://github.com/xooooooooox/radp-bash-framework/actions/workflows/build-obs-package.yml)
[![CI: Homebrew](https://img.shields.io/github/actions/workflow/status/xooooooooox/homelabctl/update-homebrew-tap.yml?label=Homebrew%20tap)](https://github.com/xooooooooox/radp-bash-framework/actions/workflows/update-homebrew-tap.yml)

[![COPR packages](https://img.shields.io/badge/COPR-packages-4b8bbe)](https://download.copr.fedorainfracloud.org/results/xooooooooox/radp/)
[![OBS packages](https://img.shields.io/badge/OBS-packages-4b8bbe)](https://software.opensuse.org//download.html?project=home%3Axooooooooox%3Aradp&package=radp-bash-framework)

基于 [radp-bash-framework](https://github.com/xooooooooox/radp-bash-framework) 构建的 homelab 基础设施管理 CLI 工具。

## 目录

- [特性](#特性)
- [系统要求](#系统要求)
- [支持的平台](#支持的平台)
- [安装](#安装)
- [快速开始](#快速开始)
- [命令](#命令)
- [全局选项](#全局选项)
- [Shell 补全](#shell-补全)
- [文档](#文档)
- [贡献](#贡献)

## 特性

- **Vagrant 集成** - 透传 Vagrant 命令，自动检测 Vagrantfile
- **RADP Vagrant Framework** - 初始化、配置和管理多虚拟机环境
- **软件安装** - 跨平台安装 40+ CLI 工具、编程语言和 DevOps 工具
- **配置文件** - 通过配置文件批量安装软件包，实现环境可复现
- **Shell 补全** - 支持 Bash 和 Zsh 补全，提供动态建议

## 系统要求

- **Bash** 4.0+ (macOS 用户: `brew install bash`)
- **Git** (手动安装时需要)
- **radp-bash-framework** (安装脚本会自动安装)

## 支持的平台

| 操作系统               | 架构                    | 包管理器           | 备注                        |
|--------------------|-----------------------|----------------|---------------------------|
| macOS              | Intel (x86_64)        | Homebrew       | 需要 Homebrew 安装的 `bash`    |
| macOS              | Apple Silicon (arm64) | Homebrew       | 需要 Homebrew 安装的 `bash`    |
| Fedora/RHEL/CentOS | x86_64, aarch64       | DNF/YUM (COPR) | RHEL 8+, Fedora 38+       |
| Ubuntu/Debian      | amd64, arm64          | APT (OBS)      | Ubuntu 20.04+, Debian 11+ |
| openSUSE           | x86_64                | Zypper (OBS)   | Tumbleweed, Leap 15.4+    |

## 安装

### 快速安装

```shell
curl -fsSL https://raw.githubusercontent.com/xooooooooox/homelabctl/main/install.sh | bash
```

### Homebrew (macOS)

```shell
brew tap xooooooooox/radp
brew install homelabctl
```

### RPM (Fedora/RHEL/CentOS)

```shell
sudo dnf copr enable -y xooooooooox/radp
sudo dnf install -y radp-bash-framework homelabctl
```

更多安装选项请参阅[安装指南](docs/installation.md)，包括 Debian/Ubuntu、手动安装和升级。

## 快速开始

```shell
# 显示帮助
homelabctl --help

# 安装开发工具
homelabctl setup install fzf
homelabctl setup install nodejs -v 20
homelabctl setup profile apply recommend

# 管理 Vagrant 虚拟机（需要 radp-vagrant-framework）
homelabctl vf init myproject --template k8s-cluster
homelabctl vg up
```

## 命令

### Vagrant 集成 (vg, vf)

| 命令                      | 描述               |
|-------------------------|------------------|
| `vg <cmd>`              | Vagrant 命令透传     |
| `vf init [dir]`         | 初始化 Vagrant 项目   |
| `vf list`               | 列出集群和虚拟机         |
| `vf info`               | 显示环境信息           |
| `vf validate`           | 验证 YAML 配置       |
| `vf dump-config`        | 导出合并后的配置         |
| `vf generate`           | 生成独立 Vagrantfile |
| `vf template list/show` | 列出或显示模板          |
| `vf version`            | 显示框架版本           |

需要安装 [radp-vagrant-framework](https://github.com/xooooooooox/radp-vagrant-framework)。详情请参阅 [Vagrant 指南](docs/vagrant-guide.md)。

### 软件安装 (setup)

| 命令                           | 描述       |
|------------------------------|----------|
| `setup list`                 | 列出可用软件包  |
| `setup info <name>`          | 显示软件包详情  |
| `setup deps <name>`          | 显示依赖树    |
| `setup install <name>`       | 安装软件包    |
| `setup profile list`         | 列出可用配置文件 |
| `setup profile show <name>`  | 显示配置文件详情 |
| `setup profile apply <name>` | 应用配置文件   |
| `setup configure list`       | 列出系统配置   |
| `setup configure <name>`     | 运行配置任务   |

**可用分类：** system, shell, editors, languages, devops, vcs, security, search, dev-tools, utilities

**系统配置：** chrony, expand-lvm, gpg-import, gpg-preset, yadm

详细架构、完整软件包列表和自定义扩展请参阅 [Setup 指南](docs/setup-guide.md)。

## 全局选项

| 选项                | 描述                           |
|-------------------|------------------------------|
| `-v`, `--verbose` | 启用详细输出（显示 banner 和 info 日志）  |
| `--debug`         | 启用调试输出（显示 banner 和 debug 日志） |
| `-h`, `--help`    | 显示帮助                         |
| `--version`       | 显示版本                         |

默认情况下，homelabctl 以静默模式运行（无 banner，仅显示错误日志）。

## Shell 补全

Shell 补全会在安装时自动配置。如需手动重新生成：

```shell
# Bash
mkdir -p ~/.local/share/bash-completion/completions
homelabctl completion bash >~/.local/share/bash-completion/completions/homelabctl

# Zsh
mkdir -p ~/.zfunc
homelabctl completion zsh >~/.zfunc/_homelabctl
```

## 文档

- [安装指南](docs/installation.md) - 完整安装选项、升级、卸载
- [Setup 指南](docs/setup-guide.md) - 软件包安装、配置文件、自定义扩展
- [Vagrant 指南](docs/vagrant-guide.md) - 虚拟机管理、模板、配置
- [配置说明](docs/configuration.md) - YAML 配置系统

## 贡献

开发设置、添加软件包和发布流程请参阅 [CONTRIBUTING.md](CONTRIBUTING.md)。

## 许可证

[MIT](LICENSE)
