#!/bin/env bash
set -euo pipefail
set -x

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Ensure curl is available
if ! command -v curl &> /dev/null; then
    echo "Installing curl..."
    if command -v apt-get &> /dev/null; then
        apt-get update && apt-get install -y curl
    elif command -v apk &> /dev/null; then
        apk add --no-cache curl
    elif command -v dnf &> /dev/null; then
        dnf install -y curl
    elif command -v yum &> /dev/null; then
        yum install -y curl
    else
        echo "ERROR: Unable to install curl. Please install it manually."
        exit 1
    fi
fi

# Ensure libicu is available (required by .NET/Aspire)
if ! ldconfig -p | grep -q libicu 2>/dev/null; then
    echo "Installing libicu..."
    if command -v apt-get &> /dev/null; then
        apt-get update && apt-get install -y libicu-dev
    elif command -v apk &> /dev/null; then
        apk add --no-cache icu-libs
    elif command -v dnf &> /dev/null; then
        dnf install -y libicu
    elif command -v yum &> /dev/null; then
        yum install -y libicu
    fi
fi

ASPIRE_INSTALL_URL="https://aspire.dev/install.sh"
TARGET_SCRIPT="/tmp/aspire-install.sh"
QUALITY_OPTION="${QUALITY:-}"
VERSION_OPTION="${VERSION:-latest}"

curl --fail --silent --show-error --location "$ASPIRE_INSTALL_URL" --output "$TARGET_SCRIPT"

run_installer() {
    local args=(--install-path /usr/local/bin)
    if [[ -n "$QUALITY_OPTION" ]]; then
        args+=(--quality "$QUALITY_OPTION")
    fi
    if [[ "$VERSION_OPTION" != "latest" ]]; then
        args+=(--version "$VERSION_OPTION")
    fi
    bash "$TARGET_SCRIPT" "${args[@]}"
}

run_installer
echo "Aspire installer completed."

mkdir --parents /var/lib/aspire-cli

install -d -m 0755 /usr/local/share/aspire-cli
install -m 0755 "$SCRIPT_DIR/on_create.sh" /usr/local/share/aspire-cli/on_create.sh
