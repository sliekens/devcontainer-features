#!/usr/bin/env bash

set -euo pipefail

VIBE_STATE_DIR="/var/lib/vibe"
VIBE_HOME_LINK="$HOME/.vibe"

run_privileged() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
    elif command -v sudo >/dev/null 2>&1; then
        sudo -n "$@"
    else
        "$@"
    fi
}

enable_state_dir() {
    local dir="$1"
    run_privileged install -d -m 0700 "$dir"
    run_privileged chown -R "$(id -u):$(id -g)" "$dir"
    run_privileged chmod 0700 "$dir"
}

enable_state_dir "$VIBE_STATE_DIR"

if [ -L "$VIBE_HOME_LINK" ]; then
    if [ "$(readlink "$VIBE_HOME_LINK")" = "$VIBE_STATE_DIR" ]; then
        exit 0
    fi
    rm -f "$VIBE_HOME_LINK"
elif [ -d "$VIBE_HOME_LINK" ]; then
    run_privileged cp -an "$VIBE_HOME_LINK/." "$VIBE_STATE_DIR/"
    rm -rf "$VIBE_HOME_LINK"
elif [ -e "$VIBE_HOME_LINK" ]; then
    rm -f "$VIBE_HOME_LINK"
fi

ln --symbolic --force --no-dereference "$VIBE_STATE_DIR" "$VIBE_HOME_LINK"