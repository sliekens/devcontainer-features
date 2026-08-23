#!/usr/bin/env bash

set -euo pipefail

CURSOR_STATE_DIR="/var/lib/cursor-agent"
CURSOR_HOME_LINK="$HOME/.cursor"

run_privileged() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
    elif command -v sudo >/dev/null 2>&1; then
        sudo -n "$@"
    else
        "$@"
    fi
}

ensure_state_dir() {
    local dir="$1"
    run_privileged install -d -m 0700 "$dir"
    run_privileged chown -R "$(id -u):$(id -g)" "$dir"
    run_privileged chmod 0700 "$dir"
}

ensure_state_dir "$CURSOR_STATE_DIR"

if [ -L "$CURSOR_HOME_LINK" ]; then
    if [ "$(readlink "$CURSOR_HOME_LINK")" = "$CURSOR_STATE_DIR" ]; then
        exit 0
    fi
    rm -f "$CURSOR_HOME_LINK"
elif [ -d "$CURSOR_HOME_LINK" ]; then
    run_privileged cp -an "$CURSOR_HOME_LINK/." "$CURSOR_STATE_DIR/"
    rm -rf "$CURSOR_HOME_LINK"
elif [ -e "$CURSOR_HOME_LINK" ]; then
    rm -f "$CURSOR_HOME_LINK"
fi

ln --symbolic --force --no-dereference "$CURSOR_STATE_DIR" "$CURSOR_HOME_LINK"
