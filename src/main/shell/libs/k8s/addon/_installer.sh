#!/usr/bin/env bash
# K8S Addon Installer
# Provides functions to install and uninstall Kubernetes addons

#######################################
# Install a Kubernetes addon
# Arguments:
#   1 - addon_name: Name of the addon to install
#   2 - version: Version to install (optional, uses default)
#   3 - values_file: Custom values file (optional)
# Returns:
#   0 - Success
#   1 - Failure
#######################################
_k8s_addon_install() {
  local addon_name="${1:?'Addon name required'}"
  local version="${2:-}"
  local values_file="${3:-}"

  # Check if addon exists
  if ! _k8s_addon_exists "$addon_name"; then
    radp_log_error "Unknown addon: $addon_name"
    radp_log_info "Run 'homelabctl k8s addon list' to see available addons"
    return 1
  fi

  # Ensure helm is available
  if ! _k8s_ensure_helm; then
    return 1
  fi

  # Get version if not specified
  if [[ -z "$version" ]]; then
    version=$(_k8s_addon_get_version "$addon_name")
  fi

  radp_log_info "Installing addon: $addon_name (version: $version)"

  # Check dependencies
  local deps
  deps=$(_k8s_addon_get_dependencies "$addon_name")
  if [[ -n "$deps" ]]; then
    radp_log_info "Checking dependencies: $deps"
    for dep in $deps; do
      if ! _k8s_addon_is_installed "$dep"; then
        radp_log_error "Dependency not installed: $dep"
        radp_log_info "Install it first: homelabctl k8s addon install $dep"
        return 1
      fi
    done
  fi

  # Get helm configuration
  local repo_name repo_url chart namespace create_namespace version_prefix
  eval "$(_k8s_addon_get_helm_config "$addon_name")"

  if [[ -z "$chart" ]]; then
    radp_log_error "No helm chart defined for addon: $addon_name"
    return 1
  fi

  # Add helm repo
  radp_log_info "Adding helm repository: $repo_name"
  radp_exec "Add helm repo $repo_name" helm repo add "$repo_name" "$repo_url" --force-update || {
    radp_log_error "Failed to add helm repository"
    return 1
  }

  # Build helm install command
  local -a helm_args=(
    "upgrade" "--install"
    "$addon_name"
    "$chart"
    "-n" "$namespace"
  )

  # Add version with optional prefix
  if [[ -n "$version" ]]; then
    helm_args+=("--version" "${version_prefix}${version}")
  fi

  # Create namespace if required
  if [[ "$create_namespace" == "true" ]]; then
    helm_args+=("--create-namespace")
  fi

  # Add custom values file if provided
  if [[ -n "$values_file" && -f "$values_file" ]]; then
    helm_args+=("-f" "$values_file")
  else
    # Try to find values file (user takes precedence over builtin)
    local k8s_version extra_config_path builtin_path
    k8s_version=$(_k8s_get_default_version)
    extra_config_path=$(_k8s_get_extra_config_path)
    builtin_path=$(_k8s_get_builtin_defaults_path)

    local user_values="$extra_config_path/$k8s_version/$addon_name/$version/values-homelab.yaml"
    local user_values_no_version="$extra_config_path/$k8s_version/$addon_name/values-homelab.yaml"
    local builtin_values="$builtin_path/$k8s_version/$addon_name/values-homelab.yaml"
    local default_values=""

    if [[ -f "$user_values" ]]; then
      default_values="$user_values"
      radp_log_info "Using user values file: $user_values"
    elif [[ -f "$user_values_no_version" ]]; then
      default_values="$user_values_no_version"
      radp_log_info "Using user values file: $user_values_no_version"
    elif [[ -f "$builtin_values" ]]; then
      default_values="$builtin_values"
      radp_log_info "Using builtin values file: $builtin_values"
    fi

    if [[ -n "$default_values" ]]; then
      helm_args+=("-f" "$default_values")
    fi
  fi

  # Run helm install
  radp_log_info "Running helm install..."
  radp_exec "Install helm chart $addon_name" helm "${helm_args[@]}" || {
    radp_log_error "Failed to install addon: $addon_name"
    return 1
  }

  # Run post-install steps
  _k8s_addon_run_post_install "$addon_name" "$version" || {
    radp_log_warn "Post-install steps had issues, addon may not be fully configured"
  }

  radp_log_info "Addon installed successfully: $addon_name"
  return 0
}

