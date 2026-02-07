#!/usr/bin/env bash

set -euo pipefail

# Optional: Import test library bundled with the devcontainer CLI
# See https://github.com/devcontainers/cli/blob/HEAD/docs/features/test.md
source dev-container-features-test-lib

# Feature-specific tests
check "bws binary available" command -v bws
check "bws reports version" bash -lc 'bws --version | grep -Eq "[0-9]+\\.[0-9]+\\.[0-9]+"'
check "Bitwarden Secrets Manager config directory is linked" bash -lc '[ -L "$HOME/.config/bws" ] && [ "$(readlink "$HOME/.config/bws")" = "/var/lib/bitwarden-secrets-manager" ]'
check "Bitwarden Secrets Manager config dir is writable" bash -lc 'tmp="$HOME/.config/bws/.feature-test"; printf ok > "$tmp"; [ "$(cat /var/lib/bitwarden-secrets-manager/.feature-test)" = "ok" ]; rm -f "$tmp"'

# Report result
reportResults
