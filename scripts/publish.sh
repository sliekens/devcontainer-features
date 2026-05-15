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
PACKAGE_VISIBILITY="${PACKAGE_VISIBILITY:-public}"
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

# Flags set once in post_publish_setup; read by annotate_image and check_visibility.
CAN_ANNOTATE=0
CAN_CHECK_VISIBILITY=0

post_publish_setup() {
    if command -v oras &>/dev/null; then
        CAN_ANNOTATE=1
    else
        log_info "Skipping image annotation (oras CLI not found)"
    fi

    if ! command -v gh &>/dev/null; then
        log_info "Skipping package visibility check (gh CLI not found)"
    elif ! gh auth status &>/dev/null; then
        log_info "Skipping package visibility check (gh not authenticated)"
        echo "  Run: gh auth login"
    else
        CAN_CHECK_VISIBILITY=1
    fi
}

# Add org.opencontainers.image.source to every tag of a published feature
# so GHCR links the package to the GitHub repository.
annotate_image() {
    local feature_id="$1"
    [[ $CAN_ANNOTATE -eq 1 ]] || return 0

    local ref="${REGISTRY}/${NAMESPACE}/${feature_id}"
    local source_url="https://github.com/${GITHUB_REPO}"

    local tags
    tags=$(oras repo tags "$ref" 2>/dev/null) || {
        log_info "Could not list tags for ${feature_id}, skipping annotation"
        return 0
    }

    local manifest
    manifest=$(oras manifest fetch "$ref:latest" 2>/dev/null) || return 0

    if echo "$manifest" | jq -e '.annotations["org.opencontainers.image.source"]' &>/dev/null; then
        log_info "${feature_id}: already annotated"
        return 0
    fi

    local updated media_type
    updated=$(echo "$manifest" | jq --arg src "$source_url" \
        '.annotations["org.opencontainers.image.source"] = $src')
    media_type=$(echo "$manifest" | jq -r '.mediaType')

    for tag in $tags; do
        echo "$updated" | oras manifest push \
            --media-type "$media_type" \
            "$ref:$tag" - 2>/dev/null
    done

    log_info "${feature_id}: annotated with source ${source_url}"
}

# Check that the published package has the expected visibility.
# GitHub's REST API has no PATCH endpoint for container package visibility;
# if the package is wrong, the user must fix it manually in the GitHub UI.
check_visibility() {
    local feature_id="$1"
    [[ $CAN_CHECK_VISIBILITY -eq 1 ]] || return 0

    local pkg_name="${NAMESPACE#*/}/${feature_id}"
    local encoded="${pkg_name//\//%2F}"

    local api_output current_visibility html_url
    if ! api_output=$(gh api "/user/packages/container/${encoded}" 2>&1); then
        log_error "${feature_id}: could not read package visibility"
        echo "$api_output" >&2
        return 0
    fi

    current_visibility=$(echo "$api_output" | jq -r '.visibility')
    if [[ "$current_visibility" == "$PACKAGE_VISIBILITY" ]]; then
        log_info "${feature_id}: visibility is ${PACKAGE_VISIBILITY}"
    else
        html_url=$(echo "$api_output" | jq -r '.html_url')
        log_error "${feature_id}: visibility is ${current_visibility}, expected ${PACKAGE_VISIBILITY}"
        echo "  Change it at: ${html_url}"
    fi
}

post_publish() {
    for dir in "$SRC_DIR"/*/; do
        [[ -f "$dir/devcontainer-feature.json" ]] || continue
        local feature_id
        feature_id=$(jq -r '.id' "$dir/devcontainer-feature.json")
        annotate_image "$feature_id"
        check_visibility "$feature_id"
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
    post_publish_setup

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

    post_publish

    log_success "Publish complete"
}

main "$@"
