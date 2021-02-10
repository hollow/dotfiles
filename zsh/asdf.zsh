# https://github.com/asdf-vm/asdf
# The extendable version manager
export ASDF_DATA_DIR="${XDG_CACHE_HOME}"/asdf
export ASDF_CONFIG_FILE="${XDG_CONFIG_HOME}"/asdf/config
export ASDF_VERSIONS_FILE="${XDG_CONFIG_HOME}"/asdf/versions
export ASDF_DEFAULT_TOOL_VERSIONS_FILENAME="${ASDF_VERSIONS_FILE}"

zinit light-mode lucid for \
    @asdf-vm/asdf

_path_add path "${ASDF_DATA_DIR}/shims"

_asdf_need_plugin() {
    local name="$1"
    if [[ ! -d "${ASDF_DATA_DIR}/plugins/${name}" ]]; then
        asdf plugin add "${name}" 1>&2 || return 1
        asdf plugin update "${name}" 1>&2 || return 1
    fi
}

_asdf_install_version() {
    _asdf_need_plugin "$1" || return 1

    local name="$1"
    local version="${2:-$(asdf latest "$1")}"
    local install_dir="${ASDF_DATA_DIR}/installs/${name}/${version}"

    if [[ ! -d "${install_dir}" ]]; then
        asdf install "${name}" "${version}" 1>&2 || return 1
        asdf reshim || return 1
    fi
}

_asdf_install_from_file() {
    local pattern="${2:-.*}"
    while read -r name version; do
        if [[ "${name}" =~ "^${pattern}$" ]]; then
            _asdf_install_version "${name}" "${version}"
        fi
    done <"$1"
}

_asdf_install() {
    _asdf_install_from_file "${ASDF_VERSIONS_FILE}" "${1}"
}

# https://github.com/direnv/direnv
# change environment variables based on the current directory
_brew_install direnv
_asdf_install direnv # for asdf integration

_direnv_hook() {
    trap -- '' SIGINT
    eval "$("${HOMEBREW_PREFIX}"/bin/direnv export zsh)"
    trap - SIGINT
}

typeset -ag precmd_functions;
if [[ -z ${precmd_functions[(r)_direnv_hook]} ]]; then
    precmd_functions=( _direnv_hook ${precmd_functions[@]} )
fi

typeset -ag chpwd_functions;
if [[ -z ${chpwd_functions[(r)_direnv_hook]} ]]; then
    chpwd_functions=( _direnv_hook ${chpwd_functions[@]} )
fi

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
