#!/usr/bin/env bash

set -euo pipefail

WORKTRUNK_CONFIG_DIR="/var/lib/worktrunk-config"
WORKTRUNK_CONFIG_LINK="$HOME/.config/worktrunk"

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

link_dir() {
    local state_dir="$1"
    local home_link="$2"
    local parent_dir

    parent_dir="$(dirname "$home_link")"
    mkdir -p "$parent_dir"

    if [ -L "$home_link" ]; then
        if [ "$(readlink "$home_link")" = "$state_dir" ]; then
            return 0
        fi
        rm -f "$home_link"
    elif [ -d "$home_link" ]; then
        cp -an "$home_link/." "$state_dir/"
        rm -rf "$home_link"
    elif [ -e "$home_link" ]; then
        rm -f "$home_link"
    fi

    ln --symbolic --force --no-dereference "$state_dir" "$home_link"
}

ensure_state_dir "$WORKTRUNK_CONFIG_DIR"
link_dir "$WORKTRUNK_CONFIG_DIR" "$WORKTRUNK_CONFIG_LINK"
