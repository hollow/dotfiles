# Home Assistant
# https://www.home-assistant.io/
#
# > secrets decrypt home-assistant
# export HASS_SERVER=...
# export HASS_TOKEN=...
if ! _has_secret home-assistant; then
    return
fi

# https://github.com/home-assistant-ecosystem/home-assistant-cli
# command line utility for home assistant
_brew_install homeassistant-cli
_hass_update() {
    hass-cli completion zsh > "${HOMEBREW_PREFIX}"/share/zsh/site-functions/_hass-cli
}
_update_append _hass_update

# wrap home assistant interface in native mac app
if [[ "${OSTYPE}" == darwin* ]]; then
    zinit lucid for \
        atclone"_make_native 'Home Assistant' '${HASS_SERVER}'" \
        atpull'%atclone' run-atpull \
        as"null" id-as'native/home-assistant' \
        @zdharma/null
fi
