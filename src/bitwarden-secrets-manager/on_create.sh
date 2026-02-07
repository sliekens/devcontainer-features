#!/usr/bin/env bash

set -euo pipefail

BWS_STATE_DIR="/var/lib/bitwarden-secrets-manager"
BWS_HOME_LINK="$HOME/.config/bws"

run_privileged() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
    elif command -v sudo >/dev/null 2>&1; then
        sudo -n "$@"
    else
        "$@"
    fi
}

run_privileged install -d -m 0700 "$BWS_STATE_DIR"
run_privileged chown -R "$(id -u):$(id -g)" "$BWS_STATE_DIR"
run_privileged chmod 0700 "$BWS_STATE_DIR"

if [ -L "$BWS_HOME_LINK" ]; then
    if [ "$(readlink "$BWS_HOME_LINK")" = "$BWS_STATE_DIR" ]; then
        exit 0
    fi
    rm -f "$BWS_HOME_LINK"
elif [ -d "$BWS_HOME_LINK" ]; then
    run_privileged cp -an "$BWS_HOME_LINK/." "$BWS_STATE_DIR/"
    rm -rf "$BWS_HOME_LINK"
elif [ -e "$BWS_HOME_LINK" ]; then
    rm -f "$BWS_HOME_LINK"
fi

run_privileged ln --symbolic --force --no-dereference "$BWS_STATE_DIR" "$BWS_HOME_LINK"
