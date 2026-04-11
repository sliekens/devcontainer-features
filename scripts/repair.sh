#!/usr/bin/env bash
#
# Repair feature repositories in the OCI registry.
#
# The devcontainer CLI fails to publish to a repository with no tags (empty
# repo). This can happen after accidentally deleting all tags. This script
# bootstraps each affected repository by pushing a dummy manifest so that
# publish.sh can run successfully afterward.
#
# Usage:
#   ./scripts/repair.sh [feature-id]
#
# Examples:
#   ./scripts/repair.sh        # Repair all features from src/
#   ./scripts/repair.sh claude # Repair only the 'claude' feature
#
# Requirements:
#   - oras: https://oras.land
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
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

check_requirements() {
    if ! command -v oras &> /dev/null; then
        log_error "oras not found"
        echo "Install from: https://oras.land/docs/installation"
        exit 1
    fi
}

# Returns 0 if the repository has no tags (empty or missing), 1 otherwise.
repo_needs_bootstrap() {
    local ref="$1"
    local tags
    tags=$(oras repo tags "$ref" 2>/dev/null) || return 0
    [[ -z "$tags" ]]
}

bootstrap_repo() {
    local ref="$1"
    local tmpdir
    tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' RETURN

    echo '{}' > "$tmpdir/dummy.json"

    log_info "Bootstrapping $ref..."
    oras push "$ref:latest" "$tmpdir/dummy.json:application/vnd.devcontainers" \
        --disable-path-validation 2>&1
    log_success "Bootstrapped $ref"
}

repair_feature() {
    local feature_id="$1"
    local ref="${REGISTRY}/${NAMESPACE}/${feature_id}"

    if repo_needs_bootstrap "$ref"; then
        bootstrap_repo "$ref"
    else
        log_info "$feature_id is healthy, skipping"
    fi
}

main() {
    local feature_filter="${1:-}"

    check_requirements

    log_info "Registry: ${REGISTRY}/${NAMESPACE}"

    if [[ -n "$feature_filter" ]]; then
        local feature_dir="$SRC_DIR/$feature_filter"
        if [[ ! -f "$feature_dir/devcontainer-feature.json" ]]; then
            log_error "Feature not found: $feature_filter"
            exit 1
        fi
        repair_feature "$feature_filter"
    else
        for feature_dir in "$SRC_DIR"/*/; do
            if [[ -f "$feature_dir/devcontainer-feature.json" ]]; then
                local feature_id
                feature_id=$(basename "$feature_dir")
                repair_feature "$feature_id"
            fi
        done
    fi

    log_success "Repair complete"
}

main "$@"
