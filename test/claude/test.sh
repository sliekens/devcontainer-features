#!/usr/bin/env bash

set -euo pipefail

source dev-container-features-test-lib

check "claude binary available" command -v claude
check "claude version runs" bash -lc 'claude --version | head -n 1'
check "claude state is linked" bash -lc '[ -L "$HOME/.claude" ] && [ "$(readlink "$HOME/.claude")" = "/var/lib/claude-container/data" ]'
check "claude binary is executable" bash -lc 'test -f /usr/local/bin/claude && test -x /usr/local/bin/claude'

reportResults
