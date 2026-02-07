#!/bin/bash

# Test for Mono feature.

set -e

source dev-container-features-test-lib

# Check that mono is installed and in PATH
check "mono is installed" bash -c "command -v mono"

# Check that mono runs and shows version
check "mono version" bash -c "mono --version | head -1"

# Check that mcs (C# compiler) is installed
check "mcs is installed" bash -c "command -v mcs"

# Check that gdb is installed (included in feature)
check "gdb is installed" bash -c "command -v gdb"

reportResults
