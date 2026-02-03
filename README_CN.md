# homelabctl

```
    __                         __      __         __  __
   / /_  ____  ____ ___  ___  / /___ _/ /_  _____/ /_/ /
  / __ \/ __ \/ __ `__ \/ _ \/ / __ `/ __ \/ ___/ __/ /
 / / / / /_/ / / / / / /  __/ / /_/ / /_/ / /__/ /_/ /
/_/ /_/\____/_/ /_/ /_/\___/_/\__,_/_.___/\___/\__/_/


```

[![GitHub Release](https://img.shields.io/github/v/release/xooooooooox/homelabctl?label=Release)](https://github.com/xooooooooox/homelabctl/releases)

基于 [radp-bash-framework](https://github.com/xooooooooox/radp-bash-framework) 构建的 homelab 基础设施管理 CLI 工具。

## 特性

- **软件安装** - 跨平台安装 40+ CLI 工具、编程语言和 DevOps 工具
- **配置文件** - 通过 Profile 批量安装软件包
- **Vagrant 集成** - 通过 radp-vagrant-framework 管理虚拟机

## 安装

```shell
# Homebrew (macOS)
brew tap xooooooooox/radp
brew install homelabctl

# 快速安装
curl -fsSL https://raw.githubusercontent.com/xooooooooox/homelabctl/main/install.sh | bash
```

## 快速开始

```shell
# 安装开发工具
homelabctl setup install fzf
homelabctl setup install nodejs -v 20
homelabctl setup profile apply recommend

# 管理 Vagrant 虚拟机
homelabctl vf init myproject --template k8s-cluster
homelabctl vf vg up -C my-cluster
```

## 命令

### 软件安装 (setup)

```shell
homelabctl setup list                    # 列出可用软件包
homelabctl setup info <name>             # 显示软件包详情
homelabctl setup install <name>          # 安装软件包
homelabctl setup profile apply <name>    # 应用配置文件
homelabctl setup configure <name>        # 运行系统配置
```

### Vagrant 集成 (vf)

```shell
homelabctl vf vg status                  # 查看虚拟机状态
homelabctl vf vg up -C my-cluster        # 启动集群
homelabctl vf init myproject             # 初始化项目
```

## 文档

详细文档请参阅英文版：

- [Getting Started](docs/getting-started.md) - 快速开始
- [Installation](docs/installation.md) - 安装指南
- [Setup Guide](docs/user-guide/setup-guide.md) - 软件安装指南
- [Vagrant Guide](docs/user-guide/vagrant-guide.md) - Vagrant 指南
- [CLI Reference](docs/reference/cli-reference.md) - CLI 参考

## 相关项目

- [radp-bash-framework](https://github.com/xooooooooox/radp-bash-framework) - Bash CLI 框架（依赖）
- [radp-vagrant-framework](https://github.com/xooooooooox/radp-vagrant-framework) - YAML 驱动的 Vagrant 框架

## 许可证

[MIT](LICENSE)
