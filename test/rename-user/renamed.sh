#!/usr/bin/env bash

set -euo pipefail

source dev-container-features-test-lib

check "user is testuser" bash -c '[ "$(whoami)" = "testuser" ]'
check "home directory is /home/testuser" bash -c '[ "$HOME" = "/home/testuser" ]'
check "passwordless sudo works" sudo -n true
check "vscode user no longer exists" bash -c '! id vscode 2>/dev/null'

reportResults
