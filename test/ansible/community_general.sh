#!/bin/bash

set -e

source dev-container-features-test-lib

check "community.general collection can be listed" bash -c "ansible-galaxy collection list | grep -E '(^|\\s)community\\.general(\\s|$)'"

reportResults
