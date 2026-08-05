#!/usr/bin/env bash

set -euo pipefail

PI_STATE_DIR="/var/lib/pi"
PI_HOME_LINK="$HOME/.pi"

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

ensure_state_dir "$PI_STATE_DIR"

if [ -L "$PI_HOME_LINK" ]; then
    if [ "$(readlink "$PI_HOME_LINK")" = "$PI_STATE_DIR" ]; then
        exit 0
    fi
    rm -f "$PI_HOME_LINK"
elif [ -d "$PI_HOME_LINK" ]; then
    run_privileged cp -an "$PI_HOME_LINK/." "$PI_STATE_DIR/"
    rm -rf "$PI_HOME_LINK"
elif [ -e "$PI_HOME_LINK" ]; then
    rm -f "$PI_HOME_LINK"
fi

ln --symbolic --force --no-dereference "$PI_STATE_DIR" "$PI_HOME_LINK"
