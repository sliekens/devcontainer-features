#!/usr/bin/env bash
set -euo pipefail

GROK_INSTALLER_URL="https://x.ai/cli/install.sh"
INSTALL_DIR="/usr/local/bin"
STATE_DIR="/var/lib/grok-build"
CONTAINER_HOME="/var/lib/grok-container"
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
        curl -fsSL "$GROK_INSTALLER_URL" -o "$destination"
    else
        wget -q -O "$destination" "$GROK_INSTALLER_URL"
    fi
}

normalize_version() {
    case "$1" in
        "" | latest)
            echo ""
            ;;
        v*)
            echo "${1#v}"
            ;;
        *)
            echo "$1"
            ;;
    esac
}

prepare_install_home() {
    install -d -m 0755 "$CONTAINER_HOME"
    chown "${_REMOTE_USER:-root}:${_REMOTE_USER:-root}" "$CONTAINER_HOME"
    ln -snf "$STATE_DIR" "${CONTAINER_HOME}/.grok"
}

run_grok_install() {
    local version="$1"
    local channel="$2"
    local installer_path

    installer_path="$(mktemp)"
    download_installer "$installer_path"
    chmod 0755 "$installer_path"

    if [ -n "$version" ]; then
        HOME="$CONTAINER_HOME" GROK_CHANNEL="$channel" bash "$installer_path" "$version"
    else
        HOME="$CONTAINER_HOME" GROK_CHANNEL="$channel" bash "$installer_path"
    fi

    rm -f "$installer_path"
}

install_binaries() {
    local source_grok="${STATE_DIR}/bin/grok"

    if [ ! -e "$source_grok" ]; then
        echo "Grok installer did not produce ${source_grok}."
        exit 1
    fi

    rm -f "${INSTALL_DIR}/grok" "${INSTALL_DIR}/agent"
    install -m 0755 "$(readlink -f "$source_grok")" "${INSTALL_DIR}/grok"
    ln -sf grok "${INSTALL_DIR}/agent"
}

main() {
    local version
    local channel="${CHANNEL:-stable}"

    version="$(normalize_version "${VERSION:-latest}")"

    ensure_basics
    install -d -m 0755 "$STATE_DIR"
    chown "${_REMOTE_USER:-root}:${_REMOTE_USER:-root}" "$STATE_DIR"
    install -d -m 0755 /usr/local/share/grok-build
    prepare_install_home

    run_grok_install "$version" "$channel"
    install_binaries
    install -m 0755 "$SCRIPT_DIR/on_create.sh" /usr/local/share/grok-build/on_create.sh

    echo "Installed Grok Build CLI (${version:-latest}, channel: ${channel})"
    "${INSTALL_DIR}/grok" --version
}

main "$@"