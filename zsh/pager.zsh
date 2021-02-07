# improve less experience
# https://man7.org/linux/man-pages/man1/less.1.html#OPTIONS
_brew_install less
typeset -TUx LESS less ' '
less=(
    "--HILITE-UNREAD"
    "--ignore-case"
    "--LONG-PROMPT"
    "--RAW-CONTROL-CHARS"
    "--tabs=4"
    "--window=-4"
)

# https://github.com/sharkdp/bat
# A cat(1) clone with wings
_brew_install bat eth-p/software/bat-extras
export BAT_CONFIG_PATH="${XDG_CONFIG_HOME}"/bat/config
export BAT_PAGER="less"
export PAGER="bat --plain"

# use bat as colorizing man pager
# https://github.com/sharkdp/bat#man
export MANPAGER="sh -c 'col -bx | ${=PAGER} -l man'"
export MANROFFOPT="-c"

# https://github.com/dbrgn/tealdeer
# very fast implementation of tldr
_brew_install tealdeer
export TEALDEER_CONFIG_DIR="${XDG_CONFIG_HOME}"/teeldear
export TEALDEER_CACHE_DIR="${XDG_CACHE_HOME}"/teeldear

# update tldr cache during zinit update
zinit light-mode lucid for \
    atclone"mkdir -p '${TEALDEER_CACHE_DIR}'; tldr --update" \
    atpull'%atclone' run-atpull \
    as"null" id-as'dbrgn/tealdeer' \
    @zdharma/null

# show tldr or man page or help text of command
help() {
    if tldr -l | grep -q "^${1}$"; then
        tldr "$1"
    elif man "$1" &>/dev/null; then
        man "$1"
    else
        "$1" --help | ${=PAGER} -l man
    fi
}

# Page generic output automatically with bat
# mnemonic: [P]a[G]er
pg() {
    ${=PAGER} "$@"
}

# follow file and colorize with bat
# menmonic: [T]ail [F]ollow
tf() {
    tail -f "$@" | pg -l log
}

# Sort Output and page it with bat
# mnemonic: [S]ort [P]age
sp() {
    sort -u | pg
}

# for historical reasons
# mnemonic: [S]ort [L]ess
alias sl=sp
