# https://github.com/ohmyzsh/ohmyzsh/blob/master/lib/completion.zsh
zinit for OMZL::completion.zsh

# do not eat space character after completion
# https://superuser.com/questions/613685/how-stop-zsh-from-eating-space-before-pipe-symbol
ZLE_SPACE_SUFFIX_CHARS=$'&|'

# https://github.com/zdharma/fast-syntax-highlighting
# Syntax-highlighting for Zshell
zinit lucid wait for \
    atinit"zicompinit; zicdreplay" \
    @zdharma/fast-syntax-highlighting

# https://github.com/zsh-users/zsh-autosuggestions
# fish-like autosuggestions for zsh
zinit lucid wait for \
    atload"_zsh_autosuggest_start" \
    @zsh-users/zsh-autosuggestions

# https://github.com/zsh-users/zsh-completions
# additional completion definitions for zsh
zinit lucid wait for \
    blockf atpull"zinit creinstall -q ." \
    @zsh-users/zsh-completions
