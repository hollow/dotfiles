export ASDF_DATA_DIR="${XDG_DATA_HOME}"/asdf
export ASDF_CONFIG_FILE="${XDG_CONFIG_HOME}"/asdf/config
export ASDF_DEFAULT_TOOL_VERSIONS_FILENAME="${XDG_CONFIG_HOME}"/asdf/versions

zinit wait"2" lucid for \
    atload"asdf-install ${ASDF_DEFAULT_TOOL_VERSIONS_FILENAME}" \
        @asdf-vm/asdf

zinit wait"2" lucid for \
    as"program" make'!' atclone'./direnv hook zsh > zhook.zsh' \
    atpull'%atclone' pick"direnv" src"zhook.zsh" \
        direnv/direnv

asdf-install-version() {
    asdf plugin add "$1"
    asdf plugin update "$1"
    asdf install "$1" "$2"
}

asdf-install-global() {
    asdf-install-version "$1" "$2"
    asdf global "$1" "$2"
}

asdf-install-local() {
    asdf-install-version "$1" "$2"
    asdf local "$1" "$2"
}

asdf-install-latest() {
    for p in "$@"; do
        asdf-install-global "$p" "$(asdf latest "$p")"
    done
}

asdf-install-all() {
    asdf-install-latest $(asdf plugin list)
}

asdf-install() {
    local versions="${1:-${PWD}/.tool-versions}"
    if [[ ! -r "${versions}" ]]; then
        return
    fi
    while read -r name version; do
        if [[ ! -d "${ASDF_DATA_DIR}/installs/${name}/${version}" ]]; then
            asdf plugin add "${name}"
            asdf plugin update "${name}"
            asdf install "${name}" "${version}"
        fi
    done <"${versions}"
}
