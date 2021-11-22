# User information (for git, gpg, etc)
export USER_NAME="Benedikt Böhm"
export USER_EMAIL="bb@xnull.de"

# Force locale to english
export LANG="en_US.UTF-8"
export LC_CTYPE=${LANG}

# User paths
# https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
export XDG_CONFIG_HOME="${HOME}/.config"
export XDG_CACHE_HOME="${HOME}/.cache"
export XDG_DATA_HOME="${HOME}/.local/share"
export XDG_STATE_HOME="${HOME}/.local/state"

# Shell paths
# https://zsh.sourceforge.io/Intro/intro_3.html
export ZDOTDIR=${${(%):-%x}:A:h} ZSH=${ZDOTDIR}
export ZSH_CACHE_DIR="${XDG_CACHE_HOME}/zsh"
mkdir -p "${XDG_CACHE_HOME}/zsh"
mkdir -p "${XDG_DATA_HOME}/zsh"

# System paths
typeset -TUx PATH path=("${XDG_CONFIG_HOME}/bin" /{usr/,}{local/,}{s,}bin)
typeset -TUx MANPATH manpath=(${(s[:])$(env -u MANPATH manpath)})
typeset -TUx FPATH fpath=(${ZDOTDIR} ${fpath[@]})

# Zsh plugin manager
# https://github.com/zdharma-continuum/zinit
autoload -Uz zinit
alias zre="exec zsh"
alias zx="sudo rm -rf ${XDG_CACHE_HOME} && zre"

# The missing package manager
# https://github.com/Homebrew/brew
export HOMEBREW_PREFIX="/opt/homebrew"

if [[ -e "${HOMEBREW_PREFIX}" ]]; then
    export HOMEBREW_BUNDLE_FILE="${XDG_CONFIG_HOME}/Brewfile"
    export HOMEBREW_BUNDLE_NO_LOCK=1
    export HOMEBREW_AUTO_UPDATE_SECS=86400
    export HOMEBREW_CLEANUP_MAX_AGE_DAYS=7
    export HOMEBREW_CLEANUP_PERIODIC_FULL_DAYS=1
    export HOMEBREW_UPDATE_REPORT_ONLY_INSTALLED=1

    export HOMEBREW_SHELLENV_PREFIX= # reset
    eval "$(${HOMEBREW_PREFIX}/bin/brew shellenv)"

    zinit id-as'brew' as'null' \
        atclone'brew update' \
        atclone'brew upgrade' \
        atclone'brew bundle install' \
        atclone'brew autoremove' \
        atclone'brew cleanup -s' \
        atpull'%atclone' run-atpull \
        for zdharma-continuum/null

    # ensure proper GNU based environment
    for formula in coreutils findutils gnu-{sed,tar,time}; do
        path=("${HOMEBREW_PREFIX}/opt/${formula}/libexec/gnubin" ${path})
        manpath=("${HOMEBREW_PREFIX}/opt/${formula}/libexec/gnuman" ${manpath})
    done

    alias bbd="brew bundle dump -f"
    alias bz="brew uninstall --zap"
fi

# Load basics from Oh My Zsh
# https://github.com/ohmyzsh/ohmyzsh
zinit wait for \
    OMZL::clipboard.zsh \
    OMZL::compfix.zsh \
    OMZL::completion.zsh \
    OMZL::directories.zsh \
    OMZL::functions.zsh \
    OMZL::git.zsh \
    OMZL::grep.zsh \
    OMZL::history.zsh \
    OMZL::key-bindings.zsh \
    OMZL::spectrum.zsh \
    OMZL::termsupport.zsh

# Words are complete shell command arguments
autoload -Uz select-word-style
select-word-style shell

# History configuration
# https://zsh.sourceforge.io/Doc/Release/Options.html#History
HISTFILE="${XDG_DATA_HOME}/zsh/history"
HISTSIZE=1000000000 SAVEHIST=1000000000
unsetopt share_history # OMZ enables shared history

# Fast, clean and configurable Zsh theme
# https://github.com/romkatv/powerlevel10k
zinit wait'!' nocd depth'1' \
    atload'source "${ZDOTDIR}/.p10k.zsh"' \
    atload'_p9k_precmd' \
    for romkatv/powerlevel10k

# Fast Zsh syntax highlighting
# https://github.com/zdharma-continuum/fast-syntax-highlighting
zinit wait \
    atinit'zicompinit && zicdreplay' \
    for zdharma-continuum/fast-syntax-highlighting

# Colors for ls and completions
# https://github.com/trapd00r/LS_COLORS
zinit wait \
    pick'dircolors.zsh' nocompile'!' \
    atclone'dircolors -b LS_COLORS > dircolors.zsh' \
    atload'zstyle ":completion:*" list-colors "${(s.:.)LS_COLORS}"' \
    atload'alias ls="ls --color=tty"' \
    atload'alias l="exa --all --long --group"' \
    for trapd00r/LS_COLORS

# Additional completions from the community
# https://github.com/zsh-users/zsh-completions
zinit wait blockf \
    atpull'zinit creinstall -q .' \
    for zsh-users/zsh-completions

# Automatically close quotes, brackets and other delimiters
# https://github.com/hlissner/zsh-autopair
zinit wait for hlissner/zsh-autopair

# direnv: change environment based on the current directory
# https://github.com/direnv/direnv
if [[ ${EUID} -ne 0 ]]; then
    eval "$(direnv hook zsh)"
    alias da="direnv allow"
