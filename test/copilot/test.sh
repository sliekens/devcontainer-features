#!/usr/bin/env bash

set -euo pipefail

# Optional: Import test library bundled with the devcontainer CLI
# See https://github.com/devcontainers/cli/blob/HEAD/docs/features/test.md
source dev-container-features-test-lib

# Feature-specific tests
check "copilot version" copilot --version
check "copilot state symlink" bash -lc '[ -L "$HOME/.copilot" ] && [ "$(readlink "$HOME/.copilot")" = "/var/lib/copilot" ]'
check "copilot state writable" bash -lc 'tmp="$HOME/.copilot/.feature-test"; printf ok > "$tmp"; [ "$(cat /var/lib/copilot/.feature-test)" = "ok" ]; rm -f "$tmp"'

# Report result
reportResults
