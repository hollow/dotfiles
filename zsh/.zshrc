source "${ZDOTDIR}"/init.zsh

zsource brew
zsource asdf

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

zsource golang
zsource java
zsource python
zsource ruby

zsource android
zsource docker
zsource gcloud
zsource home-assistant
zsource threema
zsource vagrant

zsource completion

path=("${XDG_CONFIG_HOME}"/bin ${path})

up() {
    bup && \
    zup && \
    zre
}
