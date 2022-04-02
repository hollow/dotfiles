# user information (for git, gpg, etc)
export USER_NAME="Benedikt Böhm"
export USER_EMAIL="bb@xnull.de"

# force locale to english
export LANG="en_US.UTF-8"
export LC_CTYPE=${LANG}

# user paths
# https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
export XDG_CONFIG_HOME="${HOME}/.config"
export XDG_CACHE_HOME="${HOME}/.cache"
export XDG_DATA_HOME="${HOME}/.local/share"
export XDG_STATE_HOME="${HOME}/.local/state"
export XDG_RUNTIME_DIR="${HOME}/.local/run"

# shell paths
# https://zsh.sourceforge.io/Intro/intro_3.html
ZDOTDIR="${XDG_CONFIG_HOME}/zsh"
ZSH_CACHE_DIR="${XDG_CACHE_HOME}/zsh" && mkdir -p "${ZSH_CACHE_DIR}"
ZSH_DATA_DIR="${XDG_DATA_HOME}/zsh" && mkdir -p "${ZSH_DATA_DIR}"
ZSH_COMPDUMP="${ZSH_CACHE_DIR}/zcompdump"

# shell functions
typeset -TUx FPATH fpath=(${ZDOTDIR} ${fpath[@]})
autoload -Uz has

# system path
typeset -TUx PATH path=("${XDG_CONFIG_HOME}/bin" /{usr/,}{local/,}{s,}bin)

# enforce truecolor support
export COLORTERM="truecolor"

# brew: the missing package manager
# https://github.com/Homebrew/brew
if [[ -e /opt/homebrew ]]; then
    source "${ZDOTDIR}/brew"
fi

