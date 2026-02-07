#!/usr/bin/env bash
#
# Publish devcontainer features to an OCI registry.
#
# This script delegates publishing to the devcontainer CLI, which handles:
# - Packaging
# - Semver tags
# - Idempotent version checks
# - Collection metadata publishing
#
# Usage:
#   ./scripts/publish.sh [feature-id]
#
# Examples:
#   ./scripts/publish.sh        # Publish all features from src/
#   ./scripts/publish.sh codex  # Publish only the 'codex' feature
#
# Requirements:
#   - Node.js (for @devcontainers/cli)
#   - @devcontainers/cli: npm install -g @devcontainers/cli
#

set -euo pipefail

# Configuration
REGISTRY="${REGISTRY:-ghcr.io}"
NAMESPACE="${NAMESPACE:-sliekens/devcontainer-features}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$(cd "$SCRIPT_DIR/../src" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

check_requirements() {
    if ! command -v devcontainer &> /dev/null; then
        log_error "devcontainer CLI not found"
        echo "Install with: npm install -g @devcontainers/cli"
        exit 1
    fi
}

resolve_target() {
    local feature_filter="${1:-}"
    if [[ -z "$feature_filter" ]]; then
        printf '%s\n' "$SRC_DIR"
        return
    fi

    local feature_dir="$SRC_DIR/$feature_filter"
    if [[ -d "$feature_dir" && -f "$feature_dir/devcontainer-feature.json" ]]; then
        printf '%s\n' "$feature_dir"
        return
    fi

    log_error "Feature not found: $feature_filter"
    exit 1
}

main() {
    local feature_filter="${1:-}"
    local target

    check_requirements
    target="$(resolve_target "$feature_filter")"

    log_info "Publishing target: $target"
    log_info "Registry: ${REGISTRY}/${NAMESPACE}"

    devcontainer features publish \
        "$target" \
        --registry "$REGISTRY" \
        --namespace "$NAMESPACE"

    log_success "Publish complete"
}

main "$@"
