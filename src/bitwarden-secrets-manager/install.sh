#!/usr/bin/env bash
set -euo pipefail

REPO_OWNER="bitwarden"
REPO_NAME="sdk"
INSTALL_DIR="/usr/local/bin"
STATE_DIR="/var/lib/bitwarden-secrets-manager"
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
        bws-v*)
            echo "${1#bws-v}"
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
        local releases_json
        releases_json="$(github_api_get "https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/releases?per_page=100")"

        local latest_bws_tag
        latest_bws_tag="$(printf '%s' "$releases_json" | jq -r '[.[] | select(.tag_name | startswith("bws-v"))][0] .tag_name // empty')"

        if [ -z "$latest_bws_tag" ] || [ "$latest_bws_tag" = "null" ]; then
            echo "Unable to resolve the latest Bitwarden Secrets Manager CLI release from ${REPO_OWNER}/${REPO_NAME}."
            exit 1
        fi

        github_api_get "https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/releases/tags/${latest_bws_tag}"
        return
    fi

    github_api_get "https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/releases/tags/bws-v${requested_version}"
}

map_platform() {
    if [ "$(uname -s)" != "Linux" ]; then
        echo "The Bitwarden Secrets Manager CLI feature only supports Linux containers."
        exit 1
    fi

    case "$(uname -m)" in
        x86_64 | amd64)
            PACKAGE_PLATFORM="x86_64"
            ;;
        aarch64 | arm64)
            PACKAGE_PLATFORM="aarch64"
            ;;
        *)
            echo "Unsupported architecture: $(uname -m)"
            exit 1
            ;;
    esac
}

resolve_asset_url() {
    local release_json="$1"
    local version="$2"
    local asset_name=""
    local download_url=""

    for variant in gnu musl; do
        asset_name="bws-${PACKAGE_PLATFORM}-unknown-linux-${variant}-${version}.zip"
        download_url="$(printf '%s' "$release_json" | jq -r --arg asset "$asset_name" '.assets[] | select(.name == $asset) | .browser_download_url' | head -n 1)"

        if [ -n "$download_url" ] && [ "$download_url" != "null" ]; then
            printf '%s\n' "$asset_name $download_url"
            return 0
        fi
    done

    printf '%s\n' ""
    return 1
}

main() {
    ensure_basics
    map_platform

    install -d -m 0700 "$STATE_DIR"
    install -d -m 0755 /usr/local/share/bitwarden-secrets-manager

    local requested_version
    requested_version="$(normalize_version "${VERSION:-latest}")"

    local release_json
    release_json="$(resolve_release_json "$requested_version")"

    local release_tag
    release_tag="$(printf '%s' "$release_json" | jq -r '.tag_name // empty')"
    if [ -z "$release_tag" ] || [ "$release_tag" = "null" ]; then
        echo "Unable to resolve a Bitwarden Secrets Manager CLI release."
        exit 1
    fi

    local release_version="${release_tag#bws-v}"
    if [ "$release_version" = "$release_tag" ]; then
        release_version="${release_tag#v}"
    fi

    local asset_and_url
    local selected_asset
    local download_url

    if ! asset_and_url="$(resolve_asset_url "$release_json" "$release_version")"; then
        echo "No compatible Linux asset was found for platform ${PACKAGE_PLATFORM} in release ${release_tag}."
        echo "Expected assets include:" 
        printf '%s\n' "  bws-${PACKAGE_PLATFORM}-unknown-linux-gnu-${release_version}.zip"
        printf '%s\n' "  bws-${PACKAGE_PLATFORM}-unknown-linux-musl-${release_version}.zip"
        echo "Available assets:"
        printf '%s' "$release_json" | jq -r '.assets[].name'
        exit 1
    fi

    selected_asset="${asset_and_url%% *}"
    download_url="${asset_and_url#* }"

    local tmp_dir
    tmp_dir="$(mktemp -d)"
    trap 'rm -rf "${tmp_dir:-}"' EXIT

    local archive_path="${tmp_dir}/${selected_asset}"
    local binary_path="${tmp_dir}/bws"

    curl -fsSL "$download_url" -o "$archive_path"
    unzip -q "$archive_path" -d "$tmp_dir" bws

    if [ ! -f "$binary_path" ]; then
        echo "Download succeeded but the archive did not contain a 'bws' binary."
        exit 1
    fi

    install -m 0755 "$binary_path" "${INSTALL_DIR}/bws"
    install -m 0755 "$SCRIPT_DIR/on_create.sh" /usr/local/share/bitwarden-secrets-manager/on_create.sh

    bws --version
    echo "Installed Bitwarden Secrets Manager CLI ${release_version}."
}

main "$@"
