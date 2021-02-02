# https://github.com/ohmyzsh/ohmyzsh/blob/master/lib/completion.zsh
zinit for OMZL::completion.zsh

# do not eat space character after completion
# https://superuser.com/questions/613685/how-stop-zsh-from-eating-space-before-pipe-symbol
ZLE_SPACE_SUFFIX_CHARS=$'&|'

# https://github.com/Aloxaf/fzf-tab
# zsh completion menu replacement with fzf
# zinit lucid wait for \
#     atinit"zicompinit; zicdreplay" \
#     @Aloxaf/fzf-tab

# https://github.com/zdharma/fast-syntax-highlighting
# Syntax-highlighting for Zshell
zinit lucid wait for \
    atinit"zicompinit; zicdreplay" \
    @zdharma/fast-syntax-highlighting
