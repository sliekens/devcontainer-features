#!/bin/bash

# Test for mtn (Movie Thumbnail Generator) feature.

set -e

source dev-container-features-test-lib

# Check that mtn is installed and in PATH
check "mtn is installed" bash -c "command -v mtn"

# Check that mtn runs and shows help
check "mtn help" bash -c "mtn -h 2>&1 | grep -i 'movie'"

# Check that required fonts are installed (TTF files)
check "dejavu fonts installed" bash -c "ls /usr/share/fonts/truetype/dejavu/*.ttf 2>/dev/null | head -1"

reportResults
