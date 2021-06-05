# https://github.com/Homebrew/brew
# The missing package manager for macOS

# add homebrew to path
if [[ -d /opt/homebrew ]]; then
    export HOMEBREW_PREFIX="/opt/homebrew"
else
    export HOMEBREW_PREFIX="/usr/local"
fi

_path_add_bin "${HOMEBREW_PREFIX}"
_path_add_lib "${HOMEBREW_PREFIX}"

# install homebrew if missing
if ! (( $+commands[brew] )); then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# homebrew zsh function path
export HOMEBREW_ZSH_FUNCTIONS="${HOMEBREW_PREFIX}"/share/zsh/site-functions

# always use color
export HOMEBREW_COLOR=1

# we do not need these
export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_NO_COMPAT=1

# store a bundle of all installed applications
export HOMEBREW_BUNDLE_FILE="${XDG_CONFIG_HOME}/brew/packages"
export HOMEBREW_BUNDLE_NO_LOCK=1
alias bbd="brew bundle dump --force"

# update and cleanup
export HOMEBREW_AUTO_UPDATE_SECS=86400
export HOMEBREW_CLEANUP_MAX_AGE_DAYS=7
export HOMEBREW_CLEANUP_PERIODIC_FULL_DAYS=1
export HOMEBREW_UPDATE_REPORT_ONLY_INSTALLED=1

# hook into global update
_brew_upgrade() {
    brew update && \
    brew upgrade && \
    brew autoremove && \
    brew cleanup -s
}
_update_insert _brew_upgrade

# ensure a proper GNU based environment
_path_add_lib "${HOMEBREW_PREFIX}"/opt/curl
_path_add_lib "${HOMEBREW_PREFIX}"/opt/ncurses
_path_add_lib "${HOMEBREW_PREFIX}"/opt/readline
_path_add_lib "${HOMEBREW_PREFIX}"/opt/openssl
_path_add_lib "${HOMEBREW_PREFIX}"/opt/sqlite
_path_add_lib "${HOMEBREW_PREFIX}"/opt/zlib
_path_add_lib "${HOMEBREW_PREFIX}"/opt/icu4c
_path_add_lib "${HOMEBREW_PREFIX}"/opt/libffi
_path_add_bin "${HOMEBREW_PREFIX}"/opt/gnu-getopt
_path_add_lex "${HOMEBREW_PREFIX}"/opt/coreutils
_path_add_lex "${HOMEBREW_PREFIX}"/opt/debianutils
_path_add_lex "${HOMEBREW_PREFIX}"/opt/findutils
_path_add_lex "${HOMEBREW_PREFIX}"/opt/gnu-sed
_path_add_lex "${HOMEBREW_PREFIX}"/opt/gnu-tar
_path_add_lex "${HOMEBREW_PREFIX}"/opt/gnu-time

# uninstall (zap) selected application(s)
# mnemonic: [B]rew [Z]ap
bz() {
    local fzf=("fzf" "--preview" "brew info {}")

    if [[ $# -eq 0 ]]; then
        set -- $(brew list --formula | $fzf -m)
    fi

    for pkg_name in "$@"; do
        brew uninstall --zap "${pkg_name}"
    done
}
