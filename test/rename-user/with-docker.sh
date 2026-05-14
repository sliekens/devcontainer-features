#!/usr/bin/env bash

set -euo pipefail

source dev-container-features-test-lib

check "user is testuser" bash -c '[ "$(whoami)" = "testuser" ]'
check "vscode user no longer exists" bash -c '! id vscode 2>/dev/null'
check "testuser is in docker group" bash -c 'id -nG | tr " " "\n" | grep -qx docker'

reportResults
