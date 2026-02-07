#!/bin/bash

set -e

source dev-container-features-test-lib

check "ansible is installed" bash -c "command -v ansible"
check "ansible-playbook is installed" bash -c "command -v ansible-playbook"
check "ansible-galaxy collection command works" bash -c "ansible-galaxy collection list >/dev/null"

check "ansible version" bash -c "ansible --version"
check "ansible-playbook version" bash -c "ansible-playbook --version"

reportResults
