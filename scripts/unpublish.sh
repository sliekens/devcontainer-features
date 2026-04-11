#!/usr/bin/env bash
#
# Unpublish a specific feature version from the OCI registry.
#
# Deletes the semver tags for a given version (e.g. 1.3.0 removes 1.3.0, 1.3,
# and potentially 1/latest if they point to the same manifest). Does NOT
# republish older versions — run repair.sh + publish.sh afterward if needed.
#
# Usage:
#   ./scripts/unpublish.sh <feature-id> <version>
#
# Examples:
#   ./scripts/unpublish.sh claude 1.3.0
#
# Requirements:
#   - oras: https://oras.land
#

set -euo pipefail

# Configuration
REGISTRY="${REGISTRY:-ghcr.io}"
NAMESPACE="${NAMESPACE:-sliekens/devcontainer-features}"

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

# Expand a semver string like "1.3.0" into its prefix tags: "1.3.0", "1.3", "1"
semver_tags() {
    local version="$1"
    local major minor patch
    IFS='.' read -r major minor patch <<< "$version"
    if [[ -n "${patch:-}" ]]; then
        echo "$major.$minor.$patch"
        echo "$major.$minor"
        echo "$major"
    elif [[ -n "${minor:-}" ]]; then
        echo "$major.$minor"
        echo "$major"
    else
        echo "$major"
    fi
}

main() {
    if [[ $# -ne 2 ]]; then
        echo "Usage: $0 <feature-id> <version>"
        echo "Example: $0 claude 1.3.0"
        exit 1
    fi

    local feature_id="$1"
    local version="$2"
    local ref="${REGISTRY}/${NAMESPACE}/${feature_id}"

    check_requirements

    log_info "Registry: ${REGISTRY}/${NAMESPACE}"
    log_info "Feature:  ${feature_id}"
    log_info "Version:  ${version}"

    # Resolve the digest for the target version tag
    local digest
    if ! digest=$(oras manifest fetch --descriptor "${ref}:${version}" 2>/dev/null | jq -r '.digest'); then
        log_error "Version ${version} not found in ${ref}"
        exit 1
    fi
    log_info "Manifest digest: ${digest}"

    # Find all tags that point to the same digest and warn about them
    local all_tags
    all_tags=$(oras repo tags "$ref" 2>/dev/null) || true

    local matching_tags=()
    for tag in $all_tags; do
        local tag_digest
        tag_digest=$(oras manifest fetch --descriptor "${ref}:${tag}" 2>/dev/null | jq -r '.digest') || continue
        if [[ "$tag_digest" == "$digest" ]]; then
            matching_tags+=("$tag")
        fi
    done

    if [[ ${#matching_tags[@]} -eq 0 ]]; then
        log_error "No tags found pointing to ${digest}"
        exit 1
    fi

    log_info "Tags to delete: ${matching_tags[*]}"

    local deleted_any=0
    for tag in "${matching_tags[@]}"; do
        if oras manifest delete --force "${ref}:${tag}" 2>/dev/null; then
            log_info "Deleted tag: ${tag}"
            deleted_any=1
        else
            log_warn "Failed to delete tag: ${tag} (may already be gone)"
        fi
    done

    if [[ $deleted_any -eq 1 ]]; then
        log_success "Unpublished ${feature_id}:${version}"
        log_warn "Run repair.sh + publish.sh if older versions need their tags (1, latest) restored"
    fi
}

main "$@"
