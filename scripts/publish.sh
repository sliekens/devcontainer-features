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
GITHUB_REPO="${GITHUB_REPO:-${NAMESPACE}}"
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

# Add the org.opencontainers.image.source annotation to published packages
# so GHCR automatically links them to the GitHub repository.
link_packages_to_repo() {
    local target="$1"
    local source_url="https://github.com/${GITHUB_REPO}"

    if ! command -v oras &> /dev/null; then
        log_info "Skipping repository linking (oras CLI not found)"
        return 0
    fi

    # Collect feature IDs from the publish target
    local features=()
    if [[ -f "$target/devcontainer-feature.json" ]]; then
        features+=("$(jq -r '.id' "$target/devcontainer-feature.json")")
    else
        for dir in "$target"/*/; do
            if [[ -f "$dir/devcontainer-feature.json" ]]; then
                features+=("$(jq -r '.id' "$dir/devcontainer-feature.json")")
            fi
        done
    fi

    for feature_id in "${features[@]}"; do
        local ref="${REGISTRY}/${NAMESPACE}/${feature_id}"

        # Get all tags for this feature
        local tags
        tags=$(oras repo tags "$ref" 2>/dev/null) || {
            log_info "Could not list tags for ${feature_id}, skipping linking"
            continue
        }

        # Check if already annotated
        local manifest
        manifest=$(oras manifest fetch "$ref:latest" 2>/dev/null) || continue
        if echo "$manifest" | jq -e '.annotations["org.opencontainers.image.source"]' &>/dev/null; then
            log_info "${feature_id} already linked to repository"
            continue
        fi

        # Add the source annotation and push back for each tag
        local updated
        updated=$(echo "$manifest" | jq --arg src "$source_url" \
            '.annotations["org.opencontainers.image.source"] = $src')
        local media_type
        media_type=$(echo "$manifest" | jq -r '.mediaType')

        for tag in $tags; do
            echo "$updated" | oras manifest push \
                --media-type "$media_type" \
                "$ref:$tag" - 2>/dev/null
        done

        log_info "Linked ${feature_id} to ${GITHUB_REPO}"
    done
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

    link_packages_to_repo "$target"

    log_success "Publish complete"
}

main "$@"
