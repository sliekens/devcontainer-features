#!/usr/bin/env bash

set -euo pipefail

source dev-container-features-test-lib

check "claude binary available" command -v claude
check "claude version runs" bash -lc 'claude --version | head -n 1'
check "user is testuser" bash -c '[ "$(whoami)" = "testuser" ]'
check "claude state is linked" bash -lc '[ -L "$HOME/.claude" ] && [ "$(readlink "$HOME/.claude")" = "/var/lib/claude-container/data" ]'
check "claude state dir owned by testuser" bash -c '[ "$(stat -c %U /var/lib/claude-container)" = "testuser" ]'

reportResults
