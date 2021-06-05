# https://github.com/openssh/openssh-portable
# use latest openssh from homebrew

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

# connect to server with tty and sudo shell
ssu() {
    ssh -t "$1" sudo -Hi
}
