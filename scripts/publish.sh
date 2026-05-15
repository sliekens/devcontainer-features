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
#   ./scripts/publish.sh [--dry-run]
#
# Options:
#   --dry-run    Validate schemas and print what would be published without pushing.
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
DRY_RUN=0

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
        echo "Install with: npm install -g @devcontainers/cli ajv-cli"
        exit 1
    fi
}

validate_features() {
    local schema="$SCRIPT_DIR/../schemas/devContainerFeature.schema.json"

    if ! command -v ajv &> /dev/null; then
        log_info "Skipping schema validation (ajv-cli not found)"
        return 0
    fi

    local failed=0
    for dir in "$SRC_DIR"/*/; do
        [[ -f "$dir/devcontainer-feature.json" ]] || continue
        local feature_id
        feature_id=$(basename "$dir")
        if ajv validate --allow-union-types -s "$schema" -d "$dir/devcontainer-feature.json" &>/dev/null; then
            log_info "Valid schema: ${feature_id}"
        else
            log_error "Invalid schema: ${feature_id}"
            ajv validate --allow-union-types -s "$schema" -d "$dir/devcontainer-feature.json" 2>&1 || true
            failed=1
        fi
    done

    return $failed
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

    local features=()
    for dir in "$target"/*/; do
        if [[ -f "$dir/devcontainer-feature.json" ]]; then
            features+=("$(jq -r '.id' "$dir/devcontainer-feature.json")")
        fi
    done

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

main() {
    for arg in "$@"; do
        case "$arg" in
            --dry-run) DRY_RUN=1 ;;
            *) log_error "Unknown argument: $arg"; exit 1 ;;
        esac
    done

    check_requirements

    log_info "Validating feature schemas..."
    if ! validate_features; then
        log_error "Schema validation failed. Fix errors before publishing."
        exit 1
    fi

    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "Dry run — would publish to ${REGISTRY}/${NAMESPACE}:"
        for dir in "$SRC_DIR"/*/; do
            [[ -f "$dir/devcontainer-feature.json" ]] || continue
            local id version
            id=$(jq -r '.id' "$dir/devcontainer-feature.json")
            version=$(jq -r '.version' "$dir/devcontainer-feature.json")
            log_info "  ${REGISTRY}/${NAMESPACE}/${id}:${version}"
        done
        return 0
    fi

    log_info "Registry: ${REGISTRY}/${NAMESPACE}"

    local log_level_args=()
    if [[ "${TRACE:-}" == "1" ]]; then
        log_level_args=(--log-level trace)
    elif [[ "${DEBUG:-}" == "1" ]]; then
        log_level_args=(--log-level debug)
    fi

    devcontainer features publish \
        "$SRC_DIR" \
        --registry "$REGISTRY" \
        --namespace "$NAMESPACE" \
        "${log_level_args[@]}"

    link_packages_to_repo "$SRC_DIR"

    log_success "Publish complete"
}

main "$@"