# enable Powerlevel10k instant prompt
if [[ -r "${XDG_CACHE_HOME}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# install zgenom
if [[ ! -d "${XDG_CACHE_HOME}/zgenom" ]]; then
    git clone https://github.com/jandamm/zgenom.git "${XDG_CACHE_HOME}/zgenom"
fi

# load zgenom
ZGEN_CUSTOM_COMPDUMP="${ZSH_COMPDUMP}"
source "${XDG_CACHE_HOME}/zgenom/zgenom.zsh"

# if the init script doesn't exist
if ! zgenom saved; then
    # https://github.com/jandamm/zgenom-ext-eval
    zgenom load jandamm/zgenom-ext-eval

    # Ohmyzsh base library
    zgenom ohmyzsh

    # build and load ls colors
    # https://github.com/trapd00r/LS_COLORS
    zgenom clone trapd00r/LS_COLORS
    zgenom eval $(dircolors -b $(zgenom api clone_dir trapd00r/LS_COLORS)/LS_COLORS)

    # https://github.com/romkatv/powerlevel10k
    zgenom load romkatv/powerlevel10k powerlevel10k

    # feature-rich syntax highlighting for ZSH
    # https://github.com/zdharma-continuum/fast-syntax-highlighting
    zgenom load zdharma-continuum/fast-syntax-highlighting

    # fish-like autosuggestions for zsh
    # https://github.com/zsh-users/zsh-autosuggestions/blob/master/INSTALL.md
    zgenom load zsh-users/zsh-autosuggestions

    # automatically close quotes, brackets and other delimiters
    # https://github.com/hlissner/zsh-autopair
    zgenom load hlissner/zsh-autopair

    # help remembering those aliases you defined once
    # https://github.com/djui/alias-tips
    zgenom load djui/alias-tips

    # load zsh history search and create bindings for it
    # https://github.com/zsh-users/zsh-history-substring-search
    zgenom load zsh-users/zsh-history-substring-search
    zgenom eval "bindkey '^[[A' history-substring-search-up"
    zgenom eval "bindkey '^[[B' history-substring-search-down"

    # additional completion definitions for Zsh.
    # https://github.com/zsh-users/zsh-completions
    zgenom load zsh-users/zsh-completions

    # save all to init script
    zgenom save
fi

# words are complete shell command arguments
autoload -Uz select-word-style
select-word-style shell

# speed up slow completions with a cache
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ${ZSH_CACHE_DIR}

# use approximate completion with error correction
zstyle ':completion:*' completer _complete _correct _approximate
zstyle ':completion:*' verbose yes
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%d'
zstyle ':completion:*:messages' format '%d'
zstyle ':completion:*:warnings' format 'No matches for: %d'
zstyle ':completion:*:corrections' format '%d (errors: %e)'

# ignore completion functions for commands we don’t have
zstyle ':completion:*:functions' ignored-patterns '_*'

# complete process IDs with menu selection
zstyle ':completion:*:*:kill:*' menu yes select
zstyle ':completion:*:kill:*' force-list always

# history configuration
# https://zsh.sourceforge.io/Doc/Release/Options.html#History
HISTFILE="${ZSH_DATA_DIR}/history"
HISTSIZE=1000000000 SAVEHIST=1000000000
unsetopt share_history # OMZ enables shared history

# act: run your GitHub Actions locally
# https://github.com/nektos/act
alias act="act --container-architecture=linux/amd64"

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
zgenom ohmyzsh plugins/aws

# bat: cat(1) clone with wings
# https://github.com/sharkdp/bat
if has bat; then
    export BAT_CONFIG_PATH="${XDG_CONFIG_HOME}"/bat/config BAT_PAGER="less"
    export MANPAGER="sh -c 'col -bx | bat -l man'" MANROFFOPT="-c"
fi

# boto: AWS SDK for Python
# https://github.com/boto/boto3
export BOTO_CONFIG="${XDG_DATA_HOME}/boto"
cat > "${BOTO_CONFIG}" <<EOF
[GSUtil]
state_dir = ${XDG_DATA_HOME}/gsutil
EOF

# chef
_chef_dirs=(cookbooks data_bags environments roles)
kd() { knife diff "$@" | cdl }
alias kcu="knife cookbook upload"
alias kda="kd ${_chef_dirs}"
alias ks="knife diff ${_chef_dirs} --name-status"

# colordiff
cdl() { colordiff | less -R }

# direnv: change environment based on the current directory
# https://github.com/direnv/direnv
if has direnv; then
    eval "$(direnv hook zsh)"
    alias da="direnv allow"
fi

# docker: container runtime
# https://www.docker.com
zgenom ohmyzsh --completion plugins/docker
zgenom ohmyzsh --completion plugins/docker-compose

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
else
    alias l="ls -lah"
fi

alias lR="l -R"

# gcloud: Google Cloud SDK
# https://cloud.google.com/sdk
export CLOUDSDK_CORE_DISABLE_USAGE_REPORTING=true
if [[ -e "${HOMEBREW_PREFIX}/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.zsh.inc" ]]; then
    source "${HOMEBREW_PREFIX}/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.zsh.inc"
elif [[ -e /usr/share/google-cloud-sdk/completion.zsh.inc ]]; then
    source /usr/share/google-cloud-sdk/completion.zsh.inc
fi

__gcloud_update() {
    gcloud components update
}

# git: distributed version control system
# https://github.com/git/git
export GIT_AUTHOR_NAME="${USER_NAME}"
export GIT_AUTHOR_EMAIL="${USER_EMAIL}"
export GIT_COMMITTER_NAME="${USER_NAME}"
export GIT_COMMITTER_EMAIL="${USER_EMAIL}"

# https://stackoverflow.com/questions/12508595/ignore-orig-head-in-zsh-git-autocomplete
zstyle ':completion:*:*' ignored-patterns '*ORIG_HEAD'

autoload -Uz clone

alias c="git changes"
alias ga="git add --all"
alias gap="git add --patch"
alias gcm="git co \$(git main-branch)"
alias gcu="git co upstream"
alias gd="git df"
alias gdc="git dc"
alias gdm="git df \$(git main-branch)"
alias gdu="git df upstream/\$(git main-branch)"
alias gf="git fetch --prune"
alias gl="git lg"
alias gp="git pull"
alias gpr="git pull --rebase --autostash"
alias grh="git reset HEAD"
alias s="git st ."

# gnupg: GNU privacy guard
# https://gnupg.org/
export GNUPGHOME="${XDG_DATA_HOME}/gnupg"
export GPG_TTY=$(tty)
zgenom ohmyzsh plugins/gpg-agent

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

# man: unix documentation system
# https://www.nongnu.org/man-db/
zgenom ohmyzsh plugins/colored-man-pages
if has manpath; then
  typeset -TUx MANPATH manpath=(${(s[:])$(env -u MANPATH manpath)})
fi

# mc: midnight commander
# https://midnight-commander.org
export MC_SKIN="${XDG_CONFIG_HOME}/mc/solarized-dark-truecolor.ini"
alias mc="mc --nosubshell"

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

# genpass: a simple pwgen replacement
zgenom ohmyzsh plugins/genpass
pw() { genpass-monkey | clipcopy }

# python: programming language
# https://docs.python.org/3/
path=("${HOMEBREW_PREFIX}/opt/python/libexec/bin" ${path})
export PYTHONSTARTUP="${XDG_CONFIG_HOME}/python/startup.py"
zgenom ohmyzsh plugins/pip
zgenom ohmyzsh plugins/python

__python_update() {
    # update all globally installed python modules
    pip3 install --upgrade -r <(pip3 freeze)
}

# ripgrep: fast grep replacement
# https://github.com/BurntSushi/ripgrep
export RIPGREP_CONFIG_PATH="${XDG_CONFIG_HOME}"/ripgrep/config
alias rg="rg --color=always"

# rsync: fast incremental file transfer
# https://rsync.samba.org
zgenom ohmyzsh plugins/rsync

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

# ssh: secure shell
# https://www.openssh.com
mkdir -p "${XDG_CACHE_HOME}"/ssh
zstyle :omz:plugins:ssh-agent agent-forwarding yes
zstyle :omz:plugins:ssh-agent identities id_rsa id_ed25519
zgenom ohmyzsh plugins/ssh-agent
alias ssu="ssh -o RequestTTY=force -o RemoteCommand='sudo -i'"

# terraform: manage cloud infrastructure
# https://github.com/hashicorp/terraform
export CHECKPOINT_DISABLE=true
alias tf="terraform"
alias tfa="tf apply"
alias tfd="tf destroy"
alias tfp="tf plan"

# tmux: a terminal multiplexer
# https://github.com/tmux/tmux
export ZSH_TMUX_CONFIG="${XDG_CONFIG_HOME}/tmux/tmux.conf"
export ZSH_TMUX_DEFAULT_SESSION_NAME="default"
export ZSH_TMUX_FIXTERM="false"
if [[ -n "${SSH_CONNECTION}" && -z "${VSCODE_IPC_HOOK_CLI}" ]]; then
    export ZSH_TMUX_AUTOSTART="true"
fi
zgenom ohmyzsh plugins/tmux
alias T=tmux

# tpm: tmux plugin manager
# https://github.com/tmux-plugins/tpm
export TMUX_PLUGIN_MANAGER_PATH="${XDG_CACHE_HOME}/tmux/plugins"
if [[ ! -d "${TMUX_PLUGIN_MANAGER_PATH}/tpm" ]]; then
    mkdir -p "${TMUX_PLUGIN_MANAGER_PATH}"
    git clone https://github.com/tmux-plugins/tpm "${TMUX_PLUGIN_MANAGER_PATH}/tpm"
    ${TMUX_PLUGIN_MANAGER_PATH}/tpm/bin/install_plugins
fi

# vi improved
# https://github.com/vim/vim
export VIMINIT="set nocp | source ${XDG_CONFIG_HOME}/vim/vimrc"
export EDITOR="${commands[vim]}"

# wget: retrieve files using HTTP, HTTPS, FTP and FTPS
# https://www.gnu.org/software/wget/
export WGETRC="${XDG_CONFIG_HOME}/wgetrc"
alias wget="wget --hsts-file=\"${XDG_CACHE_HOME}/wget-hsts\""

# yarn:
alias yarn="yarn --use-yarnrc \"${XDG_CONFIG_HOME}/yarn/config\""

# youtube: download audio
# https://github.com/yt-dlp/yt-dlp
alias yta="yt-dlp --extract-audio --audio-format mp3 --add-metadata"

# update system and shell
up() {
    # update brew packages on macOS
    if has __brew_update; then
        __brew_update
    fi

    __gcloud_update
    __python_update

    # upudate oh-my-zsh and plugins
    zgenom selfupdate
    zgenom update
}

# reload shell
alias zre="zgenom reset && exec zsh"

# reset cache and start from scratch
alias zx="sudo rm -rf ${XDG_CACHE_HOME} && exec zsh"

# load p10k prompt last
source "${ZDOTDIR}/.p10k.zsh"
