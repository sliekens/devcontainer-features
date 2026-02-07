#!/usr/bin/env bash
set -euo pipefail

REPO_OWNER="bitwarden"
REPO_NAME="clients"
INSTALL_DIR="/usr/local/bin"
PACKAGE_PLATFORM=""
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
    command -v unzip >/dev/null 2>&1 || missing+=("unzip")

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
        cli-v*)
            echo "${1#cli-v}"
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
    local requested_version="$1"

    if [ "$requested_version" = "latest" ]; then
        github_api_get "https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/releases/latest"
        return
    fi

    github_api_get "https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/releases/tags/cli-v${requested_version}"
}

map_platform() {
    if [ "$(uname -s)" != "Linux" ]; then
        echo "The Bitwarden CLI feature only supports Linux containers."
        exit 1
    fi

    case "$(uname -m)" in
        x86_64 | amd64)
            PACKAGE_PLATFORM="linux"
            ;;
        aarch64 | arm64)
            PACKAGE_PLATFORM="linux-arm64"
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

    local requested_version
    requested_version="$(normalize_version "${VERSION:-latest}")"

    local release_json
    release_json="$(resolve_release_json "$requested_version")"

    local release_tag
    release_tag="$(printf '%s' "$release_json" | jq -r '.tag_name // empty')"
    if [ -z "$release_tag" ] || [ "$release_tag" = "null" ]; then
        echo "Unable to resolve a Bitwarden CLI release."
        exit 1
    fi

    local release_version="${release_tag#cli-v}"
    if [ "$release_version" = "$release_tag" ]; then
        release_version="${release_tag#v}"
    fi

    local asset_name="bw-${PACKAGE_PLATFORM}-${release_version}.zip"
    local download_url
    download_url="$(printf '%s' "$release_json" | jq -r --arg asset "$asset_name" '.assets[] | select(.name == $asset) | .browser_download_url' | head -n 1)"

    if [ -z "$download_url" ] || [ "$download_url" = "null" ]; then
        echo "No compatible asset was found for ${PACKAGE_PLATFORM} in release ${release_tag}."
        echo "Expected asset: ${asset_name}"
        echo "Available assets:"
        printf '%s\n' "$release_json" | jq -r '.assets[].name'
        exit 1
    fi

    local tmp_dir
    tmp_dir="$(mktemp -d)"
    trap 'rm -rf "${tmp_dir:-}"' EXIT

    local archive_path="${tmp_dir}/${asset_name}"
    local binary_path="${tmp_dir}/bw"
    curl -fsSL "$download_url" -o "$archive_path"
    unzip -q "$archive_path" -d "$tmp_dir" bw

    if [ ! -f "$binary_path" ]; then
        echo "Download succeeded but the archive did not contain a 'bw' binary."
        exit 1
    fi

    install -d -m 0755 /usr/local/share/bitwarden-cli
    install -m 0755 "$SCRIPT_DIR/on_create.sh" /usr/local/share/bitwarden-cli/on_create.sh
    install -m 0755 "$binary_path" "${INSTALL_DIR}/bw"

    echo "Installed Bitwarden CLI ${release_version}."
    bw --version
}

main "$@"
