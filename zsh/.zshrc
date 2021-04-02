source "${ZDOTDIR}"/init.zsh

zsource bindings
zsource completion
zsource history
zsource prompt

zsource brew
zsource asdf

zsource fzf
zsource pager
zsource clipboard

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
zsource rust

zsource android
zsource ansible
zsource docker
zsource gcloud
zsource home-assistant
zsource terraform

zsource threema
zsource vscode

# our local bin overrides everything
_path_add path "${XDG_CONFIG_HOME}"/bin
