# @cmd
# @desc Initialize a new radp-vagrant-framework project
# @option -d, --dir <path> Target directory [default: .]
# @option -t, --template <name> Template name [default: default]
# @option -f, --force Overwrite existing files
# @example vf init
# @example vf init -d ~/my-lab
# @example vf init --template k8s

cmd_vf_init() {
    local target_dir="${opt_dir:-.}"
    local template="${opt_template:-default}"
    local force="${opt_force:-false}"

    # 创建目标目录
    mkdir -p "$target_dir"

    # 检查是否已存在配置
    if [[ -d "$target_dir/config" && "$force" != "true" ]]; then
        radp_log_error "Directory already initialized: $target_dir/config"
        radp_log_error "Use --force to overwrite"
        return 1
    fi

    radp_log_info "Initializing radp-vagrant-framework project in: $target_dir"

    # 创建目录结构
    mkdir -p "$target_dir"/{config,provisions/{definitions,scripts}}

    # 尝试从 RADP_VF_HOME 复制示例配置
    local sample_config="${RADP_VF_HOME:-}/src/main/ruby/config"
    if [[ -n "${RADP_VF_HOME:-}" && -d "$sample_config" ]]; then
        cp "$sample_config/vagrant.yaml" "$target_dir/config/" 2>/dev/null || true
        # 根据模板选择环境配置
        case "$template" in
            k8s)
                cp "$sample_config/vagrant-k8s.yaml" "$target_dir/config/vagrant-local.yaml" 2>/dev/null || \
                    cp "$sample_config/vagrant-sample.yaml" "$target_dir/config/vagrant-local.yaml" 2>/dev/null || true
                ;;
            *)
                cp "$sample_config/vagrant-sample.yaml" "$target_dir/config/vagrant-local.yaml" 2>/dev/null || true
                ;;
        esac
        radp_log_info "Copied sample configuration from RADP_VF_HOME"
    else
        # 生成基础配置
        radp_log_info "Generating default configuration..."
        cat > "$target_dir/config/vagrant.yaml" << 'YAML'
radp:
  env: local
  extend:
    vagrant:
      plugins:
        - name: vagrant-hostmanager
          required: true
          options:
            enabled: true
            manage_host: true
            manage_guest: true
YAML

        cat > "$target_dir/config/vagrant-local.yaml" << 'YAML'
radp:
  extend:
    vagrant:
      config:
        clusters:
          - name: lab
            common:
              box:
                name: generic/rocky9
            guests:
              - id: node-1
                provider:
                  type: virtualbox
                  mem: 2048
                  cpus: 2
                network:
                  private-network:
                    ip: 192.168.56.101
YAML
    fi

    radp_log_info "Project initialized successfully!"
    echo ""
    radp_log_info "Next steps:"
    radp_log_info "  cd $target_dir"
    radp_log_info "  # Edit config/vagrant.yaml and config/vagrant-local.yaml"
    radp_log_info "  homelabctl vf info       # Check environment"
    radp_log_info "  homelabctl vf dump-config # Preview merged config"
    radp_log_info "  homelabctl vg up         # Start VMs"
}
