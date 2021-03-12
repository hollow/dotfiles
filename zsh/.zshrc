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

zsource docker
zsource vagrant

zsource ansible
zsource gcloud
zsource terraform

zsource android
zsource home-assistant
zsource threema
zsource vscode

# our local bin overrides everything
_path_add_bin "${XDG_CONFIG_HOME}"
