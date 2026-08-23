#!/usr/bin/env bash

set -euo pipefail

source dev-container-features-test-lib

check "agent binary available" command -v agent
check "cursor-agent binary available" command -v cursor-agent
check "agent version runs" bash -lc 'agent --version | head -n 1'
check "cursor-agent version runs" bash -lc 'cursor-agent --version | head -n 1'
check "agent version format" bash -lc 'agent --version | grep -Eq "^[0-9]{4}\\.[0-9]{2}\\.[0-9]{2}-[0-9a-f]+$"'
check "agent and cursor-agent are the same target" bash -lc '[ "$(readlink -f "$(command -v agent)")" = "$(readlink -f "$(command -v cursor-agent)")" ]'
check "cursor state is linked" bash -lc '[ -L "$HOME/.cursor" ] && [ "$(readlink "$HOME/.cursor")" = "/var/lib/cursor-agent" ]'
check "cursor state writable" bash -lc 'tmp="$HOME/.cursor/.feature-test"; printf ok > "$tmp"; [ "$(cat /var/lib/cursor-agent/.feature-test)" = "ok" ]; rm -f "$tmp"'
check "file credential store" bash -lc '[ "${AGENT_CLI_CREDENTIAL_STORE:-}" = "file" ]'
check "package is executable" bash -lc 'test -f /usr/local/lib/cursor-agent/cursor-agent && test -x /usr/local/lib/cursor-agent/cursor-agent'

reportResults
