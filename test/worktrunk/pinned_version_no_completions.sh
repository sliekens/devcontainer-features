#!/usr/bin/env bash

set -euo pipefail

source dev-container-features-test-lib

check "pinned wt version" bash -lc 'wt --version | grep -F "0.69.2"'
check "git-wt is installed" command -v git-wt
check "wt config symlink" bash -lc '[ -L "$HOME/.config/worktrunk" ] && [ "$(readlink "$HOME/.config/worktrunk")" = "/var/lib/worktrunk-config" ]'
check "wt config writable" bash -lc 'tmp="$HOME/.config/worktrunk/.feature-test"; printf ok > "$tmp"; [ "$(cat /var/lib/worktrunk-config/.feature-test)" = "ok" ]; rm -f "$tmp"'
check "system config installed" test -f /etc/xdg/worktrunk/config.toml
check "system config nests worktrees" bash -lc 'grep -qF "worktree-path = \"{{ repo_path }}/.worktrees/{{ branch | sanitize }}\"" /etc/xdg/worktrunk/config.toml'
check "bash rc has no worktrunk integration" bash -c '! grep -qF "worktrunk shell integration" /etc/bash.bashrc'
check "no fish integration file" bash -c 'test ! -f /etc/fish/conf.d/worktrunk.fish'
check "interactive bash has no wt wrapper" bash -ic '! type -t wt | grep -qx function'

reportResults
