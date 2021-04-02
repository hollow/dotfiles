# https://github.com/openssh/openssh-portable
# use latest openssh from homebrew
_brew_install openssh

# symlink ~/.ssh as openssh does not support XDG
ssh_link="${HOME}/.ssh"
ssh_conf="${XDG_CONFIG_HOME}/ssh"
if [[ "$(readlink "${ssh_link}")" != "${ssh_conf}" ]]; then
    ln -nfs "${ssh_conf}" "${ssh_link}"
fi

# load GnuPG SSH Key
# > secrets decrypt ssh
# echo KEYGRIP > "${XDG_CONFIG_HOME}"/gnupg/sshcontrol
_has_secret ssh

# https://github.com/mobile-shell/mosh
# mobile shell with roaming and local echo
_brew_install mosh

# https://github.com/jtesta/ssh-audit
# ssh server & client auditing
_brew_install ssh-audit

# connect to a live/rescue system without
# host key check or known hosts
# mnemonic: [SSH] to [Live] system
sshlive() {
    ssh \
        -o "StrictHostKeyChecking no" \
        -o "UserKnownHostsFile /dev/null" \
        -o "GlobalKnownHostsFile /dev/null" \
        "$@"
}
