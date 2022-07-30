# user information (for git, gpg, etc)
export USER_NAME="Benedikt Böhm"
export USER_EMAIL="bb@xnull.de"

# force locale to english
export LANG="en_US.UTF-8"
export LC_CTYPE=${LANG}

# enforce truecolor support
export COLORTERM="truecolor"

# system path
typeset -TUx PATH path=(/{usr/,}{local/,}{s,}bin)

# user paths
# https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
export XDG_CONFIG_HOME="${HOME}/.config"
export XDG_CACHE_HOME="${HOME}/.cache"
export XDG_DATA_HOME="${HOME}/.local/share"
export XDG_STATE_HOME="${HOME}/.local/state"
export XDG_RUNTIME_DIR="${HOME}/.local/run"

mkdir -p "${XDG_CONFIG_HOME}"
mkdir -p "${XDG_CACHE_HOME}"
mkdir -p "${XDG_DATA_HOME}"
mkdir -p "${XDG_STATE_HOME}"
mkdir -p "${XDG_RUNTIME_DIR}"
chmod 0700 "${XDG_RUNTIME_DIR}"

# shell paths
# https://zsh.sourceforge.io/Intro/intro_3.html
ZDOTDIR="${XDG_CONFIG_HOME}/zsh"
ZSH_DATA_DIR="${XDG_DATA_HOME}/zsh"
ZSH_CACHE_DIR="${XDG_CACHE_HOME}/zsh"
ZSH_COMPDUMP="${ZSH_CACHE_DIR}/zcompdump"

mkdir -p "${ZSH_CACHE_DIR}"
mkdir -p "${ZSH_DATA_DIR}"

# shell functions
typeset -TUx FPATH fpath=(${ZDOTDIR} ${fpath[@]})
autoload -Uz add has

# install zgenom
if ! has "${XDG_CACHE_HOME}/zgenom"; then
    mkdir -p "${XDG_CACHE_HOME}" && \
    git clone https://github.com/jandamm/zgenom.git "${XDG_CACHE_HOME}/zgenom"
fi

# load zgenom
ZGEN_AUTOLOAD_COMPINIT=0
ZGEN_CUSTOM_COMPDUMP="${ZSH_COMPDUMP}"
COMPLETION_WAITING_DOTS="true"
source "${XDG_CACHE_HOME}/zgenom/zgenom.zsh"

# load instant prompt early except during update
P10K_INIT="${XDG_CACHE_HOME}/p10k-instant-prompt-${(%):-%n}.zsh"
if has "${ZGEN_INIT}" && has "${P10K_INIT}"; then
    source "${P10K_INIT}"
fi

# load zsh plugins
if ! zgenom saved; then
    # ohmyzsh: community driven zsh framework
    # https://github.com/ohmyzsh/ohmyzsh
    zgenom ohmyzsh

    # https://github.com/jandamm/zgenom-ext-eval
    zgenom load jandamm/zgenom-ext-eval

    # replace completion selection menu with fzf
    # https://github.com/Aloxaf/fzf-tab
    zgenom load Aloxaf/fzf-tab

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
    zgenom eval --name history-search-up "bindkey '^[[A' history-substring-search-up"
    zgenom eval --name history-search-down "bindkey '^[[B' history-substring-search-down"

    # additional completion definitions for Zsh.
    # https://github.com/zsh-users/zsh-completions
    zgenom load zsh-users/zsh-completions
fi

# use approximate completion with error correction
# https://zsh.sourceforge.io/Doc/Release/Completion-System.html#Control-Functions
zstyle ':completion:*' completer _complete _correct _approximate

# set descriptions format to enable group support
zstyle ':completion:*:descriptions' format '%d'
zstyle ':completion:*:messages' format '%d'
zstyle ':completion:*:warnings' format 'No matches for: %d'
zstyle ':completion:*:corrections' format '%d (errors: %e)'

# set list-colors to enable filename colorizing
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# improve make autocompletion
# https://unix.stackexchange.com/questions/657256/autocompletion-of-makefile-with-makro-in-zsh-not-correct-works-in-bash
zstyle ':completion::complete:make:*:targets' call-command true

