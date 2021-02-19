# https://github.com/asdf-vm/asdf
# The extendable version manager
_asdf_setup_path() {
    export ASDF_DIR="${PWD}"
    _path_add_bin "${PWD}"
}

zinit lucid for \
    atinit'_asdf_setup_path' \
    atload'source lib/asdf.sh' \
    as"null" \
    @asdf-vm/asdf

export ASDF_DATA_DIR="${XDG_CACHE_HOME}"/asdf
export ASDF_CONFIG_FILE="${XDG_CONFIG_HOME}"/asdf/config
export ASDF_VERSIONS_FILE="${XDG_CONFIG_HOME}"/asdf/versions
export ASDF_DEFAULT_TOOL_VERSIONS_FILENAME="${ASDF_VERSIONS_FILE}"

# https://github.com/direnv/direnv
# change environment variables based on the current directory
_brew_install direnv

# no need for a global versions file
# force the direnv version via env
export ASDF_DIRENV_VERSION=2.27.0

# accept long running asdf installs
# without warning messages
export DIRENV_WARN_TIMEOUT="5m"

# generate static asdf direnv hook
# to speed up zshrc loading times
_direnv_generate_hook() {
    asdf plugin add direnv
    asdf plugin update direnv
    asdf install direnv
    asdf direnv hook zsh > hook.zsh
}

zinit lucid for \
    atclone'_direnv_generate_hook' \
    atpull'%atclone' run-atpull \
    atload'source hook.zsh' \
    as"null" id-as'direnv/direnv' \
    @zdharma/null

# install one or more versions of specified language
# mnemonic: [A]sdf [I]nstall
ai() {
    local fzf=("fzf" "--preview" "asdf info")
    local plugin=${1:-$(asdf plugin list all | $fzf | awk '{print $1}')}
    asdf plugin add "${plugin}"
    asdf plugin update "${plugin}"
    for version in $(asdf list all $plugin | $fzf --tac -m); do
        asdf install "${plugin}" "${version}"
    done
}
