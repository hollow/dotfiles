# https://github.com/asdf-vm/asdf
# The extendable version manager
_brew_install -b asdf

# make asdf adhere to XDG
export ASDF_DIR="$(_brew_pkg_path asdf)"
export ASDF_BIN="${ASDF_DIR}/bin"
export ASDF_DATA_DIR="${XDG_CACHE_HOME}"/asdf
export ASDF_CONFIG_FILE="${XDG_CONFIG_HOME}"/asdf/config
export ASDF_VERSIONS_FILE="${XDG_CONFIG_HOME}"/asdf/versions
export ASDF_DEFAULT_TOOL_VERSIONS_FILENAME="${ASDF_VERSIONS_FILE}"

# load asdf function
source "${ASDF_DIR}"/lib/asdf.sh

# return latest install path for given plugin
_asdf_plugin_path() {
    echo "${ASDF_DATA_DIR}"/plugins/$1
}

_asdf_install_path() {
    local paths=("${ASDF_DATA_DIR}"/installs/$1/${2:-*}/(NOn))
    echo "${paths[1]}"
}

# install latest version of given plugin
_asdf_install() {
    if [[ ! -e "$(_asdf_plugin_path "$1")" ]]; then
        asdf plugin add "$1" 1>&2
    fi
    if [[ ! -e "$(_asdf_install_path "$1" "$2")" ]]; then
        asdf install "$1" "${2:-latest}" 1>&2
    fi
}

# hook into global update
_asdf_upgrade() {
    local plugins=($(asdf plugin list))
    for plugin in $plugins; do
        echo -e "\n>>> updating asdf plugin $plugin"
        asdf plugin update "$plugin"
        asdf install "$plugin" "$(asdf latest "$plugin")"
    done
}
_update_insert _asdf_upgrade


# https://github.com/direnv/direnv
# change environment variables based on the current directory
_brew_install direnv
_asdf_install direnv
eval "$(direnv hook zsh)"
alias da="direnv allow"

# accept long running asdf installs
# without warning messages
export DIRENV_WARN_TIMEOUT="5m"

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
