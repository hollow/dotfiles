# http://zsh.sourceforge.net/Doc/Release/Options.html#Description-of-Options
setopt auto_cd
setopt auto_pushd
setopt pushd_ignore_dups
setopt pushdminus

# https://github.com/trapd00r/LS_COLORS
zinit for \
    atclone"dircolors -b LS_COLORS > dircolors.zsh" \
    atpull'%atclone' run-atpull \
    atload'zstyle ":completion:*" list-colors "${(s.:.)LS_COLORS}"' \
    pick"dircolors.zsh" nocompile'!' \
    @trapd00r/LS_COLORS

# https://github.com/ogham/exa
# A modern replacement for ‘ls’
alias exa="exa --header --group --links --git"
alias l="exa --all --long"

# https://github.com/sharkdp/fd
# A simple, fast and user-friendly alternative to 'find'
if (( $+commands[fdfind] )); then
    alias fd=fdfind
fi

# https://github.com/BurntSushi/ripgrep
# fast grep replacement
export RIPGREP_CONFIG_PATH="${XDG_CONFIG_HOME}/ripgrep/flags"

# https://github.com/muesli/duf
# a better 'df' alternative
if (( $+commands[duf] )); then
    alias df=duf
fi

# https://github.com/Canop/broot
# A new way to see and navigate directory trees
if (( $+commands[broot] )); then
    eval "$(broot --print-shell-function zsh)"
fi

# cd helpers
alias -g ...='cd ../..'
alias -g ....='cd ../../..'
alias -g .....='cd ../../../..'
alias -g ......='cd ../../../../..'

mkcd() {
    mkdir -p "$1" && cd "$1"
}
