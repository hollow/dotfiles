# https://github.com/openssh/openssh-portable
# use latest openssh from homebrew
_brew_install openssh

# https://github.com/mobile-shell/mosh
# mobile shell with roaming and local echo
_brew_install mosh

# https://github.com/jtesta/ssh-audit
# ssh server & client auditing
_brew_install ssh-audit

# load ssh keys into agent
zinit light-mode lucid for \
    atinit'zstyle :omz:plugins:ssh-agent identities id_rsa id_ed25519' \
    OMZP::ssh-agent

sshlive() {
    ssh \
        -o "StrictHostKeyChecking no" \
        -o "UserKnownHostsFile /dev/null" \
        -o "GlobalKnownHostsFile /dev/null" \
        "$@"
}
