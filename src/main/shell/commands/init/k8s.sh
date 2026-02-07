#!/usr/bin/env bash
# @cmd
# @desc Initialize k8s user configuration directory
# @flag --force Overwrite existing files
# @flag --dry-run Show what would be created without making changes
# @example init k8s
# @example init k8s --dry-run
# @example init k8s --force

cmd_init_k8s() {
  local force="${opt_force:-false}"
  radp_set_dry_run "${opt_dry_run:-}"

  local user_dir
  user_dir=$(_k8s_get_extra_config_path)
  local k8s_version
  k8s_version=$(_k8s_get_default_version)

  radp_log_info "Initializing k8s user configuration..."
  radp_log_info "  Directory: $user_dir"

  # Create directory structure
  radp_exec "Create k8s user directory" mkdir -p "$user_dir"/addon/profiles
  radp_exec "Create k8s version directory" mkdir -p "$user_dir/$k8s_version"

  # Create README.md
  if [[ ! -f "$user_dir/README.md" ]] || [[ "$force" == "true" ]]; then
    _init_create_k8s_readme "$user_dir/README.md"
  else
    radp_log_info "  Skipping README.md (already exists, use --force to overwrite)"
  fi

  # Create sample addon registry.yaml
  if [[ ! -f "$user_dir/addon/registry.yaml" ]] || [[ "$force" == "true" ]]; then
    _init_create_k8s_addon_registry "$user_dir/addon/registry.yaml"
  else
    radp_log_info "  Skipping addon/registry.yaml (already exists, use --force to overwrite)"
  fi

  # Create version directory README
  if [[ ! -f "$user_dir/$k8s_version/README.md" ]] || [[ "$force" == "true" ]]; then
    _init_create_k8s_version_readme "$user_dir/$k8s_version/README.md" "$k8s_version"
  else
    radp_log_info "  Skipping $k8s_version/README.md (already exists, use --force to overwrite)"
  fi

  # Create .gitkeep files
  radp_exec "Create addon/profiles .gitkeep" touch "$user_dir/addon/profiles/.gitkeep"

  radp_log_info "K8s user configuration initialized at: $user_dir"
  return 0
}

#######################################
# Create k8s README.md
# Arguments:
#   1 - file path
#######################################
_init_create_k8s_readme() {
  local file_path="$1"

  radp_log_info "  Creating README.md"

  if radp_is_dry_run; then
    radp_log_info "[dry-run] Would create: $file_path"
    return 0
  fi

  cat > "$file_path" << 'EOF'
# K8s User Configuration

This directory contains user-defined addons, profiles, and configurations for `homelabctl k8s`.

## Directory Structure

```
~/.config/homelabctl/k8s/
├── README.md                          # This file
├── addon/
│   ├── registry.yaml                  # User-defined addon definitions
│   └── profiles/                      # User-defined addon profiles
│       └── *.yaml
└── <k8s-version>/                     # K8S version (e.g., 1.30)
    └── <addon-name>/
        ├── values-homelab.yaml        # Custom Helm values (overrides builtin)
        └── *.yaml                     # Post-install manifests (overrides builtin)
```

## Override Builtin Configurations

User configurations take precedence over builtin defaults:

1. **Helm Values**: Place `values-homelab.yaml` in:
   ```
   ~/.config/homelabctl/k8s/<k8s-version>/<addon-name>/values-homelab.yaml
   ```

2. **Post-install Manifests**: Place manifest files in:
   ```
   ~/.config/homelabctl/k8s/<k8s-version>/<addon-name>/<manifest>.yaml
   ```

## Examples

### Custom MetalLB IP Pool

Create `~/.config/homelabctl/k8s/1.30/metallb/IPAddressPool.yaml`:

```yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: default-pool
  namespace: metallb-system
spec:
  addresses:
    - 192.168.1.200-192.168.1.250
```

### Custom metrics-server Values

Create `~/.config/homelabctl/k8s/1.30/metrics-server/values-homelab.yaml`:

```yaml
args:
  - --kubelet-insecure-tls
  - --kubelet-preferred-address-types=InternalIP
```

## See Also

- `homelabctl k8s addon list` - List available addons
- `homelabctl k8s addon profile list` - List available profiles
- `homelabctl k8s addon install <addon>` - Install an addon
EOF
}

#######################################
# Create sample k8s addon registry.yaml
# Arguments:
#   1 - file path
#######################################
_init_create_k8s_addon_registry() {
  local file_path="$1"

  radp_log_info "  Creating addon/registry.yaml"

  if radp_is_dry_run; then
    radp_log_info "[dry-run] Would create: $file_path"
    return 0
  fi

  cat > "$file_path" << 'EOF'
# User-defined Kubernetes addons
# These addons extend the builtin registry
#
# Example addon definition:
#
# addons:
#   my-addon:
#     desc: "Description of my addon"
#     category: utilities           # networking, monitoring, security, storage, utilities
#     default_version: "1.0.0"
#     depends_on:                   # Optional: addon dependencies
#       - cert-manager
#     helm:
#       repo_name: my-repo
#       repo_url: https://charts.example.com
#       chart: my-repo/my-addon
#       namespace: my-addon
#       create_namespace: true
#       version_prefix: "v"         # Optional: prefix for version (e.g., "v1.0.0")
#     post_install:                 # Optional: post-install steps
#       - type: manifest
#         desc: "Apply custom resource"
#         path: my-addon/custom-resource.yaml
#
# Note: Post-install manifest paths are relative to:
#   ~/.config/homelabctl/k8s/<k8s-version>/

addons: {}
EOF
}

#######################################
# Create k8s version directory README
# Arguments:
#   1 - file path
#   2 - k8s version
#######################################
_init_create_k8s_version_readme() {
  local file_path="$1"
  local k8s_version="$2"

  radp_log_info "  Creating $k8s_version/README.md"

  if radp_is_dry_run; then
    radp_log_info "[dry-run] Would create: $file_path"
    return 0
  fi

  cat > "$file_path" << EOF
# K8s $k8s_version Configuration

This directory contains addon configurations for Kubernetes $k8s_version.

## Directory Structure

\`\`\`
$k8s_version/
├── README.md
├── metallb/
│   ├── IPAddressPool.yaml          # IP address pool configuration
│   └── L2Advertisement.yaml        # L2 advertisement configuration
├── cert-manager/
│   └── values-homelab.yaml         # Helm values (CRDs enabled)
├── ingress-nginx/
│   └── values-homelab.yaml         # Helm values (LoadBalancer type)
├── alidns-webhook/
│   ├── alidns-secret.yaml          # Aliyun DNS credentials
│   └── cluster-issuer.yaml         # Let's Encrypt cluster issuer
├── kubernetes-dashboard/
│   ├── kubernetes-dashboard-ingress.yaml
│   └── kubernetes-dashboard-access-control.yaml
├── metrics-server/
│   └── values-homelab.yaml         # Helm values (insecure TLS)
└── nfs-subdir-external-provisioner/
    └── values-homelab.yaml         # NFS server configuration
\`\`\`

## Usage

1. Copy builtin configurations to this directory (if needed)
2. Modify configurations for your environment
3. Run \`homelabctl k8s addon install <addon>\`

User configurations in this directory take precedence over builtin defaults.

## Important Notes

- Files marked with \`# TODO: Change\` require your specific values
- Keep sensitive data (credentials, secrets) secure
- Test in a non-production environment first
EOF
}
