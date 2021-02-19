# https://github.com/asdf-vm/asdf
# The extendable version manager
zinit light-mode lucid for \
    atinit'export ASDF_DIR="${PWD}" && path=("${PWD}/bin" $path)' \
    atload'source "${ASDF_DIR}/lib/asdf.sh"' as"null" \
    @asdf-vm/asdf

export ASDF_DATA_DIR="${XDG_CACHE_HOME}"/asdf
export ASDF_CONFIG_FILE="${XDG_CONFIG_HOME}"/asdf/config
export ASDF_VERSIONS_FILE="${XDG_CONFIG_HOME}"/asdf/versions
export ASDF_DEFAULT_TOOL_VERSIONS_FILENAME="${ASDF_VERSIONS_FILE}"

# https://github.com/direnv/direnv
# change environment variables based on the current directory
_brew_install direnv

_direnv_hook() {
    if [[ ! -d "${ASDF_DATA_DIR}/plugins/direnv" ]]; then
        asdf plugin add direnv &>2
    fi

    if [[ ! -d "${ASDF_DATA_DIR}/installs/direnv/${ASDF_DIRENV_VERSION}" ]]; then
        asdf plugin update direnv &>2
        asdf install direnv &>2
    fi

    asdf direnv hook zsh
}

# no need for a global versions file
# force the direnv version via env
export ASDF_DIRENV_VERSION=2.27.0
export DIRENV_WARN_TIMEOUT="5m"

zinit light-mode lucid for \
    atclone'_direnv_hook > direnv.zsh' \
    atpull'%atclone' run-atpull \
    atload'source direnv.zsh' \
    as"null" id-as'direnv/direnv' \
    @zdharma/null

# install one or more versions of specified language
# mnemonic: [A]sdf [I]nstall
ai() {
    local fzf=("fzf" "--preview" "asdf info")
    local plugin=${1:-$(asdf plugin list all | $fzf | awk '{print $1}')}
    _asdf_need_plugin "$plugin" || return 1
    for version in $(asdf list all $plugin | $fzf --tac -m); do
        _asdf_install_version $plugin $version || return 1
    done
}
