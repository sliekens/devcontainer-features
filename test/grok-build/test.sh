#!/usr/bin/env bash

set -euo pipefail

source dev-container-features-test-lib

check "grok binary available" command -v grok
check "grok version runs" bash -lc 'grok --version | head -n 1'
check "agent binary available" command -v agent
check "grok state is linked" bash -lc '[ -L "$HOME/.grok" ] && [ "$(readlink "$HOME/.grok")" = "/var/lib/grok-build" ]'
check "grok binary is executable" bash -lc 'test -f /usr/local/bin/grok && test -x /usr/local/bin/grok'

reportResults