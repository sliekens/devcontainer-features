#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir --parents "/var/lib/github-cli/config" "/var/lib/github-cli/state"

install -d -m 0755 /usr/local/share/github-cli
install -m 0755 "$SCRIPT_DIR/on_create.sh" /usr/local/share/github-cli/on_create.sh
