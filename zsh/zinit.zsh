declare -A ZINIT

ZINIT[BIN_DIR]="${XDG_CONFIG_HOME}"/zinit/bin
ZINIT[HOME_DIR]="${XDG_DATA_HOME}"/zinit
ZINIT[ZCOMPDUMP_PATH]="${XDG_DATA_HOME}"/zcompdump

source "${ZINIT[BIN_DIR]}"/zinit.zsh
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

zinit light-mode for \
    zinit-zsh/z-a-rust \
    zinit-zsh/z-a-readurl \
    zinit-zsh/z-a-patch-dl \
    zinit-zsh/z-a-bin-gem-node

zinit wait lucid for \
    OMZL::clipboard.zsh \
    OMZP::zsh_reload
