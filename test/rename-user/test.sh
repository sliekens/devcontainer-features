#!/usr/bin/env bash

set -euo pipefail

source dev-container-features-test-lib

# Default: remoteUser not set, feature should be a no-op
check "vscode user exists" id vscode
check "passwordless sudo works" sudo -n true

reportResults
