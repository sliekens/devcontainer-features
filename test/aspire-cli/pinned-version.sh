#!/bin/bash

# Test for aspire-cli feature with a pinned version.

set -e

source dev-container-features-test-lib

check "aspire is installed" bash -c "command -v aspire"
check "aspire version matches pinned version" bash -c "aspire --version | grep -F '13.2.1'"

reportResults