# ignore completion functions for commands we don’t have
zstyle ':completion:*:functions' ignored-patterns '_*'

# ignore completion for git ORIG_HEAD
# https://stackoverflow.com/questions/12508595/ignore-orig-head-in-zsh-git-autocomplete#comment99936479_14325591
zstyle ':completion:*:*:git*:*' ignored-patterns '*ORIG_HEAD'

# preview directory content with exa when completing cd
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'exa --all --long --group $realpath'

# words are complete shell command arguments
autoload -Uz select-word-style
select-word-style shell

# history configuration
# https://zsh.sourceforge.io/Doc/Release/Options.html#History
HISTFILE="${ZSH_DATA_DIR}/history"
HISTSIZE=1000000000 SAVEHIST=1000000000
unsetopt share_history # OMZ enables shared history

# brew: the missing package manager
# https://github.com/Homebrew/brew
export HOMEBREW_BUNDLE_FILE="${XDG_CONFIG_HOME}/Brewfile"
export HOMEBREW_BUNDLE_NO_LOCK=1
export HOMEBREW_AUTO_UPDATE_SECS=86400
export HOMEBREW_CLEANUP_MAX_AGE_DAYS=7
export HOMEBREW_CLEANUP_PERIODIC_FULL_DAYS=1

alias bbd="brew bundle dump -f"
alias bz="brew uninstall --zap"

if ! zgenom saved && has /opt/homebrew/bin/brew; then
    zgenom eval --name brew "$(/opt/homebrew/bin/brew shellenv)"
    echo "-- zgenom: Updating Homebrew packages"
    brew update && \
    brew upgrade && \
    brew bundle install && \
    brew autoremove && \
    brew cleanup -s --prune=all && \
    chmod go-w "${HOMEBREW_PREFIX}/share"
fi

# ensure proper environment
add path "${HOMEBREW_PREFIX}/opt/coreutils/libexec/gnubin"
add path "${HOMEBREW_PREFIX}/opt/findutils/libexec/gnubin"
add path "${HOMEBREW_PREFIX}/opt/gawk/libexec/gnubin"
add path "${HOMEBREW_PREFIX}/opt/gnu-sed/libexec/gnubin"
add path "${HOMEBREW_PREFIX}/opt/gnu-tar/libexec/gnubin"
add path "${HOMEBREW_PREFIX}/opt/gnu-time/libexec/gnubin"
add path "${HOMEBREW_PREFIX}/opt/make/libexec/gnubin"
add fpath "${HOMEBREW_PREFIX}/share/zsh/site-functions"

# python: programming language
# https://docs.python.org/3/
export PYTHONSTARTUP="${XDG_CONFIG_HOME}/python/startup.py"
typeset -TUx PYTHONPATH pythonpath=()

add path "${HOMEBREW_PREFIX}/opt/python@3.10/bin"
add path "${HOMEBREW_PREFIX}/opt/python@3.10/libexec/bin"

zgenom-python-argcomplete() {
    zgenom eval --name $1 "$(register-python-argcomplete $1)"
}

if ! zgenom saved; then
    for __python_version in 3.9 3.10; do
        echo "-- zgenom: Updating Python ${__python_version}"
        PIP_REQUIRE_VIRTUALENV=false \
        "${HOMEBREW_PREFIX}/opt/python@${__python_version}/bin/pip3" \
            install --upgrade setuptools pip
    done
fi

# python/pipx: install python applications in isolated environments
# https://pypa.github.io/pipx/
export PIPX_HOME="${XDG_DATA_HOME}/pipx"
export PIPX_BIN_DIR="${PIPX_HOME}/bin"
add path "${PIPX_BIN_DIR}"

if ! zgenom saved; then
    echo "-- zgenom: Updating pipx packages"
    pipx upgrade-all --include-injected
    pipx inject copier "MarkupSafe<2.1.0"
    zgenom-python-argcomplete pipx
fi

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

