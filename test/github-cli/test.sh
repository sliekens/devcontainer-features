#!/bin/bash

# Test for github-cli feature with default options.
# This feature wraps the official github-cli and adds persistent volume mounts.

set -e

source dev-container-features-test-lib

# Check that gh CLI is installed (from the dependsOn feature)
check "gh is installed" bash -c "command -v gh"

# Check that gh runs and shows version
check "gh version" bash -c "gh --version"

# Check that data lives under /var/lib and home paths are symlinks
check "gh config data dir exists" bash -c "test -d /var/lib/github-cli/config"
check "gh state data dir exists" bash -c "test -d /var/lib/github-cli/state"
check "gh config path is symlink" bash -c "test -L ~/.config/gh && [ \"$(readlink ~/.config/gh)\" = \"/var/lib/github-cli/config\" ]"
check "gh state path is symlink" bash -c "test -L ~/.local/share/gh && [ \"$(readlink ~/.local/share/gh)\" = \"/var/lib/github-cli/state\" ]"

reportResults
