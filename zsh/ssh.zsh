# use openssh from homebrew
_brew_install openssh

# load ed25519 key as well
zstyle :omz:plugins:ssh-agent identities id_rsa id_ed25519
zinit for OMZP::ssh-agent

sshlive() {
    ssh \
        -o "StrictHostKeyChecking no" \
        -o "UserKnownHostsFile /dev/null" \
        -o "GlobalKnownHostsFile /dev/null" \
        "$@"
}