if ! zgenom saved; then
    zgenom-python-argcomplete ansible
    zgenom-python-argcomplete ansible-config
    zgenom-python-argcomplete ansible-console
    zgenom-python-argcomplete ansible-doc
    zgenom-python-argcomplete ansible-galaxy
    zgenom-python-argcomplete ansible-inventory
    zgenom-python-argcomplete ansible-playbook
    zgenom-python-argcomplete ansible-pull
    zgenom-python-argcomplete ansible-vault
fi

# aws: Amazon Web Services CLI
# https://aws.amazon.com/cli/
export AWS_SHARED_CREDENTIALS_FILE="${XDG_CONFIG_HOME}/aws/credentials"
export AWS_CONFIG_FILE="${XDG_CONFIG_HOME}/aws/config"

if ! zgenom saved; then
    zgenom ohmyzsh plugins/aws
fi

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

# chef: infrastructure automation
# https://www.chef.io/
alias kcu="knife cookbook upload"
alias kda="knife diff cookbooks data_bags environments roles"
alias ks="kda --name-status"
alias kssh="easyssh -e='(ssh-exec-parallel)' -d='(knife)' -f='(coalesce host)'"

# colordiff: syntax highlighting for diff
# https://www.colordiff.org
cdl() { colordiff | less -R }

# dircolors: setup colors for ls and friends
# https://github.com/trapd00r/LS_COLORS
if ! zgenom saved; then
    zgenom clone trapd00r/LS_COLORS
    zgenom eval --name dircolors "$(dircolors -b $(zgenom api clone_dir trapd00r/LS_COLORS)/LS_COLORS)"
fi

# direnv: change environment based on the current directory
# https://github.com/direnv/direnv
alias da="direnv allow"

if ! zgenom saved; then
    zgenom eval --name direnv "$(direnv hook zsh)"
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
else
    alias l="ls -lah"
fi

alias lR="l -R"

# gcloud: Google Cloud SDK
# https://cloud.google.com/sdk
export CLOUDSDK_CORE_DISABLE_USAGE_REPORTING=true

if ! zgenom saved; then
    zgenom ohmyzsh plugins/gcloud
    echo "-- zgenom: Updating gcloud components"
    gcloud components update
fi

# git: distributed version control system
# https://github.com/git/git
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

autoload -Uz clone

if ! zgenom saved; then
    git config --global user.name "${USER_NAME}"
    git config --global user.email "${USER_EMAIL}"
fi

# gnupg: GNU privacy guard
# https://gnupg.org/
export GNUPGHOME="${XDG_DATA_HOME}/gnupg"
export GPG_TTY="${TTY}"
if ! zgenom saved; then
    zgenom ohmyzsh plugins/gpg-agent
fi

# go: programming language
# https://www.golang.org
export GOPATH="${XDG_CACHE_HOME}/go"
add path "${GOPATH}/bin"

# less: pager configuration
# https://man7.org/linux/man-pages/man1/less.1.html#OPTIONS
export PAGER="less" LESS="-FiMRSW -x4"
export LESSHISTFILE="${XDG_DATA_HOME}/less/history"
sl() { sort -u | less }

if ! zgenom saved; then
    mkdir -p "${XDG_DATA_HOME}/less"
fi

# man: unix documentation system
# https://www.nongnu.org/man-db/
if ! zgenom saved; then
    zgenom ohmyzsh plugins/colored-man-pages
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

if ! zgenom saved; then
    mkdir -p ${PARALLEL_HOME}
fi

# genpass: a simple pwgen replacement
if ! zgenom saved; then
    zgenom ohmyzsh plugins/genpass
fi

pw() { genpass-monkey | clipcopy }

# poetry: python dependency management
# https://github.com/python-poetry/poetry
if ! zgenom saved; then
    poetry config cache-dir "${XDG_CACHE_HOME}/poetry"
fi

# ripgrep: fast grep replacement
# https://github.com/BurntSushi/ripgrep
export RIPGREP_CONFIG_PATH="${XDG_CONFIG_HOME}"/ripgrep/config
alias rg="rg --color=always"

# rsync: fast incremental file transfer
# https://rsync.samba.org
if ! zgenom saved; then
    zgenom ohmyzsh plugins/rsync
fi

