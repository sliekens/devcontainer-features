#!/usr/bin/env bash

set -euo pipefail

source dev-container-features-test-lib

check "pinned codex version" bash -lc 'codex --version | grep -F "codex-cli 0.114.0"'
check "bundled rg" /usr/local/bin/rg --version
check "codex state symlink" bash -lc '[ -L "$HOME/.codex" ] && [ "$(readlink "$HOME/.codex")" = "/var/lib/codex" ]'
check "codex state writable" bash -lc 'tmp="$HOME/.codex/.feature-test"; printf ok > "$tmp"; [ "$(cat /var/lib/codex/.feature-test)" = "ok" ]; rm -f "$tmp"'

reportResults
