# hook into global update
_macos_update() {
    softwareupdate --verbose --install --all
}
_update_insert _macos_update

# https://github.com/jiahaog/nativefier
# wrap web apps in native mac apps
_brew_install nativefier

# wrapper for default nativefier app creation
_make_native() {
    local app_name="$1" && shift
    local app_path="/Applications/${app_name}.app"
    local build_version="$(date +YYYYMMDDHHMMSS)"
    local temp_path="$(mktemp -d)"

    pushd "${temp_path}" || return 1

    nativefier \
        --name "${app_name}" \
        --build-version "${build_version}" \
        --platform mac \
        --arch x64 \
        --counter \
        --bounce \
        --fast-quit \
        "$@" || return 1

    rm -rf "${app_path}"
    mv ./*/*.app "${app_path}"

    popd
    rm -rf "${temp_path}"
}

# https://github.com/mas-cli/mas
# mac app store command line interface
_brew_install mas

# fast replacement for `brew install --cask <pkg>`
_cask_path() {
    local cask_path="${HOMEBREW_PREFIX}/Caskroom/$1"
    echo "${cask_path}"
    test -d "${cask_path}"
}

_cask_install() {
    if ! _cask_path "$1" >/dev/null; then
        brew install --cask "$1"
    fi
}
