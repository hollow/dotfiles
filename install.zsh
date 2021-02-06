#!/usr/bin/env zsh

source "${${(%):-%x}:P:h}"/zsh/defaults.zsh
ln -vnfs "${XDG_CONFIG_HOME}"/zsh/config.zsh "${HOME}"/.zshenv || exit 1
exec zsh -i
