#!/usr/bin/env bash
set -euo pipefail

REPO_OWNER="openai"
REPO_NAME="codex"
INSTALL_DIR="/usr/local/bin"
STATE_DIR="/var/lib/codex"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$(id -u)" -ne 0 ]; then
    echo "Script must run as root."
    exit 1
fi

ensure_packages() {
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update -y
        apt-get install -y --no-install-recommends "$@"
        rm -rf /var/lib/apt/lists/*
    elif command -v apk >/dev/null 2>&1; then
        apk add --no-cache "$@"
    elif command -v dnf >/dev/null 2>&1; then
        dnf install -y "$@"
    elif command -v yum >/dev/null 2>&1; then
        yum install -y "$@"
    else
        echo "Unsupported package manager. Install these packages manually: $*"
        exit 1
    fi
}

ensure_basics() {
    local missing=()

    command -v curl >/dev/null 2>&1 || missing+=("curl")
    command -v jq >/dev/null 2>&1 || missing+=("jq")
    command -v tar >/dev/null 2>&1 || missing+=("tar")

    if [ ! -d /etc/ssl/certs ] && [ ! -f /etc/ssl/cert.pem ]; then
        missing+=("ca-certificates")
    fi

    if [ "${#missing[@]}" -gt 0 ]; then
        ensure_packages "${missing[@]}"
    fi
}

normalize_version() {
    case "$1" in
        "" | latest)
            echo "latest"
            ;;
        rust-v*)
            echo "${1#rust-v}"
            ;;
        v*)
            echo "${1#v}"
            ;;
        *)
            echo "$1"
            ;;
    esac
}

github_api_get() {
    local url="$1"
    curl -fsSL \
        -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        "$url"
}

resolve_release_json() {
    local requested_version
    requested_version="$(normalize_version "${VERSION:-latest}")"

    if [ "$requested_version" = "latest" ]; then
        github_api_get "https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/releases/latest"
        return
    fi

    github_api_get "https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/releases/tags/rust-v${requested_version}"
}

map_platform() {
    if [ "$(uname -s)" != "Linux" ]; then
        echo "The codex feature only supports Linux containers."
        exit 1
    fi

    case "$(uname -m)" in
        x86_64 | amd64)
            PACKAGE_PLATFORM="linux-x64"
            VENDOR_TARGET="x86_64-unknown-linux-musl"
            ;;
        aarch64 | arm64)
            PACKAGE_PLATFORM="linux-arm64"
            VENDOR_TARGET="aarch64-unknown-linux-musl"
            ;;
        *)
            echo "Unsupported architecture: $(uname -m)"
            exit 1
            ;;
    esac
}

main() {
    ensure_basics
    map_platform

    install -d -m 0700 "$STATE_DIR"
    install -d -m 0755 /usr/local/share/codex

    local release_json
    release_json="$(resolve_release_json)"

    local release_tag
    release_tag="$(printf '%s' "$release_json" | jq -r '.tag_name // empty')"
    if [ -z "$release_tag" ]; then
        echo "Unable to resolve a Codex release tag."
        exit 1
    fi

    local release_version
    release_version="${release_tag#rust-v}"

    local asset_name="codex-npm-${PACKAGE_PLATFORM}-${release_version}.tgz"
    local download_url
    download_url="$(printf '%s' "$release_json" | jq -r --arg asset "$asset_name" '.assets[] | select(.name == $asset) | .browser_download_url' | head -n 1)"

    if [ -z "$download_url" ]; then
        echo "No compatible packaged Codex asset was found for ${PACKAGE_PLATFORM} in release ${release_tag}."
        printf '%s\n' "Available packaged assets:"
        printf '%s' "$release_json" | jq -r '.assets[].name | select(startswith("codex-npm-"))'
        exit 1
    fi

    local tmp_dir
    tmp_dir="$(mktemp -d)"
    trap 'rm -rf "${tmp_dir:-}"' EXIT

    local archive_path="${tmp_dir}/${asset_name}"
    curl -fsSL "$download_url" -o "$archive_path"
    tar -xzf "$archive_path" -C "$tmp_dir"

    local codex_source=""
    local rg_source=""

    # Upstream archive layout changed in newer releases; support both layouts.
    if [ -f "${tmp_dir}/package/vendor/${VENDOR_TARGET}/bin/codex" ]; then
        codex_source="${tmp_dir}/package/vendor/${VENDOR_TARGET}/bin/codex"
    elif [ -f "${tmp_dir}/package/vendor/${VENDOR_TARGET}/codex/codex" ]; then
        codex_source="${tmp_dir}/package/vendor/${VENDOR_TARGET}/codex/codex"
    fi

    if [ -f "${tmp_dir}/package/vendor/${VENDOR_TARGET}/codex-path/rg" ]; then
        rg_source="${tmp_dir}/package/vendor/${VENDOR_TARGET}/codex-path/rg"
    elif [ -f "${tmp_dir}/package/vendor/${VENDOR_TARGET}/path/rg" ]; then
        rg_source="${tmp_dir}/package/vendor/${VENDOR_TARGET}/path/rg"
    fi

    if [ -z "$codex_source" ] || [ -z "$rg_source" ]; then
        echo "Unexpected Codex archive layout for ${asset_name}."
        echo "Archive contents:"
        tar -tzf "$archive_path"
        exit 1
    fi

    install -m 0755 "$codex_source" "${INSTALL_DIR}/codex"
    install -m 0755 "$rg_source" "${INSTALL_DIR}/rg"
    install -m 0755 "$SCRIPT_DIR/on_create.sh" /usr/local/share/codex/on_create.sh

    codex --version
    rg --version | head -n 1
    echo "Installed Codex CLI ${release_version}."
}

main "$@"
