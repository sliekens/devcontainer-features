#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$(id -u)" -ne 0 ]; then
    echo "Script must run as root."
    exit 1
fi

ensure_packages() {
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update -y
        apt-get install -y --no-install-recommends "$@"
    elif command -v apk >/dev/null 2>&1; then
        apk add --no-cache "$@"
    elif command -v dnf >/dev/null 2>&1; then
        dnf install -y "$@"
    elif command -v yum >/dev/null 2>&1; then
        yum install -y "$@"
    else
        echo "Unsupported package manager. Please install required packages manually: $*"
        exit 1
    fi
}

ensure_basics() {
    if ! command -v curl >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
        ensure_packages curl jq ca-certificates
    fi
}

ensure_xz() {
    if command -v xz >/dev/null 2>&1; then
        return
    fi

    if command -v apt-get >/dev/null 2>&1; then
        ensure_packages xz-utils
    elif command -v apk >/dev/null 2>&1; then
        ensure_packages xz
    elif command -v dnf >/dev/null 2>&1; then
        ensure_packages xz
    elif command -v yum >/dev/null 2>&1; then
        ensure_packages xz
    else
        echo "xz is required to extract compressed tea release assets."
        exit 1
    fi
}

ensure_bash_completion() {
    if [ -f /usr/share/bash-completion/bash_completion ] || [ -f /etc/bash_completion ]; then
        return
    fi

    if command -v apt-get >/dev/null 2>&1; then
        ensure_packages bash-completion
    elif command -v apk >/dev/null 2>&1; then
        ensure_packages bash-completion
    elif command -v dnf >/dev/null 2>&1; then
        ensure_packages bash-completion
    elif command -v yum >/dev/null 2>&1; then
        ensure_packages bash-completion
    else
        echo "Unable to install bash-completion package for this distro."
        exit 1
    fi
}

install_completion_bash() {
    mkdir -p /etc/bash_completion.d

    cat > /etc/bash_completion.d/tea <<'EOS'
# shellcheck shell=bash
if command -v tea >/dev/null 2>&1; then
    eval "$(tea completion bash 2>/dev/null)" || true
fi
EOS

    chmod 0644 /etc/bash_completion.d/tea
}

install_completion_zsh() {
    local completion_script
    local wrote=0

    completion_script="$(tea completion zsh 2>/dev/null || true)"
    if [ -z "$completion_script" ]; then
        return
    fi

    for dir in \
        /usr/local/share/zsh/site-functions \
        /usr/share/zsh/site-functions \
        /usr/share/zsh/vendor-completions
    do
        if [ -d "$dir" ]; then
            printf '%s\n' "$completion_script" > "$dir/_tea"
            chmod 0644 "$dir/_tea"
            wrote=1
        fi
    done

    if [ "$wrote" -eq 0 ]; then
        mkdir -p /usr/local/share/zsh/site-functions
        printf '%s\n' "$completion_script" > /usr/local/share/zsh/site-functions/_tea
        chmod 0644 /usr/local/share/zsh/site-functions/_tea
    fi
}

map_arch() {
    case "$(uname -m)" in
        x86_64|amd64) echo "amd64" ;;
        aarch64|arm64) echo "arm64" ;;
        armv7l|armv7) echo "arm-7" ;;
        armv6l|armv6) echo "arm-6" ;;
        armv5*|armv5) echo "arm-5" ;;
        *)
            echo "Unsupported architecture: $(uname -m)"
            exit 1
            ;;
    esac
}

fetch_release() {
    local requested_version="$1"
    local api_base="https://gitea.com/api/v1/repos/gitea/tea/releases"

    if [ "$requested_version" = "latest" ] || [ -z "$requested_version" ]; then
        curl -fsSL "${api_base}/latest"
        return
    fi

    local normalized="${requested_version#v}"
    curl -fsSL "${api_base}/tags/v${normalized}"
}

main() {
    ensure_basics
    ensure_bash_completion

    mkdir --parents /var/lib/tea-cli

    local requested_version="${VERSION:-latest}"
    local release_json

    if ! release_json="$(fetch_release "$requested_version")"; then
        echo "Failed to fetch release metadata for tea version: $requested_version"
        exit 1
    fi

    local release_tag
    release_tag="$(printf '%s' "$release_json" | jq -r '.tag_name // empty')"
    if [ -z "$release_tag" ]; then
        echo "Unable to resolve a release tag for tea."
        exit 1
    fi

    local release_version="${release_tag#v}"
    local arch
    arch="$(map_arch)"
    local base_asset_name="tea-${release_version}-linux-${arch}"

    local download_url
    download_url="$(printf '%s' "$release_json" | jq -r --arg asset "$base_asset_name" '.assets[] | select(.name == $asset) | .browser_download_url' | head -n 1)"

    local download_url_xz
    download_url_xz="$(printf '%s' "$release_json" | jq -r --arg asset "${base_asset_name}.xz" '.assets[] | select(.name == $asset) | .browser_download_url' | head -n 1)"

    if [ -z "$download_url" ] && [ -z "$download_url_xz" ]; then
        echo "No compatible linux asset found for ${base_asset_name} in release ${release_tag}."
        echo "Available assets:"
        printf '%s' "$release_json" | jq -r '.assets[].name'
        exit 1
    fi

    tmp_dir="$(mktemp -d)"
    trap 'if [ -n "${tmp_dir:-}" ]; then rm -rf "${tmp_dir}"; fi' EXIT

    if [ -n "$download_url" ]; then
        curl -fsSL "$download_url" -o "${tmp_dir}/tea"
    else
        ensure_xz
        curl -fsSL "$download_url_xz" -o "${tmp_dir}/tea.xz"
        xz -dc "${tmp_dir}/tea.xz" > "${tmp_dir}/tea"
    fi

    install -m 0755 "${tmp_dir}/tea" /usr/local/bin/tea
    install_completion_bash
    install_completion_zsh
    install -d -m 0755 /usr/local/share/tea
    install -m 0755 "$SCRIPT_DIR/on_create.sh" /usr/local/share/tea/on_create.sh

    tea --version
    echo "Installed tea ${release_tag}."
}

main "$@"
