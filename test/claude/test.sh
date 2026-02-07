#!/usr/bin/env bash

set -euo pipefail

source dev-container-features-test-lib

check "claude binary available" command -v claude
check "claude version runs" bash -lc 'claude --version | head -n 1'
check "claude state is linked" bash -lc '[ -L "$HOME/.claude" ] && [ "$(readlink "$HOME/.claude")" = "/var/lib/claude" ]'
check "claude executable points to shared state" bash -lc 'test -L /usr/local/bin/claude && [ "$(readlink /usr/local/bin/claude)" = "/var/lib/claude/.local/bin/claude" ]'

reportResults
