# enable debug mode
# DOT_DEBUG=1

# user information (for git, gpg, etc)
export USER_NAME="Benedikt Böhm"
export USER_EMAIL="bb@xnull.de"

# force locale to english
export LANG="en_US.UTF-8"
export LC_CTYPE=${LANG}

# enforce truecolor support
export COLORTERM="truecolor"

# shell options
setopt extendedglob

# words are complete shell command arguments
autoload -Uz select-word-style
select-word-style shell

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

mkdir -p "${ZSH_CACHE_DIR}"{,/completions}
mkdir -p "${ZSH_DATA_DIR}"

# shell functions
typeset -TUx FPATH fpath=(
    ${ZDOTDIR}
    ${ZSH_CACHE_DIR}/completions
    ${fpath[@]}
)

# load standarf functions
autoload -Uz add clone debug has link log
autoload -Uz :each :parallel

# add homebrew path as early as possible
if has /opt/homebrew/bin/brew; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# zi: Flexible and fast ZSH plugin manager
# https://github.com/z-shell/zi
typeset -Ag ZI
ZI[HOME_DIR]="${XDG_CACHE_HOME}/zi"
ZI[BIN_DIR]="${ZI[HOME_DIR]}/bin"
source "${ZDOTDIR}/zzinit" && zzinit

alias zre="exec zsh"
alias zx="sudo rm -rf ${XDG_CACHE_HOME} && zre"

zup() {
    zi self-update
    zi update --all
}

# zinit/default: set global default ice
# https://github.com/z-shell/z-a-default-ice
zi id-as for z-shell/z-a-default-ice
zi default-ice -q lucid light-mode

# zinit/eval: creates a cache containing the output of a command
# https://github.com/z-shell/z-a-eval
zi id-as for z-shell/z-a-eval

# zi/auto: load plugins with conventions
zi id-as for "${ZDOTDIR}/z-a-auto"

# ohmyzsh: community driven zsh framework
# https://github.com/ohmyzsh/ohmyzsh
COMPLETION_WAITING_DOTS="true"
zi for \
    OMZL::completion.zsh \
    OMZL::directories.zsh \
    OMZL::functions.zsh \
    OMZL::grep.zsh \
    OMZL::history.zsh \
    OMZL::key-bindings.zsh \
    OMZL::spectrum.zsh \
    OMZL::termsupport.zsh

alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."

# history configuration
# https://zsh.sourceforge.io/Doc/Release/Options.html#History
HISTSIZE=2000000000 SAVEHIST=1000000000
HISTFILE="${ZSH_DATA_DIR}/history"
link "${HISTFILE}" .zsh_history

# use approximate completion with error correction
# https://zsh.sourceforge.io/Doc/Release/Completion-System.html#Control-Functions
zstyle ':completion:*' completer _complete _correct _approximate
zstyle ':completion:*:match:*' original only
zstyle -e ':completion:*:approximate:*' max-errors 'reply=($((($#PREFIX+$#SUFFIX)/3>7?7:($#PREFIX+$#SUFFIX)/3))numeric)'

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

# brew: the missing package manager
# https://github.com/Homebrew/brew
:brew-init() {
    export HOMEBREW_BUNDLE_FILE="${XDG_CONFIG_HOME}/Brewfile"
    export HOMEBREW_BUNDLE_NO_LOCK=1
    export HOMEBREW_AUTO_UPDATE_SECS=86400
    export HOMEBREW_CLEANUP_MAX_AGE_DAYS=7
    export HOMEBREW_CLEANUP_PERIODIC_FULL_DAYS=1

    add path "${HOMEBREW_PREFIX}/opt/coreutils/libexec/gnubin"
    add path "${HOMEBREW_PREFIX}/opt/findutils/libexec/gnubin"
    add path "${HOMEBREW_PREFIX}/opt/gawk/libexec/gnubin"
    add path "${HOMEBREW_PREFIX}/opt/gnu-sed/libexec/gnubin"
    add path "${HOMEBREW_PREFIX}/opt/gnu-tar/libexec/gnubin"
    add path "${HOMEBREW_PREFIX}/opt/gnu-time/libexec/gnubin"
    add path "${HOMEBREW_PREFIX}/opt/grep/libexec/gnubin"
    add path "${HOMEBREW_PREFIX}/opt/make/libexec/gnubin"
    add fpath "${HOMEBREW_PREFIX}/share/zsh/site-functions"

    alias bbd="brew bundle dump -f"
    alias bz="brew uninstall --zap"
}

