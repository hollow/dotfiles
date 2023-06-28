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

mkdir -p "${ZSH_CACHE_DIR}"{,/completions}
mkdir -p "${ZSH_DATA_DIR}"

# shell functions
typeset -TUx FPATH fpath=(
    ${ZDOTDIR}
    ${ZSH_CACHE_DIR}/completions
    ${fpath[@]}
)

add() {
    eval "${1}[1,0]"='("${@[2,-1]}")'
}

has() {
    type "$1" &>/dev/null || test -e "/$1"
}

# homebrew path as early as possible
if has /opt/homebrew/bin/brew; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# powerlevel10k instant prompt
if has "${XDG_CACHE_HOME}/p10k-instant-prompt-${(%):-%n}.zsh"; then
    source "${XDG_CACHE_HOME}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# zinit: Flexible and fast ZSH plugin manager
# https://github.com/zdharma-continuum/zinit
if ! has "${ZINIT_HOME:=${XDG_DATA_HOME}/zinit/zinit.git}"; then
    mkdir -p "$(dirname ${ZINIT_HOME})"
    git clone https://github.com/zdharma-continuum/zinit.git "${ZINIT_HOME}"
fi

declare -A ZINIT
ZINIT[ZCOMPDUMP_PATH]="${ZSH_COMPDUMP}"
source "${ZINIT_HOME}/zinit.zsh"

# zinit update and reset
alias zre="exec zsh"
alias zup="zi update --all"
alias zx="sudo rm -rf ${XDG_CACHE_HOME} && zre"

# https://github.com/NICHOLAS85/z-a-eval
zi load NICHOLAS85/z-a-eval

# ohmyzsh: community driven zsh framework
# https://github.com/ohmyzsh/ohmyzsh
COMPLETION_WAITING_DOTS="true"
zi snippet OMZL::clipboard.zsh
zi snippet OMZL::completion.zsh
zi snippet OMZL::directories.zsh
zi snippet OMZL::functions.zsh
zi snippet OMZL::grep.zsh
zi snippet OMZL::history.zsh
zi snippet OMZL::key-bindings.zsh
zi snippet OMZL::spectrum.zsh
zi snippet OMZL::termsupport.zsh

# add missing dotdot from ohmyzsh
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."

# shell options
setopt extendedglob

# additional completion definitions for Zsh.
# https://github.com/zsh-users/zsh-completions
zi blockf atpull'zinit creinstall -q .' \
    for zsh-users/zsh-completions

# load completion system
autoload compinit
compinit -d "${ZSH_COMPDUMP}"

# feature-rich syntax highlighting for ZSH
# https://github.com/zdharma-continuum/fast-syntax-highlighting
zi load zdharma-continuum/fast-syntax-highlighting

# fish-like autosuggestions for zsh
# https://github.com/zsh-users/zsh-autosuggestions/blob/master/INSTALL.md
zi load zsh-users/zsh-autosuggestions

# automatically close quotes, brackets and other delimiters
# https://github.com/hlissner/zsh-autopair
zi load hlissner/zsh-autopair

# reminds you to use existing aliases for commands you just typed
# https://github.com/MichaelAquilina/zsh-you-should-use
zi load MichaelAquilina/zsh-you-should-use
YSU_MESSAGE_POSITION="after"

# load zsh history search and create bindings for it
# https://github.com/zsh-users/zsh-history-substring-search
zi load zsh-users/zsh-history-substring-search
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# replace completion selection menu with fzf
# https://github.com/Aloxaf/fzf-tab
if has fzf && ! has /.syno; then
    zi load Aloxaf/fzf-tab
fi

# use approximate completion with error correction
# https://zsh.sourceforge.io/Doc/Release/Completion-System.html#Control-Functions
zstyle ':completion:*' completer _complete _correct _approximate

# set descriptions format to enable group support
zstyle ':completion:*:descriptions' format '%d'
zstyle ':completion:*:messages' format '%d'
zstyle ':completion:*:warnings' format 'No matches for: %d'
zstyle ':completion:*:corrections' format '%d (errors: %e)'

# improve make autocompletion
# https://unix.stackexchange.com/questions/657256/autocompletion-of-makefile-with-makro-in-zsh-not-correct-works-in-bash
zstyle ':completion::complete:make:*:targets' call-command true

