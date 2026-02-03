#!/bin/sh
# homelabctl portable bootstrap
# This script extracts and runs the bundled homelabctl
#
# Version: __VERSION__
# Archive starts at line: __ARCHIVE_LINE__

set -e

# Configuration
VERSION="__VERSION__"
ARCHIVE_LINE="__ARCHIVE_LINE__"

# Cache directory
CACHE_BASE="${XDG_CACHE_HOME:-$HOME/.cache}/homelabctl"
CACHE_DIR="$CACHE_BASE/$VERSION"

# Export portable mode indicator
export HOMELABCTL_PORTABLE=1
export HOMELABCTL_PORTABLE_VERSION="$VERSION"

#######################################
# Log functions
#######################################
log_info() {
  echo "[homelabctl] $*" >&2
}

log_error() {
  echo "[homelabctl] ERROR: $*" >&2
}

#######################################
# Extract archive to cache directory
#######################################
extract_archive() {
  log_info "Extracting homelabctl $VERSION..."

  # Create cache directory
  mkdir -p "$CACHE_DIR"

  # Extract archive (skip bootstrap script lines)
  tail -n +"$ARCHIVE_LINE" "$0" | tar xz -C "$CACHE_DIR" 2>/dev/null || {
    log_error "Failed to extract archive"
    rm -rf "$CACHE_DIR"
    exit 1
  }

  # Mark as extracted
  echo "$VERSION" >"$CACHE_DIR/.extracted"

  log_info "Extracted to $CACHE_DIR"
}

#######################################
# Check if extraction is needed
#######################################
needs_extraction() {
  # Check if .extracted marker exists and matches version
  if [ -f "$CACHE_DIR/.extracted" ]; then
    cached_version=$(cat "$CACHE_DIR/.extracted" 2>/dev/null || echo "")
    if [ "$cached_version" = "$VERSION" ]; then
      return 1 # No extraction needed
    fi
  fi
  return 0 # Extraction needed
}

#######################################
# Clean old cached versions
#######################################
cleanup_old_versions() {
  if [ -d "$CACHE_BASE" ]; then
    # Keep only current version, remove others
    for dir in "$CACHE_BASE"/v*; do
      if [ -d "$dir" ] && [ "$dir" != "$CACHE_DIR" ]; then
        rm -rf "$dir" 2>/dev/null || true
      fi
    done
  fi
}

#######################################
# Check if bash version is 4.3+
#######################################
check_bash_version() {
  bash_path="$1"
  version_output=$("$bash_path" -c 'echo "${BASH_VERSINFO[0]}.${BASH_VERSINFO[1]}"' 2>/dev/null) || return 1

  major="${version_output%%.*}"
  minor="${version_output#*.}"

  # Require bash 4.3+
  if [ "$major" -gt 4 ] 2>/dev/null; then
    return 0
  elif [ "$major" -eq 4 ] && [ "$minor" -ge 3 ] 2>/dev/null; then
    return 0
  fi

  return 1
}

#######################################
# Find suitable bash
#######################################
find_bash() {
  # Try common locations for bash 4.3+
  for bash_path in \
    /opt/homebrew/bin/bash \
    /usr/local/bin/bash \
    /usr/bin/bash \
    /bin/bash; do
    if [ -x "$bash_path" ] && check_bash_version "$bash_path"; then
      echo "$bash_path"
      return 0
    fi
  done

  log_error "bash 4.3+ not found. Please install bash 4.3 or later."
  log_error "  macOS: brew install bash"
  log_error "  Linux: apt install bash / dnf install bash"
  exit 1
}

#######################################
# Check radp-bash-framework
#######################################
check_radp_bf() {
  if command -v radp-bf >/dev/null 2>&1; then
    return 0
  fi

  log_error "radp-bash-framework not found."
  log_error "homelabctl requires radp-bash-framework to be installed."
  log_error ""
  log_error "Install options:"
  log_error "  Homebrew: brew install xooooooooox/radp/radp-bash-framework"
  log_error "  Portable: Download radp-bf-portable from GitHub releases"
  log_error "  Script:   curl -fsSL https://raw.githubusercontent.com/xooooooooox/radp-bash-framework/main/install.sh | bash"
  log_error ""
  log_error "For more information, see: https://github.com/xooooooooox/radp-bash-framework"
  exit 1
}

#######################################
# Main entry point
#######################################
main() {
  # Extract if needed
  if needs_extraction; then
    extract_archive
    cleanup_old_versions
  fi

  # Check radp-bash-framework is available
  check_radp_bf

  # Export framework paths
  export HOMELABCTL_PORTABLE_ROOT="$CACHE_DIR"
  export RADP_APP_ROOT="$CACHE_DIR"

  # Find bash and execute homelabctl
  BASH_BIN=$(find_bash)

  # Execute homelabctl with all arguments
  exec "$BASH_BIN" "$CACHE_DIR/bin/homelabctl" "$@"
}

main "$@"
exit 0
# Archive data follows (do not edit below this line)
