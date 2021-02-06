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

# Page generic output automatically with bat
# mnemonic: [P]a[G]er
pg() {
    ${=PAGER} "$@"
}

# Page man/help output automatically with bat
# mnemonic: [P]age [H]elp text
ph() {
    pg -l man "$@"
}

# follow file and colorize with bat
# menmonic: [T]ail [F]ollow
tf() {
    tail -f "$@" | pg -l log
}

# Sort Output and page it with bat
# mnemonic: [S]ort [L]ess
sl() {
    sort -u | pg
}
