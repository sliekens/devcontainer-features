#!/usr/bin/env bash

set -euo pipefail

GROK_STATE_DIR="/var/lib/grok-build"
GROK_HOME_LINK="$HOME/.grok"

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

ensure_state_dir "$GROK_STATE_DIR"

if [ -L "$GROK_HOME_LINK" ]; then
    if [ "$(readlink "$GROK_HOME_LINK")" = "$GROK_STATE_DIR" ]; then
        exit 0
    fi
    rm -f "$GROK_HOME_LINK"
elif [ -d "$GROK_HOME_LINK" ]; then
    run_privileged cp -an "$GROK_HOME_LINK/." "$GROK_STATE_DIR/"
    rm -rf "$GROK_HOME_LINK"
elif [ -e "$GROK_HOME_LINK" ]; then
    rm -f "$GROK_HOME_LINK"
fi

ln --symbolic --force --no-dereference "$GROK_STATE_DIR" "$GROK_HOME_LINK"