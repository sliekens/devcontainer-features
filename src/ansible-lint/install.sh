#!/usr/bin/env bash
set -euo pipefail
umask 0002

if command -v pipx >/dev/null 2>&1; then
    pipx install ansible-lint
    pipx inject ansible-lint ansible-core
elif command -v pip3 >/dev/null 2>&1; then
    pip3 install --no-cache-dir --upgrade --break-system-packages ansible-lint
elif command -v pip >/dev/null 2>&1; then
    pip install --no-cache-dir --upgrade --break-system-packages ansible-lint
else
    echo "ERROR: pip is not available. This feature depends on ghcr.io/devcontainers/features/python:1."
    exit 1
fi
