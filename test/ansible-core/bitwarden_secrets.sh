#!/bin/bash

set -e

source dev-container-features-test-lib

check "bitwarden.secrets collection can be listed" bash -c "ansible-galaxy collection list | grep -E '(^|\\s)bitwarden\\.secrets(\\s|$)'"
check "bitwarden-sdk is installed in ansible-core pipx environment" bash -c "pipx runpip ansible-core show bitwarden-sdk | grep -Eq '^Name: bitwarden_sdk$'"

reportResults
