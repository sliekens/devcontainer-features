#!/usr/bin/env bash
#
# Run tests for devcontainer features.
#
# This script wraps the devcontainer CLI's feature test command.
#
# Usage:
#   ./scripts/test.sh [feature-id] [options]
#
# Examples:
#   ./scripts/test.sh              # Test all features
#   ./scripts/test.sh ansible       # Test only the 'ansible' feature
#   ./scripts/test.sh ansible -i ubuntu:latest  # Test against specific base image
#
# Requirements:
#   - Node.js (for @devcontainers/cli)
#   - @devcontainers/cli: npm install -g @devcontainers/cli
#   - Docker or Podman
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

has_arg() {
    local needle="$1"
    shift
    local arg
    for arg in "$@"; do
        if [[ "$arg" == "$needle" ]]; then
            return 0
        fi
    done
    return 1
}

# Return success if command arguments already include an explicit base image.
has_image_arg() {
    local arg
    for arg in "$@"; do
        if [[ "$arg" == "-i" || "$arg" == "--base-image" ]]; then
            return 0
        fi
    done
    return 1
}

# Build test args, defaulting to the devcontainers Ubuntu base image when no image is explicitly provided.
build_test_args() {
    local args=("$@")
    if ! has_image_arg "${args[@]}"; then
        args+=("-i" "mcr.microsoft.com/devcontainers/base:ubuntu")
    fi
    printf '%s\n' "${args[@]}"
}

# Check required tools
check_requirements() {
    if ! command -v devcontainer &> /dev/null; then
        log_error "devcontainer CLI not found"
        echo "Install with: npm install -g @devcontainers/cli"
        exit 1
    fi
    
    if ! command -v docker &> /dev/null && ! command -v podman &> /dev/null; then
        log_error "Docker or Podman required for testing"
        exit 1
    fi
}

