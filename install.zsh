#!/usr/bin/env zsh

export DOT_SOURCE_DIR="${${(%):-%x}:P:h}"
source "${DOT_SOURCE_DIR}"/zsh/defaults.zsh

echo "DOT_SOURCE_DIR=${DOT_SOURCE_DIR}"
echo "XDG_CONFIG_HOME=${XDG_CONFIG_HOME}"

if [[ "${DOT_SOURCE_DIR}" != "${XDG_CONFIG_HOME}" ]]; then
    if [[ -e "${XDG_CONFIG_HOME}" ]]; then
        echo "error: XDG_CONFIG_HOME already exists. skipping."
    else
        echo "${XDG_CONFIG_HOME} -> ${DOT_SOURCE_DIR}"
        ln -nfs "${DOT_SOURCE_DIR}" "${XDG_CONFIG_HOME}" || exit 1
    fi
else
    echo "DOT_SOURCE_DIR and XDG_CONFIG_HOME are the same. skipping."
fi

echo "${XDG_CONFIG_HOME}/zsh/env -> ${HOME}/.zshenv"
ln -nfs "${XDG_CONFIG_HOME}"/zsh/config.zsh "${HOME}"/.zshenv || exit 1

source "${XDG_CONFIG_HOME}"/zsh/config.zsh || exit 1
exec zsh -i
