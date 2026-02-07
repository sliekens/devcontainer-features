#!/bin/bash

# Test for ffmpeg feature.

set -e

source dev-container-features-test-lib

# Check that ffmpeg is installed and in PATH
check "ffmpeg is installed" bash -c "command -v ffmpeg"

# Check that ffprobe is installed and in PATH
check "ffprobe is installed" bash -c "command -v ffprobe"

# Check that ffmpeg runs and shows version
check "ffmpeg version" bash -c "ffmpeg -version | head -1"

# Check that ffprobe runs and shows version
check "ffprobe version" bash -c "ffprobe -version | head -1"

reportResults