# ignore completion functions for commands we don’t have
zstyle ':completion:*:functions' ignored-patterns '_*'

# ignore completion for git ORIG_HEAD
# https://stackoverflow.com/questions/12508595/ignore-orig-head-in-zsh-git-autocomplete#comment99936479_14325591
zstyle ':completion:*:*:git*:*' ignored-patterns '*ORIG_HEAD'

# disable sort when completing `git checkout`
zstyle ':completion:*:git-checkout:*' sort false

# preview directory content with exa when completing cd
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'exa --all --long --group $realpath'

# words are complete shell command arguments
autoload -Uz select-word-style
select-word-style shell

# history configuration
# https://zsh.sourceforge.io/Doc/Release/Options.html#History
HISTSIZE=2000000000 SAVEHIST=1000000000
HISTFILE="${ZSH_DATA_DIR}/history"
ln -nfs "${ZSH_DATA_DIR}/history" "${HOME}/.zsh_history"

# disable Apples history sharing sessions
# https://apple.stackexchange.com/a/427568
echo 'SHELL_SESSIONS_DISABLE=1' > "${HOME}/.zshenv"

# brew: the missing package manager
# https://github.com/Homebrew/brew
export HOMEBREW_BUNDLE_FILE="${XDG_CONFIG_HOME}/Brewfile"
export HOMEBREW_BUNDLE_NO_LOCK=1
export HOMEBREW_AUTO_UPDATE_SECS=86400
export HOMEBREW_CLEANUP_MAX_AGE_DAYS=7
export HOMEBREW_CLEANUP_PERIODIC_FULL_DAYS=1

alias bbd="brew bundle dump -f"
alias bz="brew uninstall --zap"

brew-update() {
    brew update && \
    brew upgrade && \
    brew bundle install && \
    brew autoremove && \
    brew cleanup -s --prune=all && \
    chmod go-w "${HOMEBREW_PREFIX}/share"
}

zi id-as"brew" has"brew" as"null" \
    atclone"brew-update" \
    atpull"%atclone" run-atpull \
    for zdharma-continuum/null

# ensure proper environment
if has brew; then
    add path "${HOMEBREW_PREFIX}/opt/coreutils/libexec/gnubin"
    add path "${HOMEBREW_PREFIX}/opt/findutils/libexec/gnubin"
    add path "${HOMEBREW_PREFIX}/opt/gawk/libexec/gnubin"
    add path "${HOMEBREW_PREFIX}/opt/gnu-sed/libexec/gnubin"
    add path "${HOMEBREW_PREFIX}/opt/gnu-tar/libexec/gnubin"
    add path "${HOMEBREW_PREFIX}/opt/gnu-time/libexec/gnubin"
    add path "${HOMEBREW_PREFIX}/opt/grep/libexec/gnubin"
    add path "${HOMEBREW_PREFIX}/opt/make/libexec/gnubin"
    add fpath "${HOMEBREW_PREFIX}/share/zsh/site-functions"
fi

# python: programming language
# https://docs.python.org/3/
export PYTHONSTARTUP="${XDG_CONFIG_HOME}/python/startup.py"

PYTHON_VERSION=$(brew ls | sed -n 's/python@//p' | tail -n1)
add path "${HOMEBREW_PREFIX}/opt/python@${PYTHON_VERSION}/bin"
add path "${HOMEBREW_PREFIX}/opt/python@${PYTHON_VERSION}/libexec/bin"

echo -e "[global]\nrequire-virtualenv = True" \
    > "${XDG_CONFIG_HOME}/pip/pip.conf"

python-update() {
    if has brew; then
        local v
        for v in $(brew ls | sed -n 's/python@//p'); do
            PIP_REQUIRE_VIRTUALENV=false \
            "${HOMEBREW_PREFIX}/opt/python@${v}/bin/pip${v}" \
                install --upgrade setuptools pip
        done
    fi
}

zi snippet OMZP::python
zi id-as"python" as"null" \
    atclone"python-update" \
    atpull"%atclone" run-atpull \
    for zdharma-continuum/null

