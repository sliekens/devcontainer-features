#!/bin/bash

set -e

source dev-container-features-test-lib

check "ansible-lint is installed" bash -c "command -v ansible-lint"
check "ansible-lint version" bash -c "ansible-lint --version"

reportResults
