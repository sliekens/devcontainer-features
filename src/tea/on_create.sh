#!/usr/bin/env bash

set -euo pipefail

TEA_CONFIG_DIR="/var/lib/tea-cli"

if command -v sudo >/dev/null 2>&1; then
    sudo chown -R "$(id -u):$(id -g)" "$TEA_CONFIG_DIR" 2>/dev/null || chown -R "$(id -u):$(id -g)" "$TEA_CONFIG_DIR"
else
    chown -R "$(id -u):$(id -g)" "$TEA_CONFIG_DIR"
fi

mkdir --parents "$HOME/.config"
ln --symbolic --force --no-dereference "$TEA_CONFIG_DIR" "$HOME/.config/tea"
