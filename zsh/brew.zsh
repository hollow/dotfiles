# https://github.com/Homebrew/brew
# The missing package manager for macOS

# add homebrew to path
export HOMEBREW_PREFIX="/usr/local"
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

# use recent versions installed by ourselves
export HOMEBREW_FORCE_BREWED_CURL=1
export HOMEBREW_FORCE_BREWED_GIT=1
export HOMEBREW_FORCE_VENDOR_RUBY=1

# set git config just in case
export HOMEBREW_GIT_EMAIL="${DEFAULT_EMAIL}"
export HOMEBREW_GIT_NAME="${DEFAULT_NAME}"

# store a bundle of all installed applications
export HOMEBREW_BUNDLE_FILE="${XDG_CONFIG_HOME}/brew/packages"
export HOMEBREW_BUNDLE_NO_LOCK=1
alias bbd="brew bundle dump --force"

# update and cleanup
export HOMEBREW_AUTO_UPDATE_SECS=86400
export HOMEBREW_CLEANUP_MAX_AGE_DAYS=7
export HOMEBREW_CLEANUP_PERIODIC_FULL_DAYS=1
export HOMEBREW_UPDATE_REPORT_ONLY_INSTALLED=1

# fast replacement for `brew info <pkg>`
_brew_pkg_path() {
    echo "${HOMEBREW_PREFIX}"/opt/"$1"
}

# fast replacement for `brew install <pkg>`
_brew_install() {
    local _add_opt=

    for pkg_name in "$@"; do
        if [[ "${pkg_name}" == "-"* ]]; then
            _add_opt="${pkg_name}"
            continue
        fi

        local pkg_path="$(_brew_pkg_path "${pkg_name##*/}")"

        if [[ ! -d "${pkg_path}" ]]; then
            brew install "${pkg_name}"
        fi

        if [[ "${_add_opt}" == "-b" ]]; then
            _path_add_bin "${pkg_path}"
        elif [[ "${_add_opt}" == "-x" ]]; then
            _path_add_lex "${pkg_path}"
        elif [[ "${_add_opt}" == "-l" ]]; then
            _path_add_lib "${pkg_path}"
        fi
    done
}

# ensure a proper GNU based environment
_brew_install -l \
    curl \
    ncurses \
    readline \
    openssl \
    sqlite \
    zlib \
    icu4c \
    libffi

_brew_install -b \
    gnu-getopt

_brew_install -x \
    coreutils \
    debianutils \
    findutils \
    gnu-sed \
    gnu-tar \
    gnu-time

_brew_install \
    bash \
    jq \
    tree \
    wget \
    xz \
    zsh

# install selected application(s)
# mnemonic: [B]rew [I]nstall
bi() {
    local fzf=("fzf" "--preview" "brew info {}")

    if [[ $# -eq 0 ]]; then
        set -- $(brew formulae | $fzf -m)
    fi

    for pkg_name in "$@"; do
        _brew_install "${pkg_name}"
    done
}

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

# update all homebrew packages
# mnemonic: [B]rew [Up]grade
bup() {
    softwareupdate --verbose --install --all && \
    brew update && \
    brew upgrade && \
    brew autoremove && \
    brew cleanup -s
}
