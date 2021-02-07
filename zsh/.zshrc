source "${ZDOTDIR}"/init.zsh

zsource brew
zsource asdf

_path_add path "${XDG_CONFIG_HOME}"/bin

zsource fzf
zsource pager
zsource prompt
zsource history
zsource bindings

zsource dir
zsource proc
zsource gpg
zsource net
zsource ssh
zsource git
zsource java
zsource vim

zsource completion

up() {
    bup && \
    zup && \
    zre
}
