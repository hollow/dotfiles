# Threema Web Client
# https://www.threema.ch
#
# > secrets decrypt threema
# THREEMA_ID=...
if ! _has_secret threema; then
    return
fi

if [[ "${OSTYPE}" == darwin* ]]; then
    zinit light-mode lucid for \
        atclone"_make_native Threema https://web.threema.ch" \
        atpull'%atclone' run-atpull \
        as"null" id-as'native/threema' \
        @zdharma/null
fi
