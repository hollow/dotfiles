# http://zsh.sourceforge.net/Doc/Release/Options.html#Description-of-Options
setopt prompt_subst

# https://github.com/trapd00r/LS_COLORS
zinit light-mode lucid for \
    atclone"dircolors -b LS_COLORS > dircolors.zsh" \
    atpull'%atclone' run-atpull \
    atload'zstyle ":completion:*" list-colors "${(s.:.)LS_COLORS}"' \
    pick"dircolors.zsh" nocompile'!' \
    @trapd00r/LS_COLORS

# https://github.com/romkatv/powerlevel10k
# beautiful and functional prompt
zinit light-mode lucid for \
    atload"source ${ZDOTDIR}/p10k.zsh; _p9k_precmd" \
    nocd depth=1 \
    @romkatv/powerlevel10k

# https://github.com/hlissner/zsh-autopair
# auto-close and delete matching delimiters
zinit light-mode lucid for \
    @hlissner/zsh-autopair

# https://github.com/ohmyzsh/ohmyzsh/blob/master/lib/clipboard.zsh
# setup os dependant clipboard
zinit light-mode lucid for \
	OMZL::clipboard.zsh

# https://github.com/mptre/yank
# yank terminal output to clipboard
_brew_install yank
