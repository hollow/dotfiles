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

# https://github.com/direnv/direnv
# change environment variables based on the current directory
_brew_install direnv

# accept long running asdf installs
# without warning messages
export DIRENV_WARN_TIMEOUT="5m"

# hook direnv into zsh
eval "$(direnv hook zsh)"

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
