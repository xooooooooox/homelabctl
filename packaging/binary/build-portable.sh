#!/usr/bin/env bash
#
# Build portable single-file executable for homelabctl
#
# Usage:
#   ./build-portable.sh --platform darwin-arm64
#   ./build-portable.sh --platform linux-amd64
#
set -euo pipefail

#######################################
# Constants
#######################################
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
VERSION_FILE="$PROJECT_ROOT/.radp-cli/version"

# Supported platforms
SUPPORTED_PLATFORMS=(
  "linux-amd64"
  "linux-arm64"
  "darwin-amd64"
  "darwin-arm64"
)

#######################################
# Show usage
#######################################
usage() {
  cat <<'USAGE'
build-portable.sh - Build portable single-file executable for homelabctl

Usage:
  build-portable.sh [options]

Options:
  --platform <platform>   Target platform (required)
                         Supported: linux-amd64, linux-arm64, darwin-amd64, darwin-arm64
  --output-dir <dir>     Output directory (default: dist/)
  --help                 Show this help

Examples:
  ./build-portable.sh --platform darwin-arm64
  ./build-portable.sh --platform linux-amd64
USAGE
}

#######################################
# Log functions
#######################################
log_info() {
  echo "[INFO] $*" >&2
}

log_error() {
  echo "[ERROR] $*" >&2
}

log_warn() {
  echo "[WARN] $*" >&2
}

#######################################
# Get version from .radp-cli/version
#######################################
get_version() {
  if [[ ! -f "$VERSION_FILE" ]]; then
    log_error "version file not found: $VERSION_FILE"
    return 1
  fi

  local version
  version=$(cat "$VERSION_FILE" | tr -d '[:space:]')

  if [[ -z "$version" ]]; then
    log_error "Failed to extract version from $VERSION_FILE"
    return 1
  fi

  echo "$version"
}

#######################################
# Validate platform
#######################################
validate_platform() {
  local platform="$1"
  local valid=false

  for p in "${SUPPORTED_PLATFORMS[@]}"; do
    if [[ "$p" == "$platform" ]]; then
      valid=true
      break
    fi
  done

  if [[ "$valid" != "true" ]]; then
    log_error "Unsupported platform: $platform"
    log_error "Supported platforms: ${SUPPORTED_PLATFORMS[*]}"
    return 1
  fi
}

#######################################
# Create archive content
#######################################
create_archive_content() {
  local build_dir="$1"

  log_info "Creating archive content in $build_dir"

  # Create directory structure
  mkdir -p "$build_dir/bin"
  mkdir -p "$build_dir/src/main/shell/commands"
  mkdir -p "$build_dir/src/main/shell/config"
  mkdir -p "$build_dir/src/main/shell/libs"
  mkdir -p "$build_dir/completions"
  mkdir -p "$build_dir/.radp-cli"

  # Copy bin/homelabctl
  cp "$PROJECT_ROOT/bin/homelabctl" "$build_dir/bin/"
  chmod +x "$build_dir/bin/homelabctl"

  # Copy shell layer
  cp -r "$PROJECT_ROOT/src/main/shell/commands/"* "$build_dir/src/main/shell/commands/"
  cp -r "$PROJECT_ROOT/src/main/shell/config/"* "$build_dir/src/main/shell/config/"
  cp -r "$PROJECT_ROOT/src/main/shell/libs/"* "$build_dir/src/main/shell/libs/"

  # Copy completions
  cp -r "$PROJECT_ROOT/completions/"* "$build_dir/completions/"

  # Copy .radp-cli metadata
  cp -r "$PROJECT_ROOT/.radp-cli/"* "$build_dir/.radp-cli/"

  log_info "Archive content created successfully"
}

#######################################
# Create portable executable
#######################################
create_portable() {
  local build_dir="$1"
  local output_file="$2"
  local version="$3"

  log_info "Creating portable executable: $output_file"

  # Create tar.gz archive
  local archive_file
  archive_file=$(mktemp)

  (cd "$build_dir" && tar czf "$archive_file" .)

  # Get bootstrap template
  local bootstrap_template="$SCRIPT_DIR/templates/portable-bootstrap.sh"
  if [[ ! -f "$bootstrap_template" ]]; then
    log_error "Bootstrap template not found: $bootstrap_template"
    return 1
  fi

  # Calculate archive line number (bootstrap lines + 1)
  local bootstrap_lines
  bootstrap_lines=$(wc -l < "$bootstrap_template" | tr -d ' ')
  local archive_line=$((bootstrap_lines + 1))

  # Replace placeholders in bootstrap template and append archive
  sed \
    -e "s|__VERSION__|$version|g" \
    -e "s|__ARCHIVE_LINE__|$archive_line|g" \
    "$bootstrap_template" > "$output_file"

  cat "$archive_file" >> "$output_file"
  chmod +x "$output_file"

  # Cleanup
  rm -f "$archive_file"

  # Show file info
  local size
  size=$(du -h "$output_file" | cut -f1)
  log_info "Created: $output_file ($size)"
}

#######################################
# Main
#######################################
main() {
  local platform=""
  local output_dir="$PROJECT_ROOT/dist"

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --platform)
        platform="$2"
        shift 2
        ;;
      --output-dir)
        output_dir="$2"
        shift 2
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      *)
        log_error "Unknown option: $1"
        usage
        exit 1
        ;;
    esac
  done

  # Validate required arguments
  if [[ -z "$platform" ]]; then
    log_error "--platform is required"
    usage
    exit 1
  fi

  validate_platform "$platform"

  # Get version
  local version
  version=$(get_version)
  log_info "Building homelabctl portable $version for $platform"

  # Create output directory
  mkdir -p "$output_dir"

  # Create temporary build directory
  local build_dir
  build_dir=$(mktemp -d)
  trap 'rm -rf "${build_dir:-}"' EXIT

  # Create archive content
  create_archive_content "$build_dir"

  # Determine output filename
  local output_name="homelabctl-portable-${platform}"
  local output_file="$output_dir/$output_name"

  # Create portable executable
  create_portable "$build_dir" "$output_file" "$version"

  log_info "Build completed successfully!"
}

main "$@"
