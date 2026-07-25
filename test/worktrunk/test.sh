#!/usr/bin/env bash

set -euo pipefail

source dev-container-features-test-lib

check "wt is installed" command -v wt
check "git-wt is installed" command -v git-wt
check "wt version works" bash -lc 'wt --version'
check "wt config symlink" bash -lc '[ -L "$HOME/.config/worktrunk" ] && [ "$(readlink "$HOME/.config/worktrunk")" = "/var/lib/worktrunk-config" ]'
check "wt config writable" bash -lc 'tmp="$HOME/.config/worktrunk/.feature-test"; printf ok > "$tmp"; [ "$(cat /var/lib/worktrunk-config/.feature-test)" = "ok" ]; rm -f "$tmp"'

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