# python/pipx: install python applications in isolated environments
# https://pypa.github.io/pipx/
export PIPX_HOME="${XDG_DATA_HOME}/pipx"
export PIPX_BIN_DIR="${PIPX_HOME}/bin"
add path "${PIPX_BIN_DIR}"

pipx-update() {
    pipx upgrade-all --include-injected
}

zi id-as"pipx" has"pipx" nocompile \
    atclone"pipx-update" \
    atpull"%atclone" run-atpull \
    eval"register-python-argcomplete pipx" \
    for zdharma-continuum/null

# python/poetry: python dependency management
# https://github.com/python-poetry/poetry
poetry-update() {
    poetry self update
    poetry config cache-dir "${XDG_CACHE_HOME}/poetry"

    # https://github.com/python-poetry/poetry/issues/7344#issuecomment-1386841002
    poetry self lock
    poetry self install --sync

    # https://github.com/MousaZeidBaker/poetry-plugin-up
    poetry self add poetry-plugin-up
}

zi snippet OMZP::poetry
zi id-as"poetry" has"pipx" as"null" \
    atclone"poetry-update" \
    atpull"%atclone" run-atpull \
    for zdharma-continuum/null

# 1password: remembers all your passwords for you
# https://1password.com
op-update() {
    has brew && brew install --cask 1password/tap/1password-cli
    has code && code --force --install-extension 1Password.op-vscode
}

zi snippet OMZP::1password
zi id-as"1password" has"op" nocompile \
    atclone"op-update" \
    atpull"%atclone" run-atpull \
    for zdharma-continuum/null

if has "${XDG_CONFIG_HOME}/op/plugins.sh"; then
    source "${XDG_CONFIG_HOME}/op/plugins.sh"
fi

# android: development kit
# https://developer.android.com/studio/command-line/variables
export ANDROID_EMULATOR_HOME="${XDG_CONFIG_HOME}/android"

# ansible: simple IT automation
# https://github.com/ansible/ansible
export ANSIBLE_GALAXY_CACHE_DIR="${XDG_CACHE_HOME}/ansible"
export ANSIBLE_GALAXY_TOKEN_PATH="${XDG_DATA_HOME}/ansible/galaxy_token"
export ANSIBLE_LOCAL_TEMP="${XDG_RUNTIME_DIR}/ansible/tmp"
export ANSIBLE_PERSISTENT_CONTROL_PATH_DIR="${XDG_RUNTIME_DIR}/ansible/cp"

alias ad="ansible-doc"
alias ai="ansible-inventory"
alias ap="ansible-playbook"

asu() {
    local pattern="$1" && shift
    ansible "${pattern}" -b -m shell -a "$@"
}

export ARA_BASE_DIR="${XDG_DATA_HOME}/ara/server"
export ARA_DATABASE_NAME="${ARA_BASE_DIR}/ansible.sqlite"
export ARA_SETTINGS="${ARA_BASE_DIR}/settings.yaml"

# aws: Amazon Web Services CLI
# https://aws.amazon.com/cli/
export AWS_SHARED_CREDENTIALS_FILE="${XDG_CONFIG_HOME}/aws/credentials"
export AWS_CONFIG_FILE="${XDG_CONFIG_HOME}/aws/config"
zi snippet OMZP::aws

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
parallel_composite_upload_threshold = 150M
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

# consul: distributed, highly available service discovery
# https://github.com/hashicorp/consul
complete -o nospace -C consul consul

# copier
copier-each() {
    for i in */.copier-answers.yml; do
        pushd ${i/\/.copier-answers.yml} &>/dev/null
        echo && pwd
        eval "$@"
        popd &>/dev/null
    done
}

# dircolors: setup colors for ls and friends
# https://github.com/trapd00r/LS_COLORS
zi eval"dircolors -b LS_COLORS" \
    atload'zstyle ":completion:*" list-colors "${(s.:.)LS_COLORS}"' \
    for trapd00r/LS_COLORS

# direnv: change environment based on the current directory
# https://github.com/direnv/direnv
zi from"gh-r" as"program" mv"direnv* -> direnv" \
    for direnv/direnv

eval "$(direnv hook zsh)"

alias da="direnv allow"

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
zi snippet OMZP::gcloud

gcloud-update() {
    gcloud components update
}