:brew-update() {
    brew update
    brew upgrade
    brew bundle install
    brew autoremove
    brew cleanup -s --prune=all
    chmod go-w "${HOMEBREW_PREFIX}/share"
}

.brew-install() {
    has brew || return 0
    brew install "$@"
}

zi auto has"brew" for brew

# asdf: multiple runtime version manager
# https://asdf-vm.com/
export ASDF_DIR="${XDG_CACHE_HOME}/asdf"
export ASDF_DATA_DIR="${ASDF_DIR}"
export ASDF_COMPLETIONS="${ASDF_DIR}/completions"

:asdf-update() {
    clone asdf-vm/asdf "${ASDF_DIR}"
    source "${ASDF_DIR}/asdf.sh"
    asdf update
    asdf plugin update --all
    link .tool-versions
}

.asdf-install() {
    asdf plugin add ${1}
    asdf install ${1} ${2:-latest}
}

zi auto silent for OMZP::asdf

# python: programming language
# https://docs.python.org/3/
export PYTHONSTARTUP="${XDG_CONFIG_HOME}/python/startup.py"
zi auto with"asdf" for OMZP::python

# python/pipx: install python applications in isolated environments
# https://pypa.github.io/pipx/
export PIPX_HOME="${XDG_CACHE_HOME}/pipx"
export PIPX_BIN_DIR="${PIPX_HOME}/bin"
export PIPX_DEFAULT_PYTHON=$(which python)

add path "${PIPX_BIN_DIR}"

:pipx-update() {
    .asdf-install pipx
    pipx reinstall-all
    pipx upgrade-all --include-injected
}

zi auto with"asdf" for pipx

# python/argcomplete: completion for python programs
# https://github.com/kislyuk/argcomplete#readme
:argcomplete-load() {
    local __argcomplete_path=(${PIPX_HOME}/venvs/argcomplete/lib/python*(n,On[1]))
    add fpath ${__argcomplete_path}/site-packages/argcomplete/bash_completion.d
}

:argcomplete-eval() {
    # we cannot register pipx completions before we install argcomplete but we
    # cannot install argcomplete until pipx is installed
    register-python-argcomplete pipx
}

zi auto with"pipx" for argcomplete

# python/poetry: python dependency management
# https://github.com/python-poetry/poetry
export POETRY_CONFIG_DIR="${XDG_CONFIG_HOME}/pypoetry"
export POETRY_CACHE_DIR="${XDG_CACHE_HOME}/poetry"
export POETRY_DATA_DIR="${XDG_DATA_HOME}/pypoetry"

:poetry-update() {
    poetry self update
    # https://github.com/MousaZeidBaker/poetry-plugin-up
    poetry self add poetry-plugin-up
}

zi auto with"pipx" for OMZP::poetry

# vscode
# https://code.visualstudio.com
# alias code="env -u XDG_RUNTIME_DIR code"
.code-extension() {
    has code || return 0
    code --force --install-extension "$@"
}

# 1password: remembers all your passwords for you
# https://1password.com
:1password-cli-load() {
    if has "${XDG_CONFIG_HOME}/op/plugins.sh"; then
        source "${XDG_CONFIG_HOME}/op/plugins.sh"

        # Enforce personal 1Password account for gh
        unalias gh; gh() {
            env OP_ACCOUNT=my.1password.com OP_SERVICE_ACCOUNT_TOKEN= \
                op plugin run -- gh "$@"
        }
    fi
}

:1password-cli-eval() {
    op completion zsh
}

