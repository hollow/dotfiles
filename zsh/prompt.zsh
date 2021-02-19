# http://zsh.sourceforge.net/Doc/Release/Options.html#Description-of-Options
setopt prompt_subst

# https://github.com/romkatv/powerlevel10k
# beautiful and functional prompt
zinit lucid for \
    atload"source ${ZDOTDIR}/p10k.zsh; _p9k_precmd" \
    nocd depth=1 \
    @romkatv/powerlevel10k

# https://github.com/hlissner/zsh-autopair
# auto-close and delete matching delimiters
zinit lucid for @hlissner/zsh-autopair