zi id-as"gcloud" has"gcloud" as"null" \
    atclone"gcloud-update" \
    atpull"%atclone" run-atpull \
    for zdharma-continuum/null

# git: distributed version control system
# https://github.com/git/git
alias c="git changes"
alias ga="git add --all"
alias gap="git add --patch"
alias gcl="git cleanup && git checkout-latest main && git dmb -y"
alias gcm="git co \$(git main-branch)"
alias gcu="git co upstream"
alias gd="git diff"
alias gdc="git dc"
alias gdm="git diff \$(git main-branch)"
alias gdu="git diff upstream/\$(git main-branch)"
alias gf="git fetch --prune"
alias gl="git lg"
alias gp="git pull"
alias gpr="git pull --rebase --autostash"
alias grh="git reset HEAD"
alias gsp="git show -p"
alias s="git st ."

autoload -Uz clone

git-update() {
    git config --global user.name "${USER_NAME}"
    git config --global user.email "${USER_EMAIL}"
}

git-each () {
	for i in */.git; do
		pushd ${i/\/.git} &> /dev/null
		echo && pwd
		eval "$@"
		popd &> /dev/null
	done
}

hub-repo-list() {
    gh repo list --limit 1000 --json nameWithOwner "$@" |
    jq -r '.[].nameWithOwner'
}

hub-clone-all() {
    hub-repo-list --no-archived "$@" |
    parallel --bar --tagstring "[{}]" --jobs 5 \
        git-clone-clean-main https://github.com/{} "${HOME}/src/{}"
}

hub-remove-archived() {
    hub-repo-list --archived "$@" |
    parallel --bar --tagstring "[{}]" \
        rm -rf "${HOME}/src/{}"
}

hub-enforce-admins() {
    repo=$(git remote get-url origin | perl -pe 's/.*github.com\///')
    branch=$(git main-branch)
    gh api -X POST /repos/${repo}/branches/${branch}/protection/enforce_admins | jq
}

hub-skip-admins() {
    repo=$(git remote get-url origin | perl -pe 's/.*github.com\///')
    branch=$(git main-branch)
    gh api -X DELETE /repos/${repo}/branches/${branch}/protection/enforce_admins | jq
    gh api /repos/${repo}/branches/${branch}/protection/enforce_admins | jq
}

pr() {
    git push && \
    gh pr create -f "$@"
}

zi id-as"git" has"git" as"null" \
    atclone"git-update" \
    atpull"%atclone" run-atpull \
    for zdharma-continuum/null

# gnupg: GNU privacy guard
# https://gnupg.org/
export GNUPGHOME="${XDG_DATA_HOME}/gnupg"
export GPG_TTY="${TTY}"

# go: programming language
# https://www.golang.org
export GOPATH="${XDG_CACHE_HOME}/go"
add path "${GOPATH}/bin"

# ip: helper to get public ip
# http://4.ifconfig.pro
IP() {
    curl -s http://4.ifconfig.pro/ip.host | awk '{print $1}'
}

# less: pager configuration
# https://man7.org/linux/man-pages/man1/less.1.html#OPTIONS
export PAGER="less" LESS="--ignore-case --LONG-PROMPT --RAW-CONTROL-CHARS --HILITE-UNREAD --quit-if-one-screen --tabs=4"
export LESSHISTFILE="${XDG_DATA_HOME}/less/history"
mkdir -p "$(dirname "${LESSHISTFILE}")"
sl() { sort -u | less }

# man: unix documentation system
# https://www.nongnu.org/man-db/
zi snippet OMZP::colored-man-pages

# mc: midnight commander
# https://midnight-commander.org
export MC_SKIN="${XDG_CONFIG_HOME}/mc/solarized-dark-truecolor.ini"
alias mc="mc --nosubshell"

# nomad: workload orchestrator
# https://github.com/hashicorp/nomad
complete -o nospace -C nomad nomad

# npm: node package manager
# https://github.com/npm/cli
export NPM_CONFIG_USERCONFIG="${XDG_CONFIG_HOME}/npm/npmrc"

# parallel: run commands in parallel
# https://www.gnu.org/software/parallel/
export PARALLEL_HOME="${XDG_CONFIG_HOME}/parallel"
mkdir -p ${PARALLEL_HOME}

