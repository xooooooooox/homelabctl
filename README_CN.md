# homelabctl

```
    __                         __      __         __  __
   / /_  ____  ____ ___  ___  / /___ _/ /_  _____/ /_/ /
  / __ \/ __ \/ __ `__ \/ _ \/ / __ `/ __ \/ ___/ __/ /
 / / / / /_/ / / / / / /  __/ / /_/ / /_/ / /__/ /_/ /
/_/ /_/\____/_/ /_/ /_/\___/_/\__,_/_.___/\___/\__/_/


```

[![Copr build status](https://copr.fedorainfracloud.org/coprs/xooooooooox/radp/package/homelabctl/status_image/last_build.png)](https://copr.fedorainfracloud.org/coprs/xooooooooox/radp/package/radp-bash-framework/)
[![OBS package build status](https://build.opensuse.org/projects/home:xooooooooox:radp/packages/homelabctl/badge.svg)](https://build.opensuse.org/package/show/home:xooooooooox:radp/radp-bash-framework)
[![CI: COPR](https://img.shields.io/github/actions/workflow/status/xooooooooox/homelabctl/build-copr-package.yml?label=CI%3A%20COPR)](https://github.com/xooooooooox/radp-bash-framework/actions/workflows/build-copr-package.yml)
[![CI: OBS](https://img.shields.io/github/actions/workflow/status/xooooooooox/homelabctl/build-obs-package.yml?label=CI%3A%20OBS)](https://github.com/xooooooooox/radp-bash-framework/actions/workflows/build-obs-package.yml)
[![CI: Homebrew](https://img.shields.io/github/actions/workflow/status/xooooooooox/homelabctl/update-homebrew-tap.yml?label=Homebrew%20tap)](https://github.com/xooooooooox/radp-bash-framework/actions/workflows/update-homebrew-tap.yml)

[![COPR packages](https://img.shields.io/badge/COPR-packages-4b8bbe)](https://download.copr.fedorainfracloud.org/results/xooooooooox/radp/)
[![OBS packages](https://img.shields.io/badge/OBS-packages-4b8bbe)](https://software.opensuse.org//download.html?project=home%3Axooooooooox%3Aradp&package=radp-bash-framework)

基于 [radp-bash-framework](https://github.com/xooooooooox/radp-bash-framework) 构建的 homelab 基础设施管理 CLI 工具。

## 特性

- **Vagrant 集成** - 透传 Vagrant 命令，自动检测 Vagrantfile
- **RADP Vagrant Framework** - 初始化、配置和管理多虚拟机环境
- **软件安装** - 跨平台安装 CLI 工具、编程语言和 DevOps 工具，支持配置文件批量安装
- **Shell 补全** - 支持 Bash 和 Zsh 补全，包含软件包和配置文件的动态补全

## 安装

### 快速安装

```shell
curl -fsSL https://raw.githubusercontent.com/xooooooooox/homelabctl/main/install.sh | bash
```

安装脚本会自动安装依赖、homelabctl，并配置 shell 补全。

### Homebrew (macOS/Linux)

```shell
brew tap xooooooooox/radp
brew install homelabctl
```

### RPM (Fedora/RHEL/CentOS)

```shell
sudo dnf copr enable -y xooooooooox/radp
sudo dnf install -y radp-bash-framework homelabctl
```

更多安装选项请参阅[安装指南](docs/installation.md)。

## 快速开始

```shell
# 显示帮助
homelabctl --help

# 安装开发工具
homelabctl setup install fzf
homelabctl setup profile apply recommend

# 管理 Vagrant 虚拟机
homelabctl vf init myproject --template k8s-cluster
homelabctl vg up
```

## 命令

### Vagrant 集成 (vg, vf)

管理 Vagrant 虚拟机，支持自动 Vagrantfile 检测和多虚拟机配置。

| 命令                 | 描述               |
|--------------------|------------------|
| `vg <cmd>`         | Vagrant 命令透传     |
| `vf init [dir]`    | 初始化 Vagrant 项目   |
| `vf list`          | 列出集群和虚拟机         |
| `vf info`          | 显示环境信息           |
| `vf validate`      | 验证 YAML 配置       |
| `vf dump-config`   | 导出合并后的配置         |
| `vf generate`      | 生成独立 Vagrantfile |
| `vf template list` | 列出可用模板           |
| `vf template show` | 显示模板详情           |
| `vf version`       | 显示框架版本           |

**示例：**

```shell
# Vagrant 命令透传
homelabctl vg up
homelabctl vg ssh
homelabctl vg status

# 从模板初始化项目
homelabctl vf init myproject
homelabctl vf init myproject --template k8s-cluster

# 查看配置
homelabctl vf list
homelabctl vf info
homelabctl vf dump-config -f yaml
```

**环境变量：**

| 变量                        | 描述                          |
|---------------------------|-----------------------------|
| `RADP_VF_HOME`            | radp-vagrant-framework 安装路径 |
| `RADP_VAGRANT_CONFIG_DIR` | 配置目录路径（默认：`./config`）       |
| `RADP_VAGRANT_ENV`        | 覆盖环境名称                      |

虚拟机配置详情请参阅 [radp-vagrant-framework 配置参考](https://github.com/xooooooooox/radp-vagrant-framework/blob/main/docs/configuration-reference.md)。

### 软件安装 (setup)

跨平台安装和管理软件包。支持单独安装和通过配置文件批量安装。

| 命令                             | 描述                    |
|--------------------------------|-----------------------|
| `setup list`                   | 列出可用软件包               |
| `setup info <name>`            | 显示软件包详情               |
| `setup install <name>`         | 安装软件包                 |
| `setup profile list`           | 列出可用配置文件              |
| `setup profile show <name>`    | 显示配置文件详情              |
| `setup profile apply <name>`   | 应用配置文件                |
| `setup configure list`         | 列出可用系统配置              |
| `setup configure chrony`       | 配置 chrony 时间同步        |
| `setup configure expand-lvm`   | 扩展 LVM 分区和文件系统        |
| `setup configure gpg-import`   | 导入 GPG 密钥到用户密钥环       |
| `setup configure gpg-preset`   | 在 gpg-agent 中预设 GPG 密码 |
| `setup configure yadm`         | 使用 yadm 克隆 dotfiles 仓库 |

**示例：**

```shell
# 列出和搜索软件包
homelabctl setup list
homelabctl setup list -c cli-tools
homelabctl setup list --installed

# 安装软件包
homelabctl setup install fzf
homelabctl setup install nodejs -v 20
homelabctl setup install jdk -v 17

# 使用配置文件
homelabctl setup profile list
homelabctl setup profile show recommend
homelabctl setup profile apply recommend --dry-run
homelabctl setup profile apply recommend --continue

# 系统配置
homelabctl setup configure list
homelabctl setup configure chrony --servers "ntp.aliyun.com" --timezone "Asia/Shanghai"
homelabctl setup configure expand-lvm
homelabctl setup configure gpg-import --secret-key-file ~/.secrets/key.asc --passphrase-file ~/.secrets/pass.txt
homelabctl setup configure gpg-preset --key-uid "user@example.com" --passphrase-file ~/.secrets/pass.txt
homelabctl setup configure yadm --repo-url "git@github.com:user/dotfiles.git" --ssh-key-file ~/.ssh/id_rsa --bootstrap
```

**可用分类：**

- **system** - 系统前置工具 (homebrew, gnu-getopt)
- **shell** - Shell 和终端 (zsh, tmux, ohmyzsh, starship, zoxide)
- **editors** - 文本编辑器 (vim, neovim)
- **languages** - 编程语言 (nodejs, jdk, python, go, rust, ruby, vfox, mvn)
- **devops** - DevOps 工具 (kubectl, helm, kubecm, vagrant, docker, terraform, ansible)
- **vcs** - 版本控制 (git, lazygit, tig, git-credential-manager, yadm)
- **security** - 安全工具 (gpg, pinentry, pass)
- **search** - 搜索工具 (fzf, fd, ripgrep, bat, eza)
- **dev-tools** - 开发工具 (jq, shellcheck, markdownlint-cli)
- **utilities** - 系统工具 (mc, fastfetch)

**内置配置文件：**

| 配置文件        | 描述                 |
|-------------|--------------------|
| `recommend` | 推荐的开发环境基础工具集 |

**系统配置：**

`setup configure` 命令提供即用型的系统配置任务：

| 命令            | 描述                               |
|---------------|----------------------------------|
| `chrony`      | 配置 NTP 时间同步，支持自定义服务器             |
| `expand-lvm`  | 扩展 LVM 分区和文件系统以使用所有可用磁盘空间        |
| `gpg-import`  | 从文件、内容或密钥服务器导入 GPG 密钥            |
| `gpg-preset`  | 在 gpg-agent 中缓存 GPG 密码，用于非交互式操作  |
| `yadm`        | 克隆 dotfiles 仓库，支持 SSH/HTTPS、bootstrap、解密 |

所有 configure 命令支持 `--dry-run` 预览更改。运行 `homelabctl setup configure <name> --help` 查看详细选项。

**用户扩展：**

在 `~/.config/homelabctl/setup/` 添加自定义软件包和配置文件：

```
~/.config/homelabctl/setup/
├── registry.yaml      # 自定义软件包定义
├── profiles/          # 自定义配置文件
│   └── my-profile.yaml
└── installers/        # 自定义安装器
    └── my-tool.sh
```

用户文件优先级高于内置文件。

**添加自定义软件包：**

1. 在 `~/.config/homelabctl/setup/registry.yaml` 中定义：

```yaml
packages:
  my-tool:
    desc: "我的自定义工具"
    category: utilities
    check-cmd: my-tool         # 用于验证安装的命令
    homepage: https://example.com
```

2. 在 `~/.config/homelabctl/setup/installers/my-tool.sh` 创建安装器：

```bash
#!/usr/bin/env bash
_setup_install_my_tool() {
    local version="${1:-latest}"
    local pm
    pm=$(radp_os_get_distro_pm 2>/dev/null || echo "unknown")

    case "$pm" in
    brew)   brew install my-tool ;;
    dnf)    sudo dnf install -y my-tool ;;
    apt)    sudo apt-get install -y my-tool ;;
    *)      radp_log_error "不支持的平台"; return 1 ;;
    esac
}
```

**添加自定义配置文件：**

创建 `~/.config/homelabctl/setup/profiles/my-profile.yaml`：

```yaml
name: my-profile
desc: "我的自定义配置"
platform: any              # any, darwin, linux

packages:
  - name: fzf
  - name: bat
  - name: my-tool
    version: "1.0.0"       # 可选：指定版本
```

然后应用：`homelabctl setup profile apply my-profile`

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
homelabctl completion bash > ~/.local/share/bash-completion/completions/homelabctl

# Zsh
mkdir -p ~/.zfunc
homelabctl completion zsh > ~/.zfunc/_homelabctl
# 添加到 ~/.zshrc: fpath=(~/.zfunc $fpath)
```

补全功能包含软件包名称、配置文件名称和分类的动态建议。

## 文档

- [安装指南](docs/installation.md) - 完整安装选项、升级、Shell 补全
- [配置说明](docs/configuration.md) - YAML 配置系统

## 贡献

开发设置和发布流程请参阅 [CONTRIBUTING.md](CONTRIBUTING.md)。

## 许可证

[MIT](LICENSE)
