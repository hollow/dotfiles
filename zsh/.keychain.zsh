#!zsh
eval $(
    keychain --quiet \
        --eval \
        --inherit any \
        --absolute \
        --dir "${XDG_DATA_HOME}/keychain" \
        --agents ssh \
        id_rsa id_ed25519
)
