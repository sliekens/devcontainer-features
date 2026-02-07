#!/usr/bin/env bash

set -euo pipefail

run_privileged() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
    elif command -v sudo >/dev/null 2>&1; then
        sudo -n "$@"
    else
        "$@"
    fi
}

BITWARDEN_CONFIG_DIR="/home/vscode/.config/Bitwarden CLI"
run_privileged mkdir -p "$BITWARDEN_CONFIG_DIR"
run_privileged chown -R "$(id -u):$(id -g)" "$BITWARDEN_CONFIG_DIR"
run_privileged chmod 0700 "$BITWARDEN_CONFIG_DIR"
