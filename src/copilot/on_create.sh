#!/usr/bin/env bash

set -euo pipefail

COPILOT_STATE_DIR="/var/lib/copilot"
COPILOT_HOME_LINK="$HOME/.copilot"

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

ensure_state_dir "$COPILOT_STATE_DIR"

if [ -L "$COPILOT_HOME_LINK" ]; then
    if [ "$(readlink "$COPILOT_HOME_LINK")" = "$COPILOT_STATE_DIR" ]; then
        exit 0
    fi
    rm -f "$COPILOT_HOME_LINK"
elif [ -d "$COPILOT_HOME_LINK" ]; then
    run_privileged cp -an "$COPILOT_HOME_LINK/." "$COPILOT_STATE_DIR/"
    rm -rf "$COPILOT_HOME_LINK"
elif [ -e "$COPILOT_HOME_LINK" ]; then
    rm -f "$COPILOT_HOME_LINK"
fi

ln --symbolic --force --no-dereference "$COPILOT_STATE_DIR" "$COPILOT_HOME_LINK"
