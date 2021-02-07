# Home Assistant
# https://www.home-assistant.io/
#
# cat home-assistant
# export HASS_SERVER=...
# export HASS_TOKEN=...
# secrets encrypt home-assistant

# https://github.com/home-assistant-ecosystem/home-assistant-cli
# command line utility for home assistant
_brew_install homeassistant-cli
zinit light-mode lucid wait for \
    atclone'hass-cli completion zsh > hass-cli.zsh' \
    atpull'%atclone' run-atpull \
    atload'source hass-cli.zsh' \
    as"null" id-as'home-assistant-ecosystem/home-assistant-cli' \
    @zdharma/null

# wrap home assistant interface in native mac app
if [[ "${OSTYPE}" == darwin* ]]; then
    zinit light-mode lucid for \
        atclone"_make_native 'Home Assistant' '${HASS_SERVER}'" \
        atpull'%atclone' run-atpull \
        as"null" id-as'native/home-assistant' \
        @zdharma/null
fi
