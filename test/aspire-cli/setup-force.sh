#!/usr/bin/env bash

# Test that aspire setup --force works as a nonroot user.

set -e

source dev-container-features-test-lib

aspire_logged() {
    "$@" || {
        local rc=$?
        local latest_log
        latest_log=$(ls -t ~/.aspire/logs/cli_*.log 2>/dev/null | head -n 1)
        [ -n "$latest_log" ] && cat "$latest_log"
        return $rc
    }
}

check "running as nonroot user" bash -c '[ "$(id -u)" != "0" ]'
check "aspire is installed" command -v aspire
check "aspire setup --force succeeds" aspire_logged aspire setup --force

reportResults
