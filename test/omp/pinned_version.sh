#!/usr/bin/env bash

set -euo pipefail

source dev-container-features-test-lib

check "omp binary available" command -v omp
check "omp is under /usr/local/bin" bash -lc 'test -x /usr/local/bin/omp'
check "omp reports pinned version" bash -lc 'omp --version 2>&1 | grep -E "(^|[^0-9])17\\.2\\.9([^0-9]|$)"'
check "omp state is linked" bash -lc '[ -L "$HOME/.omp" ] && [ "$(readlink "$HOME/.omp")" = "/var/lib/omp" ]'

reportResults
