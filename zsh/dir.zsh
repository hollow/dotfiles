# http://zsh.sourceforge.net/Doc/Release/Options.html#Description-of-Options
setopt auto_cd
setopt auto_pushd
setopt pushd_ignore_dups
setopt pushdminus

# https://github.com/ogham/exa
# A modern replacement for ‘ls’
_brew_install exa
alias exa="exa --header --group-directories-first --group --links --git"
alias l="exa --all --long"

# https://github.com/sharkdp/fd
# A simple, fast and user-friendly alternative to 'find'
_brew_install fd

# https://github.com/BurntSushi/ripgrep
# fast grep replacement
_brew_install ripgrep
export RIPGREP_CONFIG_PATH="${XDG_CONFIG_HOME}/ripgrep/flags"

# https://github.com/chmln/sd
# intuitive sed replacement
_brew_install sd

# https://github.com/muesli/duf
# a better 'df' alternative
_brew_install duf
alias df=duf

# https://github.com/sharkdp/diskus
# minimal, fast alternative to 'du -sh'
_brew_install diskus

# https://github.com/Canop/broot
# A new way to see and navigate directory trees
_brew_install broot
zinit light-mode lucid for \
    atclone'broot --print-shell-function zsh > broot.zsh' \
    atpull'%atclone' run-atpull \
    atload'source broot.zsh' \
    as"null" id-as'Canop/broot' \
    @zdharma/null

# cd helpers
alias -g ...='cd ../..'
alias -g ....='cd ../../..'
alias -g .....='cd ../../../..'
alias -g ......='cd ../../../../..'

mkcd() {
    mkdir -p "$1" && cd "$1"
}
