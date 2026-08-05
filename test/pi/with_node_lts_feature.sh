#!/usr/bin/env bash

set -euo pipefail

source dev-container-features-test-lib

check "node is available" command -v node
check "node meets pi minimum" bash -lc 'node -e "const [maj,min,patch]=process.versions.node.split(\".\").map(Number); process.exit(maj>22||(maj===22&&(min>19||(min===19&&patch>=0)))?0:1)"'
check "pi binary available" command -v pi
check "pi is under /usr/local/bin" bash -lc 'test -x /usr/local/bin/pi'
check "pi version runs" bash -lc 'pi --version | head -n 1'
check "pi state is linked" bash -lc '[ -L "$HOME/.pi" ] && [ "$(readlink "$HOME/.pi")" = "/var/lib/pi" ]'

reportResults