fi

# go: programming language
# https://www.golang.org
export GOPATH="${XDG_CACHE_HOME}/go"
path=("${GOPATH}/bin" ${path})

# npm: node package manager
# https://github.com/npm/cli
export NPM_CONFIG_USERCONFIG="${XDG_CONFIG_HOME}/npm/npmrc"

# python: programming language
# https://docs.python.org/3/
export PYTHONSTARTUP="${XDG_CONFIG_HOME}/python/startup.py"

# poetry: python dependency management
# https://github.com/python-poetry/poetry
export POETRY_CACHE_DIR="${XDG_CACHE_HOME}/poetry"

# ruby: programming language
# https://www.ruby-lang.org
export GEM_HOME="${XDG_DATA_HOME}"/gem
export GEM_SPEC_CACHE="${XDG_CACHE_HOME}"/gem
export BUNDLE_USER_CONFIG="${XDG_CONFIG_HOME}"/bundle
export BUNDLE_USER_CACHE="${XDG_CACHE_HOME}"/bundle
export BUNDLE_USER_PLUGIN="${XDG_DATA_HOME}"/bundle
path=("${HOMEBREW_PREFIX}/opt/ruby/bin" ${path})
path=("${HOMEBREW_PREFIX}/lib/ruby/gems/3.0.0/bin" ${path})

# android: development kit
# https://developer.android.com/studio/command-line/variables
export ANDROID_EMULATOR_HOME="${XDG_CONFIG_HOME}/android"

# ansible: simple IT automation
# https://github.com/ansible/ansible
alias ad="ansible-doc"
alias ai="ansible-inventory"
alias ap="ansible-playbook"

# aws: Amazon Web Services CLI
# https://aws.amazon.com/cli/
export AWS_SHARED_CREDENTIALS_FILE="${XDG_CONFIG_HOME}/aws/credentials"
export AWS_CONFIG_FILE="${XDG_CONFIG_HOME}/aws/config"

# bat: cat(1) clone with wings
# https://github.com/sharkdp/bat
export BAT_CONFIG_PATH="${XDG_CONFIG_HOME}"/bat/config BAT_PAGER="less"
export MANPAGER="sh -c 'col -bx | bat -l man'" MANROFFOPT="-c"

# duf: better `df` alternative
# https://github.com/muesli/duf
alias df=duf

# gam: Google Apps Manager
# https://github.com/jay0lee/GAM
function gam() { "/Users/bene/bin/gam/gam" "$@"; }

# gcloud: Google Cloud SDK
# https://cloud.google.com/sdk
export CLOUDSDK_CORE_DISABLE_USAGE_REPORTING=true
export CLOUDSDK_PATH="${HOMEBREW_PREFIX}/Caskroom/google-cloud-sdk/latest/google-cloud-sdk"
path=("${CLOUDSDK_PATH}/bin" ${path})
zinit id-as'google-cloud-sdk' for "${CLOUDSDK_PATH}/completion.zsh.inc"

# git: distributed version control system
# https://github.com/git/git
export GIT_AUTHOR_NAME="${USER_NAME}"
export GIT_AUTHOR_EMAIL="${USER_EMAIL}"
export GIT_COMMITTER_NAME="${USER_NAME}"
export GIT_COMMITTER_EMAIL="${USER_EMAIL}"

autoload -Uz clone

alias c="git changes"
alias ga="git add --all"
alias gap="git add --patch"
alias gcm="git co \$(git main-branch)"
alias gcu="git co upstream"
alias gd="git df"
alias gdc="git dc"
alias gdm="git df \$(git main-branch)"
alias gdu="git df upstream"
alias gl="git lg"
alias gp="git pull"
alias gpr="git pull --rebase --autostash"
alias grh="git reset HEAD"
alias s="git st ."

# gnupg: GNU privacy guard
# https://gnupg.org/
export GNUPGHOME="${XDG_DATA_HOME}/gnupg"

# insect: high precision scientific calculator
# https://github.com/sharkdp/insect
zinit wait from'gh-r' \
    lbin'insect-* -> insect' \
    for @sharkdp/insect

# less: pager configuration
# https://man7.org/linux/man-pages/man1/less.1.html#OPTIONS
export PAGER="less" LESS="-FiMRSW -x4"
export LESSHISTFILE="${XDG_DATA_HOME}/less/history"
sl() { sort -u | less }

# parallel: run commands in parallel
# https://www.gnu.org/software/parallel/
export PARALLEL_HOME="${XDG_CONFIG_HOME}/parallel"
mkdir -p ${PARALLEL_HOME}

# pw: a simple pwgen replacement
autoload -Uz pw

# ripgrep: fast grep replacement
# https://github.com/BurntSushi/ripgrep
export RIPGREP_CONFIG_PATH="${XDG_CONFIG_HOME}"/ripgrep/config

# sqlite:
export SQLITE_HISTORY=${XDG_DATA_HOME}/sqlite/history

# ssh:
zinit wait for OMZP::ssh-agent
ssu() { ssh -t "$1" sudo -Hi }

# terraform: manage cloud infrastructure
# https://github.com/hashicorp/terraform
export CHECKPOINT_DISABLE=true
alias tf=terraform

# vim: the editor
# https://github.com/vim/vim
export VIMINIT="set nocp | source ${XDG_CONFIG_HOME}/vim/vimrc"
export EDITOR="${commands[vim]}"

# youtube: download audio
alias yta="youtube-dl -x --audio-format mp3"