# pw: a simple pwgen replacement
# https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/genpass
zi snippet OMZP::genpass
pw() { genpass-monkey | clipcopy }

# ripgrep: fast grep replacement
# https://github.com/BurntSushi/ripgrep
export RIPGREP_CONFIG_PATH="${XDG_CONFIG_HOME}"/ripgrep/config
alias rg="rg --color=always"

# rsync: fast incremental file transfer
# https://rsync.samba.org
zi snippet OMZP::rsync

# ruby: programming language
# https://www.ruby-lang.org
export GEM_HOME="${XDG_DATA_HOME}"/gem
export GEM_SPEC_CACHE="${XDG_CACHE_HOME}"/gem
export BUNDLE_USER_CONFIG="${XDG_CONFIG_HOME}"/bundle
export BUNDLE_USER_CACHE="${XDG_CACHE_HOME}"/bundle
export BUNDLE_USER_PLUGIN="${XDG_DATA_HOME}"/bundle

if has brew; then
    add path "${HOMEBREW_PREFIX}"/opt/ruby/bin
    add path "${HOMEBREW_PREFIX}"/lib/ruby/gems/*/bin
fi

# sqlite: database engine
# https://sqlite.org
export SQLITE_HISTORY=${XDG_DATA_HOME}/sqlite/history

# ssh: secure shell
# https://www.openssh.com
alias ssu="sshlive -o RequestTTY=force -o RemoteCommand='sudo -i'"

mkdir -p "${HOME}/.ssh" "${XDG_CACHE_HOME}"/ssh
chmod 0700 "${HOME}/.ssh"

ln -nfs "${XDG_CONFIG_HOME}/ssh/$(uname -s).conf" "${HOME}/.ssh/config"
chmod 0600 "${HOME}/.ssh/config"

# https://1password.community/discussion/comment/660153/#Comment_660153
if [[ -e "${HOME}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock" ]]; then
    ln -nfs "${HOME}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock" "${HOME}/.ssh/ssh_auth_sock"
elif [[ -n "${SSH_TTY}" && -S "${SSH_AUTH_SOCK}" && "${SSH_AUTH_SOCK}" != "${HOME}/.ssh/ssh_auth_sock" ]]; then
    ln -nfs "${SSH_AUTH_SOCK}" "${HOME}/.ssh/ssh_auth_sock"
fi

export SSH_AUTH_SOCK="${HOME}/.ssh/ssh_auth_sock"

# terraform: manage cloud infrastructure
# https://github.com/hashicorp/terraform
export CHECKPOINT_DISABLE=true
export TF_PLUGIN_CACHE_DIR="${XDG_CACHE_HOME}/terraform/plugins"
mkdir -p "${TF_PLUGIN_CACHE_DIR}"
ln -nfs "${XDG_CONFIG_HOME}/terraform" "${HOME}/.terraform.d"

alias tf="terraform"
alias tfa="tf apply"
alias tfd="tf destroy"
alias tfi="tf import"
alias tfp="tf plan"

# terraform/checkov: static code analysis tool for Terraform
# https://github.com/bridgecrewio/checkov
zi id-as"checkov" has"checkov" as"null" \
    eval"register-python-argcomplete checkov" \
    for zdharma-continuum/null

# tmux: a terminal multiplexer
# https://github.com/tmux/tmux
export ZSH_TMUX_CONFIG="${XDG_CONFIG_HOME}/tmux/tmux.conf"
export ZSH_TMUX_DEFAULT_SESSION_NAME="default"
export ZSH_TMUX_FIXTERM="false"
zi snippet OMZP::tmux
alias T=tmux

# tmux/tpm: tmux plugin manager
# https://github.com/tmux-plugins/tpm
export TMUX_PLUGIN_MANAGER_PATH="${XDG_CACHE_HOME}/tmux/plugins"

if ! has "${TMUX_PLUGIN_MANAGER_PATH}/tpm"; then
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

# replay all completions
zi cdreplay -q

# add local path last so it takes precendence
add path "${XDG_CONFIG_HOME}/bin"

# Powerlevel10k is a theme for Zsh
# https://github.com/romkatv/powerlevel10k
zi load romkatv/powerlevel10k
source "${ZDOTDIR}"/.p10k.zsh
