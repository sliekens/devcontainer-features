#!/usr/bin/env bash

set -euo pipefail

source dev-container-features-test-lib

check "wt is installed" command -v wt
check "git-wt is installed" command -v git-wt
check "wt version works" bash -lc 'wt --version'
check "wt config symlink" bash -lc '[ -L "$HOME/.config/worktrunk" ] && [ "$(readlink "$HOME/.config/worktrunk")" = "/var/lib/worktrunk-config" ]'
check "wt config writable" bash -lc 'tmp="$HOME/.config/worktrunk/.feature-test"; printf ok > "$tmp"; [ "$(cat /var/lib/worktrunk-config/.feature-test)" = "ok" ]; rm -f "$tmp"'

check "system config installed" test -f /etc/xdg/worktrunk/config.toml
check "system config nests worktrees" bash -lc 'grep -qF "worktree-path = \"{{ repo_path }}/.worktrees/{{ branch | sanitize }}\"" /etc/xdg/worktrunk/config.toml'
check "wt sees system config" bash -lc 'wt config show --format json | jq -e ".system.exists == true" >/dev/null'
check "system default creates nested worktree" bash -lc '
    empty_user="$(mktemp)"
    repo="$(mktemp -d)"
    git -C "$repo" init -b main >/dev/null
    git -C "$repo" config user.email "test@example.com"
    git -C "$repo" config user.name "test"
    printf "x\n" > "$repo/f"
    git -C "$repo" add f
    git -C "$repo" commit -m init >/dev/null
    wt --config "$empty_user" -C "$repo" switch --create topic --no-cd -y >/dev/null
    test -d "$repo/.worktrees/topic"
    test -f "$repo/.worktrees/topic/f"
'
check "user worktree-path overrides system default" bash -lc '
    user_cfg="$(mktemp)"
    printf "%s\n" "worktree-path = \"{{ repo_path }}/custom-{{ branch | sanitize }}\"" > "$user_cfg"
    repo="$(mktemp -d)"
    git -C "$repo" init -b main >/dev/null
    git -C "$repo" config user.email "test@example.com"
    git -C "$repo" config user.name "test"
    printf "x\n" > "$repo/f"
    git -C "$repo" add f
    git -C "$repo" commit -m init >/dev/null
    wt --config "$user_cfg" -C "$repo" switch --create topic --no-cd -y >/dev/null
    test -d "$repo/custom-topic"
    test ! -d "$repo/.worktrees/topic"
'

check "bash rc has worktrunk integration" bash -c 'grep -qF "worktrunk shell integration" /etc/bash.bashrc'
check "interactive bash defines wt wrapper" bash -ic 'type -t wt | grep -qx function'
check "interactive bash registers wt completion" bash -ic 'complete -p wt | grep -q _wt_lazy_complete'
check "bash completion returns wt subcommands" bash -ic '
    COMP_LINE="wt swi"
    COMP_POINT="${#COMP_LINE}"
    COMP_WORDS=(wt swi)
    COMP_CWORD=1
    COMPREPLY=()
    _wt_lazy_complete
    printf "%s\n" "${COMPREPLY[@]}" | grep -q "^switch"
'

check "zsh rc has worktrunk integration" bash -c '
    if [ ! -f /etc/zsh/zshrc ]; then
        exit 0
    fi
    grep -qF "worktrunk shell integration" /etc/zsh/zshrc
'
check "interactive zsh defines wt wrapper" bash -c '
    if ! command -v zsh >/dev/null 2>&1 || [ ! -f /etc/zsh/zshrc ]; then
        exit 0
    fi
    zsh -ic "whence -w wt" | grep -q "wt: function"
'

reportResults