# Pre-create bind mount source directories declared in a feature's devcontainer-feature.json.
# Features may declare bind mounts with source="${localEnv:HOME}/..." which require the host
# directories to exist before Docker can mount them (Docker won't create intermediate directories).
pre_create_bind_mount_sources() {
    local feature_id="$1"
    local feature_json="$REPO_ROOT/src/$feature_id/devcontainer-feature.json"
    [[ -f "$feature_json" ]] || return 0

    local sources
    mapfile -t sources < <(
        jq -r '.mounts[]? | select(.type == "bind") | .source' "$feature_json" 2>/dev/null \
            | sed "s|\${localEnv:HOME}|$HOME|g"
    )

    for src in "${sources[@]}"; do
        local is_dir=false
        if [[ "$src" == */ ]]; then
            is_dir=true
            src="${src%/}"
        fi
        if [[ "$src" == /* ]] && [[ ! -e "$src" ]]; then
            log_info "Pre-creating bind mount source: $src"
            if $is_dir; then
                mkdir -p "$src"
            else
                mkdir -p "$(dirname "$src")"
                touch "$src"
            fi
        fi
    done
}

# Remove docker images and temp dirs produced by `devcontainer features test`.
# Safe patterns only — does not touch host bind-mount sources under $HOME.
cleanup_test_artifacts() {
    log_info "Cleaning up test artifacts..."

    local images=()
    mapfile -t images < <(
        {
            docker images --format '{{.Repository}}:{{.Tag}}' 2>/dev/null || true
            podman images --format '{{.Repository}}:{{.Tag}}' 2>/dev/null || true
        } | awk '/^vsc-.*-features(-uid)?(:|$)/ { print }' | sort -u
    )

    if [[ ${#images[@]} -gt 0 ]]; then
        log_info "Removing ${#images[@]} test image(s)..."
        # Prefer docker; fall back to podman if docker is absent.
        if command -v docker >/dev/null 2>&1; then
            docker rmi -f "${images[@]}" >/dev/null 2>&1 || true
        elif command -v podman >/dev/null 2>&1; then
            podman rmi -f "${images[@]}" >/dev/null 2>&1 || true
        fi
    fi

    # Workspace folders created for feature tests.
    if [[ -d /tmp/devcontainercli/container-features-test ]]; then
        log_info "Removing /tmp/devcontainercli/container-features-test"
        rm -rf /tmp/devcontainercli/container-features-test
    fi

    # Per-user CLI cache of unpacked feature packages from tests.
    # Keep updateUID Dockerfiles and control-manifest if present.
    local cli_cache
    for cli_cache in /tmp/devcontainercli /tmp/devcontainercli-"${USER:-}"; do
        if [[ -d "$cli_cache/container-features" ]]; then
            log_info "Removing $cli_cache/container-features"
            rm -rf "$cli_cache/container-features"
        fi
        if [[ -d "$cli_cache/empty-folder" ]]; then
            rm -rf "$cli_cache/empty-folder"
        fi
    done

    log_success "Test artifact cleanup complete"
}

run_feature_test() {
    # Runs a single `devcontainer features test` invocation.
    # On failure: logs the feature id (if provided) and returns non-zero.
    # Does not abort the suite — callers accumulate failures.
    local label="$1"
    shift

    if devcontainer features test "$@"; then
        return 0
    fi
    log_error "Tests failed: $label"
    return 1
}

# Main function
main() {
    local feature_filter=""
    if [[ $# -gt 0 && "${1}" != -* ]]; then
        feature_filter="$1"
        shift
    fi
    local extra_args=("$@")
    local failed=0

    local log_level_args=()
    if [[ "${TRACE:-}" == "1" ]]; then
        log_level_args=(--log-level trace)
    elif [[ "${DEBUG:-}" == "1" ]]; then
        log_level_args=(--log-level debug)
    fi

    check_requirements
    
    cd "$REPO_ROOT"
    
    if [[ -n "$feature_filter" ]]; then
        log_info "Testing feature: $feature_filter"
        pre_create_bind_mount_sources "$feature_filter"
        mapfile -t test_args < <(build_test_args "${extra_args[@]}")
        if ! run_feature_test "$feature_filter" \
            --project-folder . \
            -f "$feature_filter" \
            "${log_level_args[@]}" \
            "${test_args[@]}"; then
            failed=1
        fi
    else
        log_info "Testing all features..."
        mapfile -t test_args < <(build_test_args "${extra_args[@]}")

        if has_arg "--global-scenarios-only" "${test_args[@]}"; then
            log_info "Running global scenario tests only..."
            if ! run_feature_test "global-scenarios" \
                --project-folder . \
                "${log_level_args[@]}" \
                "${test_args[@]}"; then
                failed=1
            fi
        else
            # Run autogenerated tests
            for feature_dir in src/*/; do
                if [[ -f "$feature_dir/devcontainer-feature.json" ]]; then
                    local feature_id
                    feature_id=$(basename "$feature_dir")
                    pre_create_bind_mount_sources "$feature_id"
                    log_info "Testing $feature_id..."
                    if ! run_feature_test "$feature_id (autogenerated)" \
                        --project-folder . \
                        -f "$feature_id" \
                        --skip-scenarios \
                        "${log_level_args[@]}" \
                        "${test_args[@]}"; then
                        failed=1
                    fi
                fi
            done

            # Run scenario tests
            log_info "Running scenario tests..."
            for feature_dir in src/*/; do
                if [[ -f "$feature_dir/devcontainer-feature.json" ]]; then
                    local feature_id
                    feature_id=$(basename "$feature_dir")
                    pre_create_bind_mount_sources "$feature_id"
                    if ! run_feature_test "$feature_id (scenarios)" \
                        --project-folder . \
                        -f "$feature_id" \
                        --skip-autogenerated \
                        --skip-duplicated \
                        "${log_level_args[@]}" \
                        "${test_args[@]}"; then
                        failed=1
                    fi
                fi
            done

            # Run global scenario tests
            log_info "Running global scenario tests..."
            if ! run_feature_test "global-scenarios" \
                --project-folder . \
                --global-scenarios-only \
                "${log_level_args[@]}" \
                "${test_args[@]}"; then
                failed=1
            fi
        fi
    fi

    if [[ "$failed" -ne 0 ]]; then
        log_error "Testing finished with failures (artifacts kept for debugging)"
        exit 1
    fi

    log_success "Testing complete!"
    cleanup_test_artifacts
}

main "$@"
