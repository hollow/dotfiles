# https://github.com/ohmyzsh/ohmyzsh/blob/master/lib/clipboard.zsh
# setup os dependant clipboard
zinit for OMZL::clipboard.zsh

# https://github.com/mptre/yank
# yank terminal output to clipboard
_brew_install yank

# generate a random password into clipboard
# mnemonic: [P]ass[W]ord
pw() {
    genpass-monkey | tee /dev/stderr | clipcopy
}
