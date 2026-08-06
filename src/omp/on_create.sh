#!/usr/bin/env bash

set -euo pipefail

OMP_STATE_DIR="/var/lib/omp"
OMP_HOME_LINK="$HOME/.omp"

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

ensure_state_dir "$OMP_STATE_DIR"

if [ -L "$OMP_HOME_LINK" ]; then
    if [ "$(readlink "$OMP_HOME_LINK")" = "$OMP_STATE_DIR" ]; then
        exit 0
    fi
    rm -f "$OMP_HOME_LINK"
elif [ -d "$OMP_HOME_LINK" ]; then
    run_privileged cp -an "$OMP_HOME_LINK/." "$OMP_STATE_DIR/"
    rm -rf "$OMP_HOME_LINK"
elif [ -e "$OMP_HOME_LINK" ]; then
    rm -f "$OMP_HOME_LINK"
fi

ln --symbolic --force --no-dereference "$OMP_STATE_DIR" "$OMP_HOME_LINK"
