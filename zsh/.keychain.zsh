#!zsh
eval $(
    keychain --quiet \
        --eval \
        --inherit any \
        --absolute \
        --dir "${XDG_DATA_HOME}/keychain" \
        --agents ssh,gpg \
        id_rsa id_ed25519 \
        ${USER_EMAIL}
)
