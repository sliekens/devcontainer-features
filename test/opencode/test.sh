#!/usr/bin/env bash

set -euo pipefail

source dev-container-features-test-lib

check "opencode version" opencode --version
check "opencode data symlink" bash -lc '[ -L "$HOME/.local/share/opencode" ] && [ "$(readlink "$HOME/.local/share/opencode")" = "/var/lib/opencode" ]'
check "opencode config symlink" bash -lc '[ -L "$HOME/.config/opencode" ] && [ "$(readlink "$HOME/.config/opencode")" = "/var/lib/opencode-config" ]'
check "opencode data writable" bash -lc 'tmp="$HOME/.local/share/opencode/.feature-test"; printf ok > "$tmp"; [ "$(cat /var/lib/opencode/.feature-test)" = "ok" ]; rm -f "$tmp"'
check "opencode config writable" bash -lc 'tmp="$HOME/.config/opencode/.feature-test"; printf ok > "$tmp"; [ "$(cat /var/lib/opencode-config/.feature-test)" = "ok" ]; rm -f "$tmp"'

reportResults