#######################################
# Run post-install steps for an addon
# Arguments:
#   1 - addon_name: Name of the addon
#   2 - version: Installed version
# Returns:
#   0 - Success
#   1 - Failure
#######################################
_k8s_addon_run_post_install() {
  local addon_name="${1:?'Addon name required'}"
  local version="${2:-}"

  local post_install
  post_install=$(_k8s_addon_get_post_install "$addon_name")

  if [[ "$post_install" == "[]" || -z "$post_install" ]]; then
    return 0
  fi

  radp_log_info "Running post-install steps..."

  local k8s_version extra_config_path builtin_path
  k8s_version=$(_k8s_get_default_version)
  extra_config_path=$(_k8s_get_extra_config_path)
  builtin_path=$(_k8s_get_builtin_defaults_path)

  # Parse JSON array of post-install steps
  local step_count
  step_count=$(echo "$post_install" | yq -r 'length' 2>/dev/null)

  local i=0
  while [[ $i -lt $step_count ]]; do
    local step_type step_path step_desc
    step_type=$(echo "$post_install" | yq -r ".[$i].type // empty" 2>/dev/null)
    step_path=$(echo "$post_install" | yq -r ".[$i].path // empty" 2>/dev/null)
    step_desc=$(echo "$post_install" | yq -r ".[$i].desc // \"Post-install step\"" 2>/dev/null)

    radp_log_info "  - $step_desc"

    case "$step_type" in
      manifest)
        # Try user path first, then builtin path
        local user_manifest="$extra_config_path/$k8s_version/$step_path"
        local builtin_manifest="$builtin_path/$k8s_version/$step_path"
        local full_path=""

        if [[ -f "$user_manifest" ]]; then
          full_path="$user_manifest"
          radp_log_info "    Using user manifest: $user_manifest"
        elif [[ -f "$builtin_manifest" ]]; then
          full_path="$builtin_manifest"
          radp_log_info "    Using builtin manifest: $builtin_manifest"
        fi

        if [[ -n "$full_path" ]] || radp_is_dry_run; then
          radp_exec "Apply manifest $step_path" kubectl apply -f "$full_path" || {
            radp_log_warn "Failed to apply manifest: $full_path"
          }
        else
          radp_log_warn "Manifest not found in user or builtin paths: $step_path"
          radp_log_warn "  User path: $user_manifest"
          radp_log_warn "  Builtin path: $builtin_manifest"
        fi
        ;;
      *)
        radp_log_warn "Unknown post-install step type: $step_type"
        ;;
    esac

    ((++i))
  done

  return 0
}

#######################################
# Uninstall a Kubernetes addon
# Arguments:
#   1 - addon_name: Name of the addon to uninstall
# Returns:
#   0 - Success
#   1 - Failure
#######################################
_k8s_addon_uninstall() {
  local addon_name="${1:?'Addon name required'}"

  # Check if addon exists in registry
  if ! _k8s_addon_exists "$addon_name"; then
    radp_log_error "Unknown addon: $addon_name"
    return 1
  fi

  radp_log_info "Uninstalling addon: $addon_name"

  # Get helm configuration
  local namespace
  namespace=$(_k8s_addon_get_property "$addon_name" "helm.namespace")
  namespace="${namespace:-default}"

  # Run pre-uninstall: remove post-install resources
  _k8s_addon_cleanup_post_install "$addon_name" || true

  # Uninstall helm release
  radp_exec "Uninstall helm release $addon_name" helm uninstall "$addon_name" -n "$namespace" || {
    radp_log_warn "Helm uninstall may have failed, release might not exist"
  }

  radp_log_info "Addon uninstalled: $addon_name"
  return 0
}

#######################################
# Cleanup post-install resources for an addon
# Arguments:
#   1 - addon_name: Name of the addon
# Returns:
#   0 - Success (best effort)
#######################################
_k8s_addon_cleanup_post_install() {
  local addon_name="${1:?'Addon name required'}"

  local post_install
  post_install=$(_k8s_addon_get_post_install "$addon_name")

  if [[ "$post_install" == "[]" || -z "$post_install" ]]; then
    return 0
  fi

  radp_log_info "Cleaning up post-install resources..."

  local k8s_version extra_config_path builtin_path
  k8s_version=$(_k8s_get_default_version)
  extra_config_path=$(_k8s_get_extra_config_path)
  builtin_path=$(_k8s_get_builtin_defaults_path)

  local step_count
  step_count=$(echo "$post_install" | yq -r 'length' 2>/dev/null)

  local i=0
  while [[ $i -lt $step_count ]]; do
    local step_type step_path
    step_type=$(echo "$post_install" | yq -r ".[$i].type // empty" 2>/dev/null)
    step_path=$(echo "$post_install" | yq -r ".[$i].path // empty" 2>/dev/null)

    case "$step_type" in
      manifest)
        # Try user path first, then builtin path
        local user_manifest="$extra_config_path/$k8s_version/$step_path"
        local builtin_manifest="$builtin_path/$k8s_version/$step_path"
        local full_path=""

        if [[ -f "$user_manifest" ]]; then
          full_path="$user_manifest"
        elif [[ -f "$builtin_manifest" ]]; then
          full_path="$builtin_manifest"
        fi

        if [[ -n "$full_path" ]] || radp_is_dry_run; then
          radp_exec "Delete manifest $step_path" kubectl delete -f "$full_path" 2>/dev/null || true
        fi
        ;;
    esac

    ((++i))
  done

  return 0
}

#######################################
# Check if an addon is installed
# Arguments:
#   1 - addon_name: Name of the addon
# Returns:
#   0 - Addon is installed
#   1 - Addon is not installed
#######################################
_k8s_addon_is_installed() {
  local addon_name="${1:?'Addon name required'}"

  local namespace
  namespace=$(_k8s_addon_get_property "$addon_name" "helm.namespace")
  namespace="${namespace:-default}"

  helm status "$addon_name" -n "$namespace" &>/dev/null
}

