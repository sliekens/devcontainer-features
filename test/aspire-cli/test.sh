#!/bin/bash

# Test for aspire-cli feature with default options.
# See: https://github.com/devcontainers/cli/blob/HEAD/docs/features/test.md

set -e

source dev-container-features-test-lib

# Check that aspire CLI is installed and in PATH
check "aspire is installed" bash -c "command -v aspire"

# Check that aspire runs and shows version
check "aspire version" bash -c "aspire --version"

# Check that aspire help works
check "aspire help" bash -c "aspire --help"

# Check that state lives under /var/lib and home path is symlinked
check "aspire state dir exists" bash -c "test -d /var/lib/aspire-cli"
check "aspire home path is symlink" bash -c "test -L ~/.aspire && [ \"$(readlink ~/.aspire)\" = \"/var/lib/aspire-cli\" ]"

# Check that telemetry is opted out
check "telemetry opt-out" bash -c "[ \"$ASPIRE_CLI_TELEMETRY_OPTOUT\" = \"1\" ]"

reportResults
