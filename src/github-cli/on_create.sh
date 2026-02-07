#!/usr/bin/env bash

set -euo pipefail

GH_CONFIG_DIR="/var/lib/github-cli/config"
GH_STATE_DIR="/var/lib/github-cli/state"

if command -v sudo >/dev/null 2>&1; then
    sudo chown -R "$(id -u):$(id -g)" "$GH_CONFIG_DIR" "$GH_STATE_DIR" 2>/dev/null || chown -R "$(id -u):$(id -g)" "$GH_CONFIG_DIR" "$GH_STATE_DIR"
else
    chown -R "$(id -u):$(id -g)" "$GH_CONFIG_DIR" "$GH_STATE_DIR"
fi

mkdir --parents "$HOME/.config" "$HOME/.local/share"
ln --symbolic --force --no-dereference "$GH_CONFIG_DIR" "$HOME/.config/gh"
ln --symbolic --force --no-dereference "$GH_STATE_DIR" "$HOME/.local/share/gh"
