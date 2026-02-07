#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="/usr/local/bin"
STATE_DIR="/var/lib/claude"
CLAUDE_INSTALLER_URL="https://claude.ai/install.sh"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$(id -u)" -ne 0 ]; then
    echo "Script must run as root."
    exit 1
fi

install_packages() {
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

    if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
        missing+=("curl")
    fi

    if ! command -v sha256sum >/dev/null 2>&1 && ! command -v shasum >/dev/null 2>&1; then
        # coreutils includes sha256sum on most Debian/Alpine-family images
        missing+=("coreutils")
    fi

    if [ ! -d /etc/ssl/certs ] && [ ! -f /etc/ssl/cert.pem ]; then
        missing+=("ca-certificates")
    fi

    if [ "${#missing[@]}" -gt 0 ]; then
        install_packages "${missing[@]}"
    fi
}

download_installer() {
    local destination="$1"
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$CLAUDE_INSTALLER_URL" -o "$destination"
    else
        wget -q -O "$destination" "$CLAUDE_INSTALLER_URL"
    fi
}

run_claude_install() {
    local version="$1"
    local installer_path

    installer_path="$(mktemp)"
    download_installer "$installer_path"
    chmod 0755 "$installer_path"
    HOME="$STATE_DIR" bash "$installer_path" "$version"
    rm -f "$installer_path"
}

install_binary_link() {
    local source_cli
    local target_cli="${INSTALL_DIR}/claude"

    source_cli="${STATE_DIR}/.local/bin/claude"
    if [ ! -f "$source_cli" ]; then
        echo "Claude installer did not produce ${source_cli}."
        exit 1
    fi

    ln -sf "$source_cli" "$target_cli"
}

main() {
    local version="${VERSION:-stable}"

    ensure_basics
    install -d -m 0700 "$STATE_DIR"
    install -d -m 0755 /usr/local/share/claude

    run_claude_install "$version"
    install_binary_link
    install -m 0755 "$SCRIPT_DIR/on_create.sh" /usr/local/share/claude/on_create.sh

    echo "Installed Claude CLI (${version})"
    "${INSTALL_DIR}/claude" --version
}

main "$@"
