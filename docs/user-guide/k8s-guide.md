# Kubernetes Guide

The `k8s` command group provides complete Kubernetes cluster management for homelab environments. It supports kubeadm-based installation, cluster initialization, addon management, backup/restore operations, and token management.

## Table of Contents

- [Quick Start](#quick-start)
- [Installation](#installation)
- [Cluster Initialization](#cluster-initialization)
- [Addon Management](#addon-management)
- [Backup and Restore](#backup-and-restore)
- [Token Management](#token-management)
- [Configuration Reference](#configuration-reference)

## Quick Start

```shell
# Install Kubernetes components
homelabctl k8s install

# Initialize master node
homelabctl k8s init master -a 192.168.1.100

# Check cluster health
homelabctl k8s health

# Install recommended addons
homelabctl k8s addon quickstart

# Create etcd backup
homelabctl k8s backup create
```

## Installation

### Basic Installation

Install Kubernetes with kubeadm (default):

```shell
homelabctl k8s install
```

### Specific Version

Install a specific Kubernetes version:

```shell
homelabctl k8s install -v 1.29
homelabctl k8s install -v 1.30
```

### Skip Options

Skip specific installation steps:

```shell
# Skip prerequisites (disable swap, configure sysctl, etc.)
homelabctl k8s install --skip-prerequisites

# Skip container runtime installation
homelabctl k8s install --skip-container-runtime

# Skip both
homelabctl k8s install --skip-prerequisites --skip-container-runtime
```

### Installation Options

| Option                     | Description                                  |
|----------------------------|----------------------------------------------|
| `-t, --type`               | Install type: `kubeadm` (default) or `minikube` |
| `-v, --version`            | Kubernetes version (default: 1.30)           |
| `--skip-prerequisites`     | Skip prerequisites configuration             |
| `--skip-container-runtime` | Skip container runtime installation          |
| `--dry-run`                | Preview installation steps                   |

### What Installation Does

1. Checks system requirements (CPU cores, RAM)
2. Disables swap
3. Loads required kernel modules (`overlay`, `br_netfilter`)
4. Configures sysctl parameters for networking
5. Disables SELinux and firewalld (for RHEL-based systems)
6. Installs containerd as container runtime
7. Installs kubeadm, kubelet, and kubectl
8. Enables kubelet service

## Cluster Initialization

### Initialize Master Node

Initialize the first control plane node:

```shell
homelabctl k8s init master -a 192.168.1.100
```

With custom pod network CIDR:

```shell
homelabctl k8s init master -a 192.168.1.100 -p 10.244.0.0/16
```

### Master Initialization Options

| Option                              | Description                                |
|-------------------------------------|--------------------------------------------|
| `-a, --apiserver-advertise-address` | API server advertise address (required)    |
| `-p, --pod-network-cidr`            | Pod network CIDR (default: 10.244.0.0/16)  |
| `--dry-run`                         | Preview changes                            |

### What Master Initialization Does

1. Validates prerequisites
2. Runs `kubeadm init`
3. Configures kubectl for the current user
4. Installs Flannel CNI (pod network)
5. Generates join command for workers

### Initialize Worker Node

Join a worker node to the cluster:

```shell
homelabctl k8s init worker -c 192.168.1.100:6443
```

With explicit token and CA hash:

```shell
homelabctl k8s init worker -c 192.168.1.100:6443 \
  -t abcdef.1234567890abcdef \
  --discovery-token-ca-cert-hash sha256:abc123...
```

### Worker Initialization Options

| Option                           | Description                              |
|----------------------------------|------------------------------------------|
| `-c, --control-plane`            | Control plane address (ip:port, required)|
| `-t, --token`                    | Join token (optional)                    |
| `--discovery-token-ca-cert-hash` | CA cert hash (optional)                  |
| `--dry-run`                      | Preview changes                          |

## Addon Management

### List Available Addons

View all available addons:

```shell
homelabctl k8s addon list
```

View installed addons:

```shell
homelabctl k8s addon list --installed
```

### Install Addon

Install a single addon:

```shell
homelabctl k8s addon install metallb
homelabctl k8s addon install ingress-nginx -v 4.11.1
```

With custom values file:

```shell
homelabctl k8s addon install cert-manager -f /path/to/values.yaml
```

### Uninstall Addon

```shell
homelabctl k8s addon uninstall metallb
```

### Install Recommended Addons

Quick install recommended addons:

```shell
homelabctl k8s addon quickstart
```

This is equivalent to:

```shell
homelabctl k8s addon profile apply quickstart
```

### Addon Profiles

List available profiles:

```shell
homelabctl k8s addon profile list
```

Show profile details:

```shell
homelabctl k8s addon profile show quickstart
homelabctl k8s addon profile show production
```

Apply a profile:

```shell
homelabctl k8s addon profile apply quickstart
homelabctl k8s addon profile apply quickstart --dry-run
homelabctl k8s addon profile apply production --continue --skip-installed
```

### Profile Apply Options

| Option             | Description                     |
|--------------------|---------------------------------|
| `--dry-run`        | Preview what would be installed |
| `--continue`       | Continue on error               |
| `--skip-installed` | Skip already installed addons   |

### Common Addons

| Addon                          | Category   | Description                         |
|--------------------------------|------------|-------------------------------------|
| `metallb`                      | networking | Load balancer for bare metal        |
| `ingress-nginx`                | networking | Ingress controller                  |
| `cert-manager`                 | security   | Certificate management              |
| `metrics-server`               | monitoring | Resource metrics                    |
| `kubernetes-dashboard`         | utilities  | Web UI                              |
| `nfs-subdir-external-provisioner` | storage | NFS dynamic provisioning         |

### User Configuration Override

Override builtin addon configurations by creating files in:

```
~/.config/homelabctl/k8s/<k8s-version>/<addon-name>/
```

**Custom Helm values:**

```shell
# Create custom values
mkdir -p ~/.config/homelabctl/k8s/1.30/metallb/
cat > ~/.config/homelabctl/k8s/1.30/metallb/values-homelab.yaml << 'EOF'
# Custom MetalLB configuration
controller:
  logLevel: info
EOF
```

**Post-install manifests:**

```shell
# Create custom IP address pool
cat > ~/.config/homelabctl/k8s/1.30/metallb/IPAddressPool.yaml << 'EOF'
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: default-pool
  namespace: metallb-system
spec:
  addresses:
    - 192.168.1.200-192.168.1.250
EOF
```

## Backup and Restore

### Create Backup

Create an etcd backup:

```shell
homelabctl k8s backup create
```

To a custom directory:

```shell
homelabctl k8s backup create -d /backup/etcd
```

### List Backups

```shell
homelabctl k8s backup list
homelabctl k8s backup list -d /backup/etcd
```

### Restore from Backup

Restore etcd from a backup:

```shell
homelabctl k8s backup restore /var/opt/k8s/backups/etcd/etcd-snapshot-20240101120000.db
```

With custom data directory:

```shell
homelabctl k8s backup restore /path/to/backup.db --data-dir /var/lib/etcd
```

Skip confirmation:

```shell
homelabctl k8s backup restore /path/to/backup.db --force
```

### Restore Options

| Option       | Description                              |
|--------------|------------------------------------------|
| `--data-dir` | etcd data directory (default: /var/lib/etcd)|
| `--dry-run`  | Preview what would be done               |
| `--force`    | Skip confirmation prompt                 |

## Token Management

### Create Join Token

Create a new bootstrap token:

```shell
homelabctl k8s token create
```

Get full join command:

```shell
homelabctl k8s token create --print-join-command
```

### Get Existing Token

Get current valid token:

```shell
homelabctl k8s token get
```

Create if no valid token exists:

```shell
homelabctl k8s token get --create
```

Get full join command:

```shell
homelabctl k8s token get --join-command
```

## Configuration Reference

### User Configuration Directory

Initialize user configuration:

```shell
homelabctl init k8s
```

This creates:

```
~/.config/homelabctl/k8s/
├── README.md
├── addon/
│   ├── registry.yaml       # Custom addon definitions
│   └── profiles/           # Custom addon profiles
└── <k8s-version>/          # Version-specific configs
    └── <addon-name>/       # Per-addon overrides
        ├── values-homelab.yaml
        └── *.yaml          # Post-install manifests
```

### homelabctl Configuration

K8s settings in `~/.config/homelabctl/config.yaml`:

```yaml
radp:
  extend:
    homelabctl:
      k8s:
        # Default Kubernetes version
        version: "1.30"
        # Default install type
        install_type: kubeadm
        # Default pod network CIDR
        pod_network_cidr: "10.244.0.0/16"
        # etcd backup directory
        backup_home: /var/opt/k8s/backups/etcd
```

### Directory Paths

| Path                           | Description                    |
|--------------------------------|--------------------------------|
| `/etc/kubernetes/`             | Kubernetes configuration       |
| `/etc/kubernetes/admin.conf`   | Admin kubeconfig               |
| `/var/lib/etcd/`               | etcd data directory            |
| `/var/opt/k8s/backups/etcd/`   | Default backup location        |
| `~/.config/homelabctl/k8s/`    | User configuration directory   |

### System Requirements

| Resource   | Minimum | Recommended |
|------------|---------|-------------|
| CPU Cores  | 2       | 4           |
| RAM        | 2 GB    | 4 GB        |
| Disk       | 20 GB   | 50 GB       |

### Troubleshooting

Check cluster health:

```shell
homelabctl k8s health --verbose
```

View node status:

```shell
kubectl get nodes -o wide
```

Check pod status:

```shell
kubectl get pods -A
```

View kubelet logs:

```shell
sudo journalctl -xeu kubelet
```

Reset node (start over):

```shell
sudo kubeadm reset
sudo rm -rf /etc/cni/net.d
sudo rm -rf $HOME/.kube/config
```

## See Also

- [CLI Reference - K8s Commands](../reference/cli-reference.md#k8s-health)
- [Kubernetes Official Documentation](https://kubernetes.io/docs/)
- [kubeadm Documentation](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/)
