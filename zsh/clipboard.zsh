# https://github.com/ohmyzsh/ohmyzsh/blob/master/lib/clipboard.zsh
# setup os dependant clipboard
zinit for OMZL::clipboard.zsh

# generate a random password into clipboard
# mnemonic: [P]ass[W]ord
pw() {
    genpass-monkey | tee /dev/stderr | clipcopy
}
