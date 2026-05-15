#!/usr/bin/env bash

set -euo pipefail

AAC_STATE_DIR="/var/lib/bitwarden-agent-access"
AAC_HOME_LINK="$HOME/.access-protocol"

run_privileged() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
    elif command -v sudo >/dev/null 2>&1; then
        sudo -n "$@"
    else
        "$@"
    fi
}

run_privileged install -d -m 0700 "$AAC_STATE_DIR"
run_privileged chown -R "$(id -u):$(id -g)" "$AAC_STATE_DIR"
run_privileged chmod 0700 "$AAC_STATE_DIR"

if [ -L "$AAC_HOME_LINK" ]; then
    if [ "$(readlink "$AAC_HOME_LINK")" = "$AAC_STATE_DIR" ]; then
        exit 0
    fi
    rm -f "$AAC_HOME_LINK"
elif [ -d "$AAC_HOME_LINK" ]; then
    run_privileged cp -an "$AAC_HOME_LINK/." "$AAC_STATE_DIR/"
    rm -rf "$AAC_HOME_LINK"
elif [ -e "$AAC_HOME_LINK" ]; then
    rm -f "$AAC_HOME_LINK"
fi

run_privileged ln --symbolic --force --no-dereference "$AAC_STATE_DIR" "$AAC_HOME_LINK"
