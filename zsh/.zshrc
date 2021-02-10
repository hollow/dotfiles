source "${ZDOTDIR}"/init.zsh

zsource brew
zsource asdf

path=("${XDG_CONFIG_HOME}"/bin ${path})

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
zsource vim
zsource tmux

if [[ "${OSTYPE}" == darwin* ]]; then
    zsource macos
fi

zsource java
zsource python

zsource android
zsource docker
zsource home-assistant
zsource threema
zsource vagrant

zsource completion

up() {
    bup && \
    zup && \
    zre
}