zi auto with"asdf" wait for 1password-cli

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
    local pattern="platform_almalinux"
    if [[ $# -gt 1 ]]; then
        pattern="$1" && shift
    fi

    ansible "${pattern}" -b -m shell -a "$@"
}

ansible-each() {
    :each */ansible.mk(:h) do "$@"
}

ansible-parallel() {
    :parallel */ansible.mk(:h) do "$@"
}

# ansible/ara: ARA Records Ansible
export ARA_BASE_DIR="${XDG_DATA_HOME}/ara/server"
export ARA_DATABASE_NAME="${ARA_BASE_DIR}/ansible.sqlite"
export ARA_SETTINGS="${ARA_BASE_DIR}/settings.yaml"

# aws: Amazon Web Services CLI
# https://aws.amazon.com/cli/
export AWS_SHARED_CREDENTIALS_FILE="${XDG_CONFIG_HOME}/aws/credentials"
export AWS_CONFIG_FILE="${XDG_CONFIG_HOME}/aws/config"
zi auto wait for OMZP::aws

# bat: cat(1) clone with wings
# https://github.com/sharkdp/bat
:bat-load() {
    export BAT_CONFIG_PATH="${XDG_CONFIG_HOME}"/bat/config BAT_PAGER="less"
    export MANPAGER="sh -c 'col -bx | bat -l man'" MANROFFOPT="-c"
}

zi auto has"bat" wait for bat

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

# checkov: static code analysis tool for Terraform & Co
# https://github.com/bridgecrewio/checkov
:checkov-eval() {
    register-python-argcomplete checkov
}

zi auto with"pipx" wait for checkov

# colordiff: syntax highlighting for diff
# https://www.colordiff.org
cdl() { colordiff | less -R }

# consul: distributed, highly available service discovery
# https://github.com/hashicorp/consul
:consul-load() {
    zicompinit
    complete -o nospace -C consul consul
}

zi auto with"asdf" wait1 for consul

# copier: repository template framework
# https://copier.readthedocs.io/en/stable/
zi auto with"pipx" wait for copier

copier-each() {
    :each */.copier-answers.yml(:h) do "$@"
}

copier-parallel() {
    :parallel */.copier-answers.yml(:h) do "$@"
}

# dircolors: setup colors for ls and friends
# https://github.com/trapd00r/LS_COLORS
:dircolors-load() {
    zstyle ":completion:*:default" list-colors "${(s.:.)LS_COLORS}"
}

:dircolors-eval() {
    dircolors -b LS_COLORS
}

zi auto id-as"dircolors" wait for trapd00r/LS_COLORS

# direnv: change environment based on the current directory
# https://github.com/direnv/direnv
:direnv-load() {
    alias da="direnv allow"
}

:direnv-eval() {
    direnv hook zsh
}

zi auto with"asdf" for direnv/direnv

# docker/orbstack:
add path "${HOME}"/.orbstack/bin
zi auto id-as"docker" as"completion" blockf wait for \
    https://github.com/docker/cli/blob/master/contrib/completion/zsh/_docker

# duf: better `df` alternative
# https://github.com/muesli/duf
:duf-load() {
    alias df=duf
}

zi auto with"asdf" wait for duf

# eza: a modern replacement for ‘ls’.
# https://github.com/ogham/eza
:eza-load() {
    alias l="eza --all --long --group"
    alias lR="l -R"
}

zi auto has"eza" wait for eza

# fd:
zi auto with"asdf" id-as"fd" as"completion" blockf wait for \
    https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/fd/_fd

# fping: send ICMP echo probes to network hosts
# https://fping.org/
netping() {
    for i in "$@"; do
        fping -g "${i}" 2>/dev/null
    done
}

# fzf:
zi auto with"asdf" wait for fzf

# fzf/tab: replace completion selection menu with fzf
# https://github.com/Aloxaf/fzf-tab
zi auto wait for Aloxaf/fzf-tab

# preview directory content with eza when completing cd
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --all --long --group $realpath'

# gcloud: Google Cloud SDK
# https://cloud.google.com/sdk
:gcloud-update() {
    gcloud components update
}

:gcloud-load() {
    export CLOUDSDK_HOME=(${ASDF_DATA_DIR}/installs/gcloud/*(n,On[1]))
    export CLOUDSDK_CORE_DISABLE_USAGE_REPORTING=true
    source "${CLOUDSDK_HOME}/path.zsh.inc"
    source "${CLOUDSDK_HOME}/completion.zsh.inc"
}

zi auto with"asdf" wait1 for gcloud

# git: distributed version control system
# https://github.com/git/git
zi auto id-as"git" as"completion" blockf mv"git->_git" wait for \
    https://github.com/git/git/blob/master/contrib/completion/git-completion.zsh

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

git-each () {
    :each */.git(:h) do "$@"
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
    parallel \
        rm -rvf "${HOME}/src/{}"
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
    gh pr view --web
}

ghm() {
    gh pr merge --merge "$@" && \
    gcl
}

# gnupg: GNU privacy guard
# https://gnupg.org/
export GNUPGHOME="${XDG_DATA_HOME}/gnupg"
export GPG_TTY="${TTY}"

# go: programming language
# https://www.golang.org
export GOPATH="${XDG_CACHE_HOME}/go"
add path "${GOPATH}/bin"

go-each() {
    :each */go.mk(:h) do "$@"
}

go-parallel() {
    :parallel */go.mk(:h:a) do "$@"
}

zi auto with"asdf" for golang

# ip: helper to get public ip
# http://4.ifconfig.pro
IP() {
    curl -s http://4.ifconfig.pro/ip.host | awk '{print $1}'
}

# less: pager configuration
# https://man7.org/linux/man-pages/man1/less.1.html#OPTIONS
export PAGER="${commands[less]}" LESS="--ignore-case --LONG-PROMPT --RAW-CONTROL-CHARS --HILITE-UNREAD --chop-long-lines --tabs=4"
export LESSHISTFILE="${XDG_DATA_HOME}/less/history"
mkdir -p "$(dirname "${LESSHISTFILE}")"
sl() { sort -u | less }

# man: unix documentation system
# https://www.nongnu.org/man-db/
zi auto wait for OMZP::colored-man-pages

# mc: midnight commander
# https://midnight-commander.org
export MC_SKIN="${XDG_CONFIG_HOME}/mc/solarized-dark-truecolor.ini"
alias mc="mc --nosubshell"

# nomad: workload orchestrator
# https://github.com/hashicorp/nomad
:nomad-load() {
    zicompinit
    complete -o nospace -C nomad nomad
}

zi auto with"asdf" wait1 for nomad

# npm: node package manager
# https://github.com/npm/cli
export NPM_CONFIG_USERCONFIG="${XDG_CONFIG_HOME}/npm/npmrc"
add path "${XDG_DATA_HOME}"/npm/bin

# parallel: run commands in parallel
# https://www.gnu.org/software/parallel/
export PARALLEL_HOME="${XDG_CONFIG_HOME}/parallel"
mkdir -p ${PARALLEL_HOME}

# pwgen: generate random passwords
pw() { pwgen -s 32 1 | clipcopy }

# ripgrep: fast grep replacement
# https://github.com/BurntSushi/ripgrep
export RIPGREP_CONFIG_PATH="${XDG_CONFIG_HOME}"/ripgrep/config
rg() { command rg --color=always --sort path "$@" | less }

#:ripgrep-eval() {
#    rg --generate complete-zsh
#}

zi auto with"asdf" for ripgrep

# rsync: fast incremental file transfer
# https://rsync.samba.org
zi auto wait for OMZP::rsync

# ruby: programming language
# https://www.ruby-lang.org
export GEM_HOME="${XDG_CACHE_HOME}"/gem
export GEM_SPEC_CACHE="${XDG_CACHE_HOME}"/gem
export BUNDLE_USER_CONFIG="${XDG_CONFIG_HOME}"/bundle
export BUNDLE_USER_CACHE="${XDG_CACHE_HOME}"/bundle
export BUNDLE_USER_PLUGIN="${XDG_DATA_HOME}"/bundle

# sqlite: database engine
# https://sqlite.org
export SQLITE_HISTORY=${XDG_DATA_HOME}/sqlite/history

# ssh: secure shell
# https://www.openssh.com
alias ssu="sshlive -o RequestTTY=force -o RemoteCommand='sudo -i'"

mkdir -p "${HOME}/.ssh" "${XDG_CACHE_HOME}"/ssh
chmod 0700 "${HOME}/.ssh"

link ssh/config .ssh/config
chmod 0600 "${HOME}/.ssh/config"

# https://1password.community/discussion/comment/660153/#Comment_660153
if [[ -e "${HOME}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock" ]]; then
    export SSH_AUTH_SOCK="${HOME}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
else
    zi auto silent for OMZP::ssh-agent
fi

# terraform: manage cloud infrastructure
# https://github.com/hashicorp/terraform
export CHECKPOINT_DISABLE=true
export TF_PLUGIN_CACHE_DIR="${XDG_CACHE_HOME}/terraform/plugins"
mkdir -p "${TF_PLUGIN_CACHE_DIR}"
link terraform .terraform.d

alias tf="terraform"
alias tfa="tf apply"
alias tfd="tf destroy"
alias tfi="tf import"
alias tfp="tf plan"

terraform-each() {
    :each */terraform.mk(:h) do "$@"
}

terraform-parallel() {
    :parallel */terraform.mk(:h) do "$@"
}

# tmux: a terminal multiplexer
# https://github.com/tmux/tmux
:tmux-update() {
    clone tmux-plugins/tpm "${TMUX_PLUGIN_MANAGER_PATH}/tpm"
    ${TMUX_PLUGIN_MANAGER_PATH}/tpm/bin/install_plugins
}

:tmux-load() {
    export TMUX_PLUGIN_MANAGER_PATH="${XDG_CACHE_HOME}/tmux/plugins"
    export ZSH_TMUX_CONFIG="${XDG_CONFIG_HOME}/tmux/tmux.conf"
    export ZSH_TMUX_DEFAULT_SESSION_NAME="default"
    export ZSH_TMUX_FIXTERM="false"
    alias T=tmux
}

zi auto has"tmux" silent for OMZP::tmux

# tmux/xpanes:
# https://github.com/greymd/tmux-xpanes
# TODO: zi auto wait for greymd/tmux-xpanes

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

# misc other aliases
alias dev="ssh -t dev01.dev.rmge.net \"zsh -i -c T\""

# add local path last so it takes precendence
add path "${XDG_CONFIG_HOME}/bin"

# reminds you to use existing aliases for commands you just typed
# https://github.com/MichaelAquilina/zsh-you-should-use
zi auto wait for MichaelAquilina/zsh-you-should-use
YSU_MESSAGE_POSITION="after"

# load zsh history search and create bindings for it
# https://github.com/zsh-users/zsh-history-substring-search
zi auto wait for zsh-users/zsh-history-substring-search
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# zsh/p10k is a theme for Zsh
# https://github.com/romkatv/powerlevel10k
zi auto depth'1' atload'source "${ZDOTDIR}"/.p10k.zsh' \
    for romkatv/powerlevel10k

# zsh/f-sy-h: feature-rich syntax highlighting for ZSH
# https://github.com/z-shell/F-Sy-H
zi auto atinit"zicompinit; zicdreplay" \
    wait for z-shell/F-Sy-H

# zsh/autosuggestions: fish-like autosuggestions for zsh
# https://github.com/zsh-users/zsh-autosuggestions
zi auto atload"_zsh_autosuggest_start" \
    wait for zsh-users/zsh-autosuggestions

# zsh/autopair: automatically close quotes, brackets and other delimiters
# https://github.com/hlissner/zsh-autopair
zi auto wait for hlissner/zsh-autopair

# zsh/completions: initialize completion system
# https://github.com/zsh-users/zsh-completions
zi auto blockf wait for zsh-users/zsh-completions

# Load .envrc after shell initialization if present
if [[ -e .envrc ]]; then
    direnv reload
fi
