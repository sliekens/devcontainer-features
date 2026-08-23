#!/usr/bin/env bash

set -euo pipefail

source dev-container-features-test-lib

check "pinned agent version" bash -lc 'agent --version | grep -Fx "2026.08.11-e8db854"'
check "pinned cursor-agent version" bash -lc 'cursor-agent --version | grep -Fx "2026.08.11-e8db854"'
check "cursor state symlink" bash -lc '[ -L "$HOME/.cursor" ] && [ "$(readlink "$HOME/.cursor")" = "/var/lib/cursor-agent" ]'
check "cursor state writable" bash -lc 'tmp="$HOME/.cursor/.feature-test"; printf ok > "$tmp"; [ "$(cat /var/lib/cursor-agent/.feature-test)" = "ok" ]; rm -f "$tmp"'

reportResults
