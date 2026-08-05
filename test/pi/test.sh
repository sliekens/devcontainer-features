#!/usr/bin/env bash

set -euo pipefail

source dev-container-features-test-lib

check "pi binary available" command -v pi
check "pi is under /usr/local/bin" bash -lc 'test -x /usr/local/bin/pi'
check "pi version runs" bash -lc 'pi --version | head -n 1'
check "pi state is linked" bash -lc '[ -L "$HOME/.pi" ] && [ "$(readlink "$HOME/.pi")" = "/var/lib/pi" ]'
check "pi state writable" bash -lc 'tmp="$HOME/.pi/.feature-test"; printf ok > "$tmp"; [ "$(cat /var/lib/pi/.feature-test)" = "ok" ]; rm -f "$tmp"'

reportResults
