# hook into global update
_macos_update() {
    softwareupdate --verbose --install --all
}
_update_insert _macos_update

# https://github.com/jiahaog/nativefier
# wrap web apps in native mac apps
_make_native() {
    local app_name="$1" && shift
    local app_path="/Applications/${app_name}.app"
    local build_version="$(date +%Y%m%d%H%M%S)"
    local temp_path="$(mktemp -d)"
    local nativefier_args=(
        --name "${app_name}"
        --build-version "${build_version}"
        --platform mac
        --arch $(uname -m)
        --counter
        --bounce
        --fast-quit
        "$@"
    )

    pushd "${temp_path}" || return 1
    echo nativefier "${nativefier_args[@]}"
    nativefier "${nativefier_args[@]}" || return 1

    rm -rf "${app_path}"
    mv ./*/*.app "${app_path}"

    popd
    rm -rf "${temp_path}"
}
