#!/usr/bin/env bash

set -euo pipefail

ASPIRE_STATE_DIR="/var/lib/aspire-cli"

if command -v sudo >/dev/null 2>&1; then
    sudo chown -R "$(id -u):$(id -g)" "$ASPIRE_STATE_DIR" 2>/dev/null || chown -R "$(id -u):$(id -g)" "$ASPIRE_STATE_DIR"
else
    chown -R "$(id -u):$(id -g)" "$ASPIRE_STATE_DIR"
fi

ln --symbolic --force --no-dereference "$ASPIRE_STATE_DIR" "$HOME/.aspire"
