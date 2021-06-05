# https://github.com/ohmyzsh/ohmyzsh/blob/master/lib/completion.zsh
zinit for OMZL::completion.zsh

# do not eat space character after completion
# https://superuser.com/questions/613685/how-stop-zsh-from-eating-space-before-pipe-symbol
ZLE_SPACE_SUFFIX_CHARS=$'&|'

# https://github.com/zdharma/fast-syntax-highlighting
# https://github.com/zsh-users/zsh-autosuggestions
zinit wait lucid light-mode for \
  atinit"zicompinit; zicdreplay" \
      @zdharma/fast-syntax-highlighting \
  atload"_zsh_autosuggest_start" \
      @zsh-users/zsh-autosuggestions \
  blockf atpull'zinit creinstall -q .' \
      @zsh-users/zsh-completions
