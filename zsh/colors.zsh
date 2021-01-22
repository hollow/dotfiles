autoload -U colors && colors

zinit wait"!" lucid for \
    atload"source ${ZDOTDIR}/p10k.zsh; _p9k_precmd" \
        nocd depth=1 romkatv/powerlevel10k

zinit wait lucid for \
    atclone"dircolors -b LS_COLORS > clrs.zsh" \
    atpull'%atclone' pick"clrs.zsh" nocompile'!' \
    atload'zstyle ":completion:*" list-colors “${(s.:.)LS_COLORS}”' \
    atinit'alias ls="ls --color=auto" diff="diff --color"' \
        trapd00r/LS_COLORS

zinit wait lucid for \
    as"program" pick"bin/git-dsf" \
        zdharma/zsh-diff-so-fancy

zinit wait lucid for \
    atinit"ZINIT[COMPINIT_OPTS]=-C; zicompinit; zicdreplay" \
        zdharma/fast-syntax-highlighting
