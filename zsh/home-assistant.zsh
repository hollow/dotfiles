# Home Assistant
# https://www.home-assistant.io/
#
# > secrets decrypt home-assistant
# export HASS_SERVER=...
# export HASS_TOKEN=...
if ! _has_secret home-assistant; then
    return
fi

# wrap home assistant interface in native mac app
if [[ "${OSTYPE}" == darwin* ]]; then
    zinit for \
        atclone"_make_native 'Home Assistant' '${HASS_SERVER}' --icon '${XDG_CONFIG_HOME}/home-assistant/app.icns'" \
        atpull'%atclone' run-atpull \
        as"null" id-as'native/home-assistant' \
        @zdharma/null
fi
