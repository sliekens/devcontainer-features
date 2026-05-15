#!/usr/bin/env bash

set -euo pipefail

# Optional: Import test library bundled with the devcontainer CLI
# See https://github.com/devcontainers/cli/blob/HEAD/docs/features/test.md
source dev-container-features-test-lib

# Feature-specific tests
check "aac binary available" command -v aac
check "aac reports version" bash -lc 'aac --version | grep -Eq "[0-9]+\.[0-9]+\.[0-9]+"'

# Report result
reportResults
