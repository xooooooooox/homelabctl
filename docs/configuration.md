# Configuration

homelabctl uses the radp-bash-framework configuration system. Configuration is stored in
`src/main/shell/config/config.yaml`.

## Complete Configuration Reference

```yaml
# src/main/shell/config/config.yaml - Complete Configuration Reference
radp:
  # Active environment (determines which config-{env}.yaml to load)
  env: default

  # Framework settings override
  fw:
    # Banner display mode: on, off, log
    # homelabctl defaults to 'off' for cleaner CLI output
    banner-mode: off

    # Logging configuration
    log:
      # Enable debug level logging
      debug: false

      # Minimum log level: debug, info, warn, error
      level: info

      # Console output settings
      console:
        enabled: true

      # File output settings
      file:
        enabled: false
        # name: /var/log/homelabctl/homelabctl.log

    # User configuration settings
    user:
      config:
        # Auto-map radp.extend.* to shell variables
        automap: true

  # Application-specific settings
  # Variables defined here are available as gr_radp_extend_* in shell
  extend:
    homelabctl:
    # Add application-specific configuration here
    # Example:
    # default_template: base
    # default_env: dev
```

## Environment Overrides

Override configuration via environment variables using `GX_` prefix:

```bash
# Enable debug logging
GX_RADP_FW_LOG_DEBUG=true homelabctl vf list

# Show banner
GX_RADP_FW_BANNER_MODE=on homelabctl --help
```

## Environment-Specific Configuration

Create additional config files for different environments:

```
config/
├── config.yaml           # Base configuration
├── config-dev.yaml       # Development overrides
└── config-prod.yaml      # Production overrides
```

Set the environment:

```yaml
# config/config.yaml
radp:
  env: dev    # Load config-dev.yaml
```

Or via environment variable:

```bash
GX_RADP_ENV=prod homelabctl vf list
```

## Vagrant Framework Configuration

homelabctl wraps radp-vagrant-framework. For VM configuration, see:

- [radp-vagrant-framework Configuration Reference](https://github.com/xooooooooox/radp-vagrant-framework/blob/main/docs/configuration-reference.md)

The vagrant configuration files are located in your project directory:

```
myproject/
└── config/
    ├── vagrant.yaml          # Base vagrant configuration
    └── vagrant-{env}.yaml    # Environment-specific clusters
```

## Configuration Priority

1. **Framework defaults** (radp-bash-framework)
2. **Base config** (`config/config.yaml`)
3. **Environment config** (`config/config-{env}.yaml`)
4. **Environment variables** (`GX_*`)

Later sources override earlier ones.

## Related Environment Variables

| Variable                  | Description                                             |
|---------------------------|---------------------------------------------------------|
| `RADP_VF_HOME`            | Path to radp-vagrant-framework installation             |
| `RADP_VAGRANT_CONFIG_DIR` | Override vagrant config directory (default: `./config`) |
| `RADP_VAGRANT_ENV`        | Override vagrant environment name                       |
