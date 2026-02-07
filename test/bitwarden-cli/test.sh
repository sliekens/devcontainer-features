#!/usr/bin/env bash

set -euo pipefail

# Optional: Import test library bundled with the devcontainer CLI
# See https://github.com/devcontainers/cli/blob/HEAD/docs/features/test.md
source dev-container-features-test-lib

# Feature-specific tests
check "bw binary available" command -v bw
check "bw reports version" bash -lc 'bw --version | grep -Eq "[0-9]+\\.[0-9]+\\.[0-9]+"'
check "Bitwarden CLI config directory is mounted" bash -lc 'test -d "/home/vscode/.config/Bitwarden CLI"'

# Report result
reportResults
