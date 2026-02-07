#!/bin/bash

# Test for aspire-cli feature with dev quality.

set -e

source dev-container-features-test-lib

check "aspire is installed" bash -c "command -v aspire"
check "aspire version" bash -c "aspire --version"

reportResults
