#!/usr/bin/env bash

set -euo pipefail

CODEX_STATE_DIR="/var/lib/codex"
CODEX_HOME_LINK="$HOME/.codex"

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

ensure_state_dir "$CODEX_STATE_DIR"

if [ -L "$CODEX_HOME_LINK" ]; then
    if [ "$(readlink "$CODEX_HOME_LINK")" = "$CODEX_STATE_DIR" ]; then
        exit 0
    fi
    rm -f "$CODEX_HOME_LINK"
elif [ -d "$CODEX_HOME_LINK" ]; then
    cp -an "$CODEX_HOME_LINK/." "$CODEX_STATE_DIR/"
    rm -rf "$CODEX_HOME_LINK"
elif [ -e "$CODEX_HOME_LINK" ]; then
    rm -f "$CODEX_HOME_LINK"
fi

ln --symbolic --force --no-dereference "$CODEX_STATE_DIR" "$CODEX_HOME_LINK"
