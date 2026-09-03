#!/usr/bin/env bash

set -euo pipefail

# Optional: Import test library bundled with the devcontainer CLI
# See https://github.com/devcontainers/cli/blob/HEAD/docs/features/test.md
source dev-container-features-test-lib

# Feature-specific tests
check "codex version" codex --version
check "bundled rg" /usr/local/bin/rg --version
check "codex-code-mode-host installed" test -x /usr/local/bin/codex-code-mode-host
check "codex-code-mode-host help" bash -lc 'codex-code-mode-host --help | grep -q "Usage: codex-code-mode-host"'
check "codex state symlink" bash -lc '[ -L "$HOME/.codex" ] && [ "$(readlink "$HOME/.codex")" = "/var/lib/codex" ]'
check "codex state writable" bash -lc 'tmp="$HOME/.codex/.feature-test"; printf ok > "$tmp"; [ "$(cat /var/lib/codex/.feature-test)" = "ok" ]; rm -f "$tmp"'

# Report result
reportResults
