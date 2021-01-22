HISTFILE="${XDG_DATA_HOME}/zsh/history"
HISTSIZE=50000
SAVEHIST=10000

setopt extended_history
setopt hist_expire_dups_first
setopt hist_ignore_dups
setopt hist_ignore_space
setopt hist_reduce_blanks
setopt hist_verify

# https://github.com/zdharma/history-search-multi-word
zstyle ":history-search-multi-word" page-size "11"
zinit wait lucid for \
    zdharma/history-search-multi-word

# https://github.com/zsh-users/zsh-history-substring-search
# zinit wait lucid for \
#     zsh-users/zsh-history-substring-search

# Bind UP and DOWN arrow keys for subsstring search.
# https://github.com/zsh-users/zsh-history-substring-search#usage
# bindkey "${terminfo[kcuu1]}" history-substring-search-up
# bindkey "${terminfo[kcud1]}" history-substring-search-down
# bindkey '^[[A' history-substring-search-up
# bindkey '^[[B' history-substring-search-down
