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

# generate static homeassistant-cli zsh completion
zinit lucid for \
    atclone'hass-cli completion zsh > _hass-cli.zsh' \
    atpull'%atclone' run-atpull \
    atload'source hass-cli.zsh' \
    pick"/dev/null" \
    id-as'home-assistant-ecosystem/home-assistant-cli' \
    @zdharma/null

# generate static asdf direnv hook
# to speed up zshrc loading times
_direnv_generate_hook() {
    asdf plugin add direnv
    asdf plugin update direnv
    asdf install direnv
    asdf direnv hook zsh > hook.zsh
}

zinit lucid for \
    atclone'_direnv_generate_hook' \
    atpull'%atclone' run-atpull \
    atload'source hook.zsh' \
    as"null" id-as'direnv/direnv' \
    @zdharma/null

# wrap home assistant interface in native mac app
if [[ "${OSTYPE}" == darwin* ]]; then
    zinit lucid for \
        atclone"_make_native 'Home Assistant' '${HASS_SERVER}'" \
        atpull'%atclone' run-atpull \
        as"null" id-as'native/home-assistant' \
        @zdharma/null
fi
