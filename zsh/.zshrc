source "${ZDOTDIR}"/init.zsh

zsource bindings
zsource completion
zsource history
zsource prompt

if [[ "${OSTYPE}" == darwin* ]]; then
    zsource brew
fi

zsource asdf

zsource fzf
zsource pager
zsource clipboard

zsource dir
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
zsource ruby
zsource rust

zsource aws
zsource android
zsource ansible
zsource gcloud
zsource home-assistant
zsource terraform

zsource threema
zsource vscode

# our local bin overrides everything
_path_add path "${XDG_CONFIG_HOME}"/bin
