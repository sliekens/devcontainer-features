#!/usr/bin/env bash

set -euo pipefail

source dev-container-features-test-lib

check "pi binary available" command -v pi
check "pi is under /usr/local/bin" bash -lc 'test -x /usr/local/bin/pi'
check "pi reports pinned version" bash -lc 'pi --version 2>&1 | grep -E "(^|[^0-9])0\\.83\\.0([^0-9]|$)"'
check "pi state is linked" bash -lc '[ -L "$HOME/.pi" ] && [ "$(readlink "$HOME/.pi")" = "/var/lib/pi" ]'

reportResults
