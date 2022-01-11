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

# System paths
typeset -TUx PATH path=("${XDG_CONFIG_HOME}/bin" /{usr/,}{local/,}{s,}bin)
typeset -TUx MANPATH manpath=(${(s[:])$(env -u MANPATH manpath)})

# Shell paths
# https://zsh.sourceforge.io/Intro/intro_3.html
ZDOTDIR=${${(%):-%x}:A:h}
ZSH_CACHE_DIR="${XDG_CACHE_HOME}/zsh"
mkdir -p "${ZSH_CACHE_DIR}"
ZSH_DATA_DIR="${XDG_DATA_HOME}/zsh"
mkdir -p "${ZSH_DATA_DIR}"
ZSH_COMPDUMP="${ZSH_CACHE_DIR}/zcompdump"

# Shell functions
typeset -TUx FPATH fpath=(${ZDOTDIR} ${fpath[@]})
autoload -Uz has

# brew: the missing package manager
# https://github.com/Homebrew/brew
if [[ -e /opt/homebrew ]]; then
    source "${ZDOTDIR}/brew"
fi

# Enable Powerlevel10k instant prompt
if [[ -r "${XDG_CACHE_HOME}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Install zgenom
if [[ ! -d "${XDG_CACHE_HOME}/zgenom" ]]; then
    git clone https://github.com/jandamm/zgenom.git "${XDG_CACHE_HOME}/zgenom"
fi

# Load zgenom
ZGEN_CUSTOM_COMPDUMP="${ZSH_COMPDUMP}"
source "${XDG_CACHE_HOME}/zgenom/zgenom.zsh"

# Reload zgenom
alias zre="zgenom reset && exec zsh"
alias zx="sudo rm -rf ${XDG_CACHE_HOME} && exec zsh"

# Check for plugin and zgenom updates every 7 days
# This does not increase the startup time.
zgenom autoupdate

# if the init script doesn't exist
if ! zgenom saved; then
    # https://github.com/jandamm/zgenom-ext-eval
    zgenom load jandamm/zgenom-ext-eval

    # Ohmyzsh base library
    zgenom ohmyzsh

    # enhance the terminal environment with 256 colors
    # https://github.com/chrissicool/zsh-256color
    zgenom load chrissicool/zsh-256color

    # build and load ls colors
    # https://github.com/trapd00r/LS_COLORS
    zgenom clone trapd00r/LS_COLORS
    zgenom eval $(dircolors -b $(zgenom api clone_dir trapd00r/LS_COLORS)/LS_COLORS)

    # https://github.com/romkatv/powerlevel10k
    zgenom load romkatv/powerlevel10k powerlevel10k

    # Feature-rich syntax highlighting for ZSH
    # https://github.com/zdharma-continuum/fast-syntax-highlighting
    zgenom load zdharma-continuum/fast-syntax-highlighting

    # Fish-like autosuggestions for zsh
    # https://github.com/zsh-users/zsh-autosuggestions/blob/master/INSTALL.md
    zgenom load zsh-users/zsh-autosuggestions

    # Automatically close quotes, brackets and other delimiters
    # https://github.com/hlissner/zsh-autopair
    zgenom load hlissner/zsh-autopair

    # help remembering those aliases you defined once
    # https://github.com/djui/alias-tips
    zgenom load djui/alias-tips

    # Load zsh history search and create bindings for it
    zgenom load zsh-users/zsh-history-substring-search
    zgenom eval "bindkey '^[[A' history-substring-search-up"
    zgenom eval "bindkey '^[[B' history-substring-search-down"

    # Additional completion definitions for Zsh.
    # https://github.com/zsh-users/zsh-completions
    zgenom load zsh-users/zsh-completions

    # docker completions
    zgenom ohmyzsh --completion plugins/docker
    zgenom ohmyzsh --completion plugins/docker-compose

    # ohmyzsh plugins
    zgenom ohmyzsh plugins/colored-man-pages
    zgenom ohmyzsh plugins/pip
    zgenom ohmyzsh plugins/python
    zgenom ohmyzsh plugins/rsync

    # keychain
    zstyle :omz:plugins:ssh-agent agent-forwarding yes
    zstyle :omz:plugins:ssh-agent identities id_rsa id_ed25519
    zgenom ohmyzsh plugins/ssh-agent

    # save all to init script
    zgenom save

    # Compile your zsh files
    zgenom compile "${${(%):-%x}:A}"
    zgenom compile "${ZDOTDIR}"
fi

# Words are complete shell command arguments
autoload -Uz select-word-style
select-word-style shell

# Speed up slow completions with a cache
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ${ZSH_CACHE_DIR}

# Use approximate completion with error correction
zstyle ':completion:*' completer _complete _correct _approximate
zstyle ':completion:*' verbose yes
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%d'
zstyle ':completion:*:messages' format '%d'
zstyle ':completion:*:warnings' format 'No matches for: %d'
zstyle ':completion:*:corrections' format '%d (errors: %e)'

# Ignore completion functions for commands we don’t have
zstyle ':completion:*:functions' ignored-patterns '_*'

# Complete process IDs with menu selection
zstyle ':completion:*:*:kill:*' menu yes select
zstyle ':completion:*:kill:*' force-list always

# History configuration
# https://zsh.sourceforge.io/Doc/Release/Options.html#History
HISTFILE="${ZSH_DATA_DIR}/history"
HISTSIZE=1000000000 SAVEHIST=1000000000
unsetopt share_history # OMZ enables shared history

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
if has bat; then
    export BAT_CONFIG_PATH="${XDG_CONFIG_HOME}"/bat/config BAT_PAGER="less"
    export MANPAGER="sh -c 'col -bx | bat -l man'" MANROFFOPT="-c"
fi

# direnv: change environment based on the current directory
# https://github.com/direnv/direnv
if has direnv; then
    eval "$(direnv hook zsh)"
    alias da="direnv allow"
fi

# duf: better `df` alternative
# https://github.com/muesli/duf
if has duf; then
    alias df=duf
elif has pydf; then
    alias df=pydf
fi

# exa: a modern replacement for ‘ls’.
# https://github.com/ogham/exa
if has exa; then
    alias l="exa --all --long --group"
fi

# gcloud: Google Cloud SDK
# https://cloud.google.com/sdk
export CLOUDSDK_CORE_DISABLE_USAGE_REPORTING=true
if [[ -e "${HOMEBREW_PREFIX}/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.zsh.inc" ]]; then
    source "${HOMEBREW_PREFIX}/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.zsh.inc"
elif [[ -e /usr/share/google-cloud-sdk/completion.zsh.inc ]]; then
    source /usr/share/google-cloud-sdk/completion.zsh.inc
fi

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

# go: programming language
# https://www.golang.org
export GOPATH="${XDG_CACHE_HOME}/go"
path=("${GOPATH}/bin" ${path})

# less: pager configuration
# https://man7.org/linux/man-pages/man1/less.1.html#OPTIONS
export PAGER="less" LESS="-FiMRSW -x4"
export LESSHISTFILE="${XDG_DATA_HOME}/less/history"
mkdir -p "${XDG_DATA_HOME}/less"
sl() { sort -u | less }

# npm: node package manager
# https://github.com/npm/cli
export NPM_CONFIG_USERCONFIG="${XDG_CONFIG_HOME}/npm/npmrc"

# parallel: run commands in parallel
# https://www.gnu.org/software/parallel/
export PARALLEL_HOME="${XDG_CONFIG_HOME}/parallel"
mkdir -p ${PARALLEL_HOME}

# poetry: python dependency management
# https://github.com/python-poetry/poetry
export POETRY_CACHE_DIR="${XDG_CACHE_HOME}/poetry"

# pw: a simple pwgen replacement
autoload -Uz pw

# python: programming language
# https://docs.python.org/3/
export PYTHONSTARTUP="${XDG_CONFIG_HOME}/python/startup.py"

# ripgrep: fast grep replacement
# https://github.com/BurntSushi/ripgrep
export RIPGREP_CONFIG_PATH="${XDG_CONFIG_HOME}"/ripgrep/config

# ruby: programming language
# https://www.ruby-lang.org
export GEM_HOME="${XDG_DATA_HOME}"/gem
export GEM_SPEC_CACHE="${XDG_CACHE_HOME}"/gem
export BUNDLE_USER_CONFIG="${XDG_CONFIG_HOME}"/bundle
export BUNDLE_USER_CACHE="${XDG_CACHE_HOME}"/bundle
export BUNDLE_USER_PLUGIN="${XDG_DATA_HOME}"/bundle

if [[ -e "${HOMEBREW_PREFIX}" ]]; then
    path=("${HOMEBREW_PREFIX}/opt/ruby/bin" ${path})
    path=("${HOMEBREW_PREFIX}/lib/ruby/gems/3.0.0/bin" ${path})
fi

# sqlite: database engine
# https://sqlite.org
export SQLITE_HISTORY=${XDG_DATA_HOME}/sqlite/history

# terraform: manage cloud infrastructure
# https://github.com/hashicorp/terraform
export CHECKPOINT_DISABLE=true
alias tf="terraform"
alias tfa="tf apply"
alias tfp="tf plan"

# vim: the editor
# https://github.com/vim/vim
export VIMINIT="set nocp | source ${XDG_CONFIG_HOME}/vim/vimrc"
export EDITOR="${commands[vim]}"

# youtube: download audio
alias yta="yt-dlp --extract-audio --audio-format mp3 --add-metadata"

# Load p10k prompt last
source "${${(%):-%x}:A:h}/.p10k.zsh"
