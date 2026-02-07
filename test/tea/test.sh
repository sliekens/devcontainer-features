#!/bin/bash

set -e

source dev-container-features-test-lib

check "tea is installed" bash -c "command -v tea"
check "tea version works" bash -c "tea --version"
check "tea config data dir exists" bash -c "test -d /var/lib/tea-cli"
check "tea home config path is symlink" bash -c "test -L ~/.config/tea && [ \"$(readlink ~/.config/tea)\" = \"/var/lib/tea-cli\" ]"
check "legacy profile.d script is absent" bash -c "test ! -f /etc/profile.d/tea-completion.sh"
check "bash completion script exists" bash -c "test -f /etc/bash_completion.d/tea"
check "bash completion registers tea" bash -c '
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    else
        exit 1
    fi
    complete -p tea | grep -q "__tea_bash_autocomplete"
'
check "bash completion returns tea subcommands" bash -c '
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    else
        exit 1
    fi
    completion_fn="$(complete -p tea | sed -n "s/.*-F \\([^ ]*\\) tea.*/\\1/p")"
    test -n "$completion_fn"
    COMP_LINE="tea pu"
    COMP_POINT="${#COMP_LINE}"
    COMP_WORDS=(tea pu)
    COMP_CWORD=1
    COMPREPLY=()
    "$completion_fn"
    printf "%s\n" "${COMPREPLY[@]}" | grep -Eq "^pull$|^pulls$"
'
check "zsh completion file exists in fpath directories" bash -c '
    for f in \
        /usr/local/share/zsh/site-functions/_tea \
        /usr/share/zsh/site-functions/_tea \
        /usr/share/zsh/vendor-completions/_tea
    do
        if [ -f "$f" ]; then
            exit 0
        fi
    done
    exit 1
'
check "zsh can resolve _tea completion" bash -c '
    if ! command -v zsh >/dev/null 2>&1; then
        exit 0
    fi
    zsh -fc "autoload -Uz compinit && compinit -i && whence -w _tea | grep -q \"_tea: function\""
'

reportResults
