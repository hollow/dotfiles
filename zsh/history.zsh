# http://zsh.sourceforge.net/Doc/Release/Options.html#Description-of-Options
# history configuration
setopt extended_history       # record timestamp of command in HISTFILE
setopt hist_expire_dups_first # delete duplicates first when HISTFILE size exceeds HISTSIZE
setopt hist_ignore_dups       # ignore duplicated commands history list
setopt hist_ignore_space      # ignore commands that start with space
setopt hist_reduce_blanks     # remove superfluous blanks from each command line
setopt hist_verify            # show command with history expansion to user before running it
setopt inc_append_history     # immediately append to history file
unsetopt share_history        # do not share command history data

# http://zsh.sourceforge.net/Doc/Release/Parameters.html#Parameters-Used-By-The-Shell
HISTFILE="${ZINIT[HOME_DIR]}/history"
HISTSIZE=1000000000
SAVEHIST=1000000000

# Start typing + [Up-Arrow] - fuzzy find history forward
autoload -U up-line-or-beginning-search
zle -N up-line-or-beginning-search
bindkey "${terminfo[kcuu1]}" up-line-or-beginning-search

# Start typing + [Down-Arrow] - fuzzy find history backward
autoload -U down-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "${terminfo[kcud1]}" down-line-or-beginning-search
