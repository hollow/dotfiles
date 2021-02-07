# https://github.com/jiahaog/nativefier
# wrap web apps in native mac apps
_brew_install nativefier

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

_cask_app_path() {
    echo /Applications/"$1".app
}

# fast replacement for `brew install --cask <pkg>`
_cask_install() {
    local app_path="/Applications/${2}.app"
    if [[ ! -d "${app_path}" ]]; then
        brew install --cask "${1}"
    fi
}

_cask_install alfred "Alfred 4"
# _cask_install balenaetcher "balenaEtcher"
# _cask_install banking-4 "Banking4"
# _cask_install bitwarden "Bitwarden"
# _cask_install boxy-suite "Boxy for Gmail"
_cask_install cleanmymac "CleanMyMac X"
# _cask_install discord "Discord"
# _cask_install divvy "Divvy"
_cask_install docker "Docker"
# _cask_install dupeguru "dupeGuru"
# _cask_install forklift "ForkLift"
# _cask_install google-chrome "Google Chrome"
_cask_install iterm2 "iTerm"
# _cask_install logitech-options "Logi Options"
# _cask_install microsoft-office "Microsoft Word"
# _cask_install miro "Miro"
# _cask_install mountain-duck "Mountain Duck"
# _cask_install native-access "Native Access"
# _cask_install nextcloud "nextcloud"
_cask_install slack "Slack"
# _cask_install sonos "Sonos"
# _cask_install spotify "Spotify"
# _cask_install teamviewer "TeamViewer"
_cask_install the-unarchiver "The Unarchiver"
_cask_install virtualbox "VirtualBox"
_cask_install visual-studio-code "Visual Studio Code"
# _cask_install vlc "VLC"
_cask_install zoom "zoom.us"
