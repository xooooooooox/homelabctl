# homelabctl

```
    __                         __      __         __  __
   / /_  ____  ____ ___  ___  / /___ _/ /_  _____/ /_/ /
  / __ \/ __ \/ __ `__ \/ _ \/ / __ `/ __ \/ ___/ __/ /
 / / / / /_/ / / / / / /  __/ / /_/ / /_/ / /__/ /_/ /
/_/ /_/\____/_/ /_/ /_/\___/_/\__,_/_.___/\___/\__/_/


```

基于 [radp-bash-framework](https://github.com/xooooooooox/radp-bash-framework) 构建的 homelab 基础设施管理 CLI 工具。

## 特性

- **Vagrant 集成** - 透传 Vagrant 命令，自动检测 Vagrantfile
- **RADP Vagrant Framework** - 初始化、配置和管理多虚拟机环境
- **模板系统** - 从预定义模板创建项目（`k8s-cluster`、`single-node` 等）
- **Shell 补全** - 支持 Bash 和 Zsh 补全
- **Verbose/Debug 模式** - 可配置的输出级别，便于问题排查

## 前置要求

homelabctl 需要安装 radp-bash-framework：

```shell
brew tap xooooooooox/radp
brew install radp-bash-framework
```

或参考：https://github.com/xooooooooox/radp-bash-framework#installation

## 安装

### Homebrew（推荐）

```shell
brew tap xooooooooox/radp
brew install homelabctl
```

### 脚本安装 (curl)

```shell
curl -fsSL https://raw.githubusercontent.com/xooooooooox/homelabctl/main/install.sh | bash
```

### RPM (Fedora/RHEL/CentOS)

```shell
sudo dnf copr enable -y xooooooooox/radp
sudo dnf install -y homelabctl
```

更多安装选项（OBS、手动安装、升级）请参阅[安装指南](docs/installation.md)。

## 使用方法

```shell
# 显示帮助
homelabctl --help

# Vagrant 命令透传
homelabctl vg up
homelabctl vg ssh
homelabctl vg status

# Vagrant 框架命令
homelabctl vf init myproject
homelabctl vf init myproject --template k8s-cluster
homelabctl vf list
homelabctl vf info
homelabctl vf dump-config

# Shell 补全
homelabctl completion bash >~/.local/share/bash-completion/completions/homelabctl
homelabctl completion zsh >~/.zfunc/_homelabctl

# Verbose/Debug 模式
homelabctl -v vf info # Verbose 输出
homelabctl --debug vg up # Debug 输出
```

## 命令

| 命令                   | 描述               |
|----------------------|------------------|
| `vg <cmd>`           | Vagrant 命令透传     |
| `vf init [dir]`      | 初始化 Vagrant 项目   |
| `vf list`            | 列出集群和虚拟机         |
| `vf info`            | 显示环境信息           |
| `vf validate`        | 验证 YAML 配置       |
| `vf dump-config`     | 导出合并后的配置         |
| `vf generate`        | 生成独立 Vagrantfile |
| `vf template list`   | 列出可用模板           |
| `vf template show`   | 显示模板详情           |
| `version`            | 显示 homelabctl 版本 |
| `completion <shell>` | 生成 Shell 补全脚本    |

## 全局选项

| 选项                | 描述                           |
|-------------------|------------------------------|
| `-v`, `--verbose` | 启用详细输出（显示 banner 和 info 日志）  |
| `--debug`         | 启用调试输出（显示 banner 和 debug 日志） |

默认情况下，homelabctl 以静默模式运行（无 banner，仅显示错误日志）。

## 环境变量

| 变量                        | 描述                          |
|---------------------------|-----------------------------|
| `RADP_VF_HOME`            | radp-vagrant-framework 安装路径 |
| `RADP_VAGRANT_CONFIG_DIR` | 配置目录路径（默认：`./config`）       |
| `RADP_VAGRANT_ENV`        | 覆盖环境名称                      |

## 文档

- [安装指南](docs/installation.md) - 完整安装选项、升级、Shell 补全
- [配置说明](docs/configuration.md) - YAML 配置系统

Vagrant
虚拟机配置请参阅 [radp-vagrant-framework 配置参考](https://github.com/xooooooooox/radp-vagrant-framework/blob/main/docs/configuration-reference.md)。

## 贡献

开发设置和发布流程请参阅 [CONTRIBUTING.md](CONTRIBUTING.md)。

## 许可证

[MIT](LICENSE)