# ruby: programming language
# https://www.ruby-lang.org
export GEM_HOME="${XDG_DATA_HOME}"/gem
export GEM_SPEC_CACHE="${XDG_CACHE_HOME}"/gem
export BUNDLE_USER_CONFIG="${XDG_CONFIG_HOME}"/bundle
export BUNDLE_USER_CACHE="${XDG_CACHE_HOME}"/bundle
export BUNDLE_USER_PLUGIN="${XDG_DATA_HOME}"/bundle
add path "${HOMEBREW_PREFIX}"/opt/ruby/bin
add path "${HOMEBREW_PREFIX}"/lib/ruby/gems/*/bin

# sqlite: database engine
# https://sqlite.org
export SQLITE_HISTORY=${XDG_DATA_HOME}/sqlite/history

# ssh: secure shell
# https://www.openssh.com
alias ssu="ssh -o RequestTTY=force -o RemoteCommand='sudo -i'"

if ! zgenom saved; then
    mkdir -p "${XDG_CACHE_HOME}"/ssh
fi

# terraform: manage cloud infrastructure
# https://github.com/hashicorp/terraform
export CHECKPOINT_DISABLE=true
export TF_CLI_CONFIG_FILE="${XDG_CONFIG_HOME}/terraform.tfrc"

alias tf="terraform"
alias tfa="tf apply"
alias tfd="tf destroy"
alias tfi="tf import"
alias tfp="tf plan"

# terraform/checkov
#source <(register-python-argcomplete checkov)

# tmux: a terminal multiplexer
# https://github.com/tmux/tmux
export ZSH_TMUX_CONFIG="${XDG_CONFIG_HOME}/tmux/tmux.conf"
export ZSH_TMUX_DEFAULT_SESSION_NAME="default"
export ZSH_TMUX_FIXTERM="false"

if [[ -n "${SSH_CONNECTION}" && -z "${VSCODE_IPC_HOOK_CLI}" ]]; then
    export ZSH_TMUX_AUTOSTART="true"
fi

alias T=tmux

if ! zgenom saved; then
    zgenom ohmyzsh plugins/tmux
fi

# tpm: tmux plugin manager
# https://github.com/tmux-plugins/tpm
export TMUX_PLUGIN_MANAGER_PATH="${XDG_CACHE_HOME}/tmux/plugins"

if ! zgenom saved && ! has "${TMUX_PLUGIN_MANAGER_PATH}/tpm"; then
    mkdir -p "${TMUX_PLUGIN_MANAGER_PATH}" && \
    git clone https://github.com/tmux-plugins/tpm "${TMUX_PLUGIN_MANAGER_PATH}/tpm" && \
    ${TMUX_PLUGIN_MANAGER_PATH}/tpm/bin/install_plugins
fi

# vi improved
# https://github.com/vim/vim
export VIMINIT="set nocp | source ${XDG_CONFIG_HOME}/vim/vimrc"
export EDITOR="${commands[vim]}"

# vscode
# https://code.visualstudio.com
alias code="env -u XDG_RUNTIME_DIR code"

# wget: retrieve files using HTTP, HTTPS, FTP and FTPS
# https://www.gnu.org/software/wget/
export WGETRC="${XDG_CONFIG_HOME}/wgetrc"
alias wget="wget --hsts-file=\"${XDG_CACHE_HOME}/wget-hsts\""

# yarn:
alias yarn="yarn --use-yarnrc \"${XDG_CONFIG_HOME}/yarn/config\""

# youtube: download audio
# https://github.com/yt-dlp/yt-dlp
alias yta="yt-dlp --extract-audio --audio-format mp3 --add-metadata"

# add local path last so it takes precendence
add path "${XDG_CONFIG_HOME}/bin"

# save zgenom init script
if ! zgenom saved; then
    zgenom save
fi

# zgenom update and reset
alias zre="exec zsh"
alias zup="zgenom selfupdate && zgenom update && zre"
alias zx="sudo rm -rf ${XDG_CACHE_HOME} && zre"

# load p10k prompt last
source "${ZDOTDIR}/.p10k.zsh"
