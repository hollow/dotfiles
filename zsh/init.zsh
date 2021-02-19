source "${ZDOTDIR}"/defaults.zsh

# https://github.com/zdharma/zinit
# ZSH plugin manager
declare -A ZINIT
ZINIT[BIN_DIR]="${XDG_CONFIG_HOME}"/zinit/bin
ZINIT[HOME_DIR]="${XDG_CACHE_HOME}"/zinit
ZINIT[ZCOMPDUMP_PATH]="${ZINIT[HOME_DIR]}"/zcompdump
ZINIT[COMPINIT_OPTS]="-C"

if [[ ! -e "${ZINIT[BIN_DIR]}"/zinit.zsh ]]; then
	pushd "${ZDOTDIR}"
	git submodules update --init
	popd
fi

source "${ZINIT[BIN_DIR]}"/zinit.zsh

# https://github.com/ohmyzsh/ohmyzsh/tree/master/lib
# OMZ and extensions
zinit lucid for \
	OMZL::functions.zsh \
	OMZL::spectrum.zsh \
	atload"unalias _ afind" \
	OMZL::misc.zsh

# Load a zsh file with zinit to
# get traces and benchmarks
zsource() {
	source "${ZDOTDIR}/${1}.zsh"
}

# Update Zinit and all plugins and completions
# mnemonic: [Z]init [Up]date
zup() {
	zi cclear
	zi delete --clean --yes
	zi cclear
	zi self-update
	zi update --all --reset
	zi compinit
	zi compile --all
}

# Replace the current shell process with a new one
# mnemonic: [Z]init [R]e-[E]xec
zre() {
	exec zsh
}

# Remove Zinit cache and start from scratch
# mnemonic: [Z]init Reset[X]
zx() {
	rm -rf "${XDG_CACHE_HOME}"
	exec zsh
}

# global update functionality
typeset -ag _update_hooks
_update_append() { _update_hooks=(${_update_hooks} "$1") }
_update_insert() { _update_hooks=("$1" ${_update_hooks}) }

up() {
    for f in ${_update_hooks}; do
        echo ">>> ${f}"
        ${f}
        echo
    done
    zup
    zre
}
