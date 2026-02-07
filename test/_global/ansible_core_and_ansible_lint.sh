#!/bin/bash

set -e

source dev-container-features-test-lib

check "ansible is installed" bash -c "command -v ansible"
check "ansible-lint is installed" bash -c "command -v ansible-lint"

check "ansible version" bash -c "ansible --version"
check "ansible-lint version" bash -c "ansible-lint --version"

reportResults
