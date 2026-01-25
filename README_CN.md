# homelabctl

```
    __                         __      __         __  __
   / /_  ____  ____ ___  ___  / /___ _/ /_  _____/ /_/ /
  / __ \/ __ \/ __ `__ \/ _ \/ / __ `/ __ \/ ___/ __/ /
 / / / / /_/ / / / / / /  __/ / /_/ / /_/ / /__/ /_/ /
/_/ /_/\____/_/ /_/ /_/\___/_/\__,_/_.___/\___/\__/_/


```

基于 [radp-bash-framework](https://github.com/xooooooooox/radp-bash-framework) 构建的 homelab 基础设施管理 CLI 工具。

## 前置要求

homelabctl 需要安装 radp-bash-framework：

```shell
brew tap xooooooooox/radp
brew install radp-bash-framework
```

或参考：https://github.com/xooooooooox/radp-bash-framework#installation

## 安装

### 脚本安装 (curl / wget / fetch)

```shell
curl -fsSL https://raw.githubusercontent.com/xooooooooox/homelabctl/main/install.sh | bash
```

或：

```shell
wget -qO- https://raw.githubusercontent.com/xooooooooox/homelabctl/main/install.sh | bash
```

可选环境变量：

```shell
HOMELABCTL_VERSION=vX.Y.Z \
  HOMELABCTL_REF=main \
  HOMELABCTL_INSTALL_DIR="$HOME/.local/lib/homelabctl" \
  HOMELABCTL_BIN_DIR="$HOME/.local/bin" \
  HOMELABCTL_ALLOW_ANY_DIR=1 \
  bash -c "$(curl -fsSL https://raw.githubusercontent.com/xooooooooox/homelabctl/main/install.sh)"
```

### Homebrew

```shell
brew tap xooooooooox/radp
brew install homelabctl
```

### RPM (Fedora/RHEL/CentOS via COPR)

```shell
# dnf
sudo dnf install -y dnf-plugins-core
sudo dnf copr enable -y xooooooooox/radp
sudo dnf install -y homelabctl

# yum
sudo yum install -y epel-release
sudo yum install -y yum-plugin-copr
sudo yum copr enable -y xooooooooox/radp
sudo yum install -y homelabctl
```

### OBS 仓库 (dnf / yum / apt)

将 `<DISTRO>` 替换为目标发行版（如 `CentOS_7`、`openSUSE_Tumbleweed`、`xUbuntu_24.04`）。

```shell
# CentOS/RHEL (yum)
sudo yum-config-manager --add-repo https://download.opensuse.org/repositories/home:/xooooooooox:/radp/ <DISTRO >/radp.repo
sudo yum install -y homelabctl

# Debian/Ubuntu (apt)
echo 'deb http://download.opensuse.org/repositories/home:/xooooooooox:/radp/<DISTRO>/ /' |
  sudo tee /etc/apt/sources.list.d/home:xooooooooox:radp.list
curl -fsSL https://download.opensuse.org/repositories/home:xooooooooox:radp/ <DISTRO >/Release.key | gpg --dearmor |
  sudo tee /etc/apt/trusted.gpg.d/home_xooooooooox_radp.gpg >/dev/null
sudo apt update
sudo apt install homelabctl

# Fedora/RHEL/CentOS (dnf)
sudo dnf config-manager --add-repo https://download.opensuse.org/repositories/home:/xooooooooox:/radp/ <DISTRO >/radp.repo
sudo dnf install -y homelabctl
```

## 使用方法

```shell
# 显示帮助
homelabctl --help

# 显示版本
homelabctl version

# Vagrant 命令透传
homelabctl vg up
homelabctl vg ssh

# Vagrant 框架命令
homelabctl vf init
homelabctl vf info
homelabctl vf dump-config
homelabctl vf generate

# 生成 Shell 补全脚本
homelabctl completion bash >~/.local/share/bash-completion/completions/homelabctl
homelabctl completion zsh >~/.zfunc/_homelabctl

# Verbose 模式（显示 banner 和 info 日志）
homelabctl -v vf info
homelabctl --verbose vg status

# Debug 模式（显示 banner、debug 日志和详细输出）
homelabctl --debug vf info
```

## 全局选项

| 选项                | 描述                           |
|-------------------|------------------------------|
| `-v`, `--verbose` | 启用详细输出（显示 banner 和 info 日志）  |
| `--debug`         | 启用调试输出（显示 banner 和 debug 日志） |

默认情况下，homelabctl 以静默模式运行（无 banner，仅显示错误日志）。

## 命令

| 命令                   | 描述                            |
|----------------------|-------------------------------|
| `vg <cmd>`           | Vagrant 命令透传                  |
| `vf init`            | 初始化 Vagrant 项目                |
| `vf info`            | 显示环境信息                        |
| `vf dump-config`     | 导出合并后的配置（JSON 格式）             |
| `vf generate`        | 生成独立的 Vagrantfile             |
| `vf version`         | 显示 radp-vagrant-framework 版本  |
| `version`            | 显示 homelabctl 版本              |
| `completion <shell>` | 生成 Shell 补全脚本                 |

## 环境变量

| 变量                        | 描述                          |
|---------------------------|-----------------------------|
| `RADP_VF_HOME`            | radp-vagrant-framework 安装路径 |
| `RADP_VAGRANT_CONFIG_DIR` | 配置目录路径（默认：`./config`）       |
| `RADP_VAGRANT_ENV`        | 覆盖环境名称                      |

## CI/CD

本项目包含用于自动发布的 GitHub Actions workflows。

### Workflow 链

```
release-prep (手动触发)
       │
       ▼
   PR 合并
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
```

### 发布流程

1. 触发 `release-prep` workflow，选择 bump_type（patch/minor/major/manual）
2. 审核并合并生成的 PR
3. 后续 workflows 自动串联运行

### 必需的 Secrets

在 GitHub 仓库设置中配置这些 secrets（`Settings > Secrets and variables > Actions`）：

#### Homebrew Tap（用于 `update-homebrew-tap`）

| Secret               | 描述                                                               |
|----------------------|------------------------------------------------------------------|
| `HOMEBREW_TAP_TOKEN` | 具有 `repo` 权限的 GitHub Personal Access Token，用于访问 homebrew-radp 仓库 |

#### COPR（用于 `build-copr-package`）

| Secret          | 描述                                                            |
|-----------------|---------------------------------------------------------------|
| `COPR_LOGIN`    | COPR API login（从 <https://copr.fedorainfracloud.org/api/> 获取） |
| `COPR_TOKEN`    | COPR API token                                                |
| `COPR_USERNAME` | COPR 用户名                                                      |
| `COPR_PROJECT`  | COPR 项目名（如 `radp`）                                            |

#### OBS（用于 `build-obs-package`）

| Secret         | 描述                                             |
|----------------|------------------------------------------------|
| `OBS_USERNAME` | OBS 用户名                                        |
| `OBS_PASSWORD` | OBS 密码或 API token                              |
| `OBS_PROJECT`  | OBS 项目名                                        |
| `OBS_PACKAGE`  | OBS 包名                                         |
| `OBS_API_URL`  | （可选）OBS API URL，默认为 `https://api.opensuse.org` |

### 跳过 Workflows

如果不需要某些分发渠道：

- 删除 `.github/workflows/` 中对应的 workflow 文件
- 或不配置相关 secrets（workflow 会因缺少 secrets 而跳过）

## 许可证

MIT
