# force locale to english
export LANG="en_US.UTF-8"
export LC_CTYPE=${LANG}

# enforce truecolor support
export COLORTERM="truecolor"

# shell options
setopt extendedglob

# set resource limits
ulimit -n $((1024*1024))

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

# append ZDOTDIR so `git foo` and subprocess lookups can find user scripts,
# but `command foo` still resolves to system binaries first
path+=("${ZDOTDIR}")

# autoload all regular files in ZDOTDIR
autoload -Uz ${ZDOTDIR}/*(.N:t)

# add homebrew path as early as possible
if has /opt/homebrew/bin/brew; then
    eval "$(/opt/homebrew/bin/brew shellenv zsh)"
fi

# add local bin to path
add path "${HOME}/.local/bin"

# compiler flags
typeset -TUx LDFLAGS ldflags ":"
typeset -TUx CPPFLAGS cppflags ":"

# zi: Flexible and fast ZSH plugin manager
# https://github.com/z-shell/zi
typeset -Ag ZI
ZI[HOME_DIR]="${XDG_CACHE_HOME}/zi"
ZI[BIN_DIR]="${ZI[HOME_DIR]}/bin"
source "${ZDOTDIR}/zzinit" && zzinit

alias zre="exec zsh"
alias zx="sudo rm -rf ${XDG_CACHE_HOME} && zre"

zup() {
    local oldpwd="${PWD}"
    :brew-update && \
    :uv-update && \
    :tmux-update && \
    :gcloud-update && \
    zi self-update && \
    zi update --all
    cd "${oldpwd}"
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
zi for \
    OMZL::directories.zsh \
    OMZL::functions.zsh \
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
    if ! has brew; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        eval "$(/opt/homebrew/bin/brew shellenv)"
        :brew-init
    else
        brew bundle dump -f
    fi

    brew update
    brew upgrade
    brew bundle install
    brew autoremove
    brew cleanup -s --prune=all
    chmod go-w "${HOMEBREW_PREFIX}/share"
}

zi auto has"dscl" for brew

# mise: dev tools, env vars, task runner
# https://github.com/jdx/mise
export MISE_SOPS_AGE_KEY_FILE="${XDG_CONFIG_HOME}/sops/age/keys.txt"

:mise-load() {
    local _mise_cmd_not_found
    eval "$(mise activate zsh)"
}

zi auto has"mise" for jdx/mise

# python: programming language
# https://docs.python.org/3/
export PYTHONSTARTUP="${XDG_CONFIG_HOME}/python/startup.py"
export PIP_REQUIRE_VIRTUALENV="1"
export PIP_USER="0"
export PYTHONNOUSERSITE="1"

# expose brew's unversioned python/pip shims on PATH (macOS/brew only)
if has brew; then
    add path "${HOMEBREW_PREFIX}/opt/python/libexec/bin"
fi

alias python-each=':each */python.mk(:h) do'
alias python-parallel=':parallel */python.mk(:h) do'

# python/uv: an extremely fast Python package manager
# https://github.com/astral-sh/uv
export UV_TOOL_DIR="${XDG_CACHE_HOME}/uv/tools"
export UV_TOOL_BIN_DIR="${XDG_CACHE_HOME}/uv/bin"

add path "${UV_TOOL_BIN_DIR}"

:uv-update() {
    uv tool upgrade --all
}

:uv-eval() {
    uv generate-shell-completion zsh
}

zi auto has"uv" for uv

# python/argcomplete: tab completion for argparse-based programs, installed via uv
# https://github.com/kislyuk/argcomplete#readme

# argcomplete's completers set `IFS=$'\013'` and leave it set when calling
# `_describe`; that leaked IFS breaks fzf-tab's match capture (empty popup).
# :argcomplete-fix-ifs rewrites the generated code to reset IFS for the
# `_describe` call (the matches are already split by then), so completions
# render under both fzf-tab and the native menu.
:argcomplete-fix-ifs() {
    local code="$(cat)"
    print -r -- "${code//_describe /IFS=$' \t\n' _describe }"
}

:register-python-argcomplete() {
    register-python-argcomplete --shell zsh "$@" | :argcomplete-fix-ifs
}

:argcomplete-eval() {
    activate-global-python-argcomplete --dest=- | :argcomplete-fix-ifs
}

zi auto with"uv" for argcomplete

# 1password: remembers all your passwords for you
# https://1password.com
:1password-cli-eval() {
    chmod 0700 "${XDG_CONFIG_HOME}/op"
    op completion zsh
}

zi auto has"op" wait for 1password-cli

# android: development kit
# https://developer.android.com/studio/command-line/variables
export ANDROID_EMULATOR_HOME="${XDG_CONFIG_HOME}/android"

# ansible: simple IT automation
# https://github.com/ansible/ansible
export ANSIBLE_GALAXY_CACHE_DIR="${XDG_CACHE_HOME}/ansible"
export ANSIBLE_GALAXY_TOKEN_PATH="${XDG_DATA_HOME}/ansible/galaxy_token"
export ANSIBLE_LOCAL_TEMP="${XDG_RUNTIME_DIR}/ansible/tmp"
export ANSIBLE_PERSISTENT_CONTROL_PATH_DIR="${XDG_RUNTIME_DIR}/ansible/cp"

alias ansible-each=':each */ansible.mk(:h) do'
alias ansible-parallel=':parallel */ansible.mk(:h) do'

alias ad="ansible-doc"
alias ai="ansible-inventory"
alias ap="ansible-playbook"

# ansible/ara: ARA Records Ansible
# https://github.com/ansible-community/ara
export ARA_BASE_DIR="${XDG_DATA_HOME}/ara/server"
export ARA_DATABASE_NAME="${ARA_BASE_DIR}/ansible.sqlite"
export ARA_SETTINGS="${ARA_BASE_DIR}/settings.yaml"

# atuin: magical shell history with optional sync
# https://github.com/atuinsh/atuin
:atuin-load() {
    alias a="atuin"
}

:atuin-eval() {
    atuin init zsh --disable-up-arrow
}

zi auto has"atuin" wait for atuin

# aws: Amazon Web Services CLI
# https://aws.amazon.com/cli/
export SHOW_AWS_PROMPT=false
zi auto has"aws" wait for OMZP::aws

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

# checkov: static code analysis tool for Terraform & Co
# https://github.com/bridgecrewio/checkov
:checkov-eval() {
    :register-python-argcomplete checkov
}

zi auto has"checkov" wait for checkov

# claude: AI assistant by Anthropic
# https://claude.ai
export CLAUDE_CODE_NEW_INIT=1
export ENABLE_CLAUDEAI_MCP_SERVERS=true
cp "${HOME}/Library/Application Support/Claude/claude_desktop_config.json" \
    "${HOME}/.claude/claude_desktop_config.json"

# consul: distributed, highly available service discovery
# https://github.com/hashicorp/consul
:consul-load() {
    complete -o nospace -C consul consul
}

zi auto has"consul" wait1 for consul

# copier: repository template framework
# https://copier.readthedocs.io/en/stable/
zi auto has"copier" wait for copier

alias copier-each=':each */.copier-answers.yml(:h) do'
alias copier-parallel=':parallel */.copier-answers.yml(:h) do'

# dircolors: setup colors for ls and friends
# https://github.com/trapd00r/LS_COLORS
:dircolors-load() {
    # colorize completion candidates (filenames, dirs, …) in every context, not
    # just the `default` tag — fzf-tab reads list-colors to color its menu. Set
    # here rather than in the completion block because LS_COLORS is populated by
    # :dircolors-eval, which runs when this plugin loads.
    zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
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

zi auto has"direnv" for direnv/direnv

# docker: develop, ship, and run containers
# https://www.docker.com
add fpath "${HOME}/.docker/completions"

# duf: better `df` alternative
# https://github.com/muesli/duf
:duf-load() {
    alias df=duf
}

zi auto has"duf" wait for duf

# eza: a modern replacement for ‘ls’.
# https://github.com/ogham/eza
:eza-load() {
    export EZA_ICONS_AUTO=1
    alias l="eza --all --long --group"
    alias lR="l -R"
}

zi auto has"eza" wait for eza

# fzf: command-line fuzzy finder
# https://github.com/junegunn/fzf
# https://github.com/catppuccin/fzf/blob/main/themes/catppuccin-fzf-mocha.sh
export FZF_DEFAULT_OPTS=" \
    --color=bg+:#313244,bg:#1E1E2E,spinner:#F5E0DC,hl:#F38BA8 \
    --color=fg:#CDD6F4,header:#F38BA8,info:#CBA6F7,pointer:#F5E0DC \
    --color=marker:#B4BEFE,fg+:#CDD6F4,prompt:#CBA6F7,hl+:#F38BA8 \
    --color=selected-bg:#45475A \
    --color=border:#6C7086,label:#CDD6F4"

zi auto has"fzf" wait for fzf

# gcloud: Google Cloud SDK
# https://cloud.google.com/sdk
:gcloud-update() {
    gcloud components update || :
}

:gcloud-load() {
    if has brew; then
        export CLOUDSDK_HOME="/opt/homebrew/share/google-cloud-sdk"
    else
        export CLOUDSDK_HOME="/usr/lib64/google-cloud-sdk"
    fi

    if has "${CLOUDSDK_HOME}"; then
        add path "${CLOUDSDK_HOME}/bin"
        source "${CLOUDSDK_HOME}/completion.zsh.inc"
        export CLOUDSDK_CORE_DISABLE_USAGE_REPORTING=true
    fi
}

zi auto has"gcloud" wait1 for gcloud

# ghostty: fast, native, GPU-accelerated terminal emulator
# https://ghostty.org
add path "${GHOSTTY_BIN_DIR}"

# git: distributed version control system
# https://github.com/git/git
zi auto id-as"git" as"completion" blockf mv"git->_git" wait for \
    https://github.com/git/git/blob/master/contrib/completion/git-completion.zsh

alias git-each=':each */.git(:h) do'
alias git-parallel=':parallel */.git(:h) do'

alias ga="git add --all"
alias gap="git add --patch"
alias gcl="git checkout-latest main"
alias gcm="git co \$(git main-branch)"
alias gcu="git co upstream"
alias gd="git diff"
alias gdc="git diff --cached"
alias gdm="git diff origin/\$(git main-branch)"
alias gdu="git diff upstream/\$(git main-branch)"
alias gf="git fetch --prune"
alias gl="git lg"
alias gp="git pull"
alias gpr="git pull --rebase --autostash"
alias grh="git reset HEAD"
alias gsp="git show -p"
alias s="git st ."

# glamour/glow: terminal markdown rendering
# https://github.com/charmbracelet/glow
export GLAMOUR_STYLE="${HOME}/.config/glow/styles/catppuccin-mocha.json"
export GLOW_STYLE="${GLAMOUR_STYLE}"

# gnupg: GNU privacy guard
# https://gnupg.org/
export GPG_TTY="${TTY}"
export GNUPGHOME="${XDG_DATA_HOME}/gnupg"
mkdir -p "${GNUPGHOME}"
chmod 0700 "${GNUPGHOME}"
zi auto wait for OMZP::gpg-agent

# go: programming language
# https://www.golang.org
export GOPATH="${XDG_CACHE_HOME}/go"
add path "${GOPATH}/bin"
zi auto has"go" for golang
alias go-each=':each */go.mk(:h) do'
alias go-parallel=':parallel */go.mk(:h:a) do'

# less: pager configuration
# https://man7.org/linux/man-pages/man1/less.1.html#OPTIONS
export PAGER="${commands[less]}" LESS="--ignore-case --LONG-PROMPT --RAW-CONTROL-CHARS --HILITE-UNREAD --chop-long-lines --tabs=4"
export LESSHISTFILE="${XDG_DATA_HOME}/less/history"
mkdir -p "$(dirname "${LESSHISTFILE}")"

# man: unix documentation system
# https://www.nongnu.org/man-db/
zi auto wait for OMZP::colored-man-pages

# ncdu: disk usage analyzer
# https://dev.yorhel.nl/ncdu
link ncduignore .ncduignore

# node: JavaScript runtime
# https://nodejs.org
alias node-each=':each */nodejs.mk(:h) do'
alias node-parallel=':parallel */nodejs.mk(:h) do'

# nomad: workload orchestrator
# https://github.com/hashicorp/nomad
:nomad-load() {
    complete -o nospace -C nomad nomad
}

zi auto has"nomad" wait1 for nomad

# npm: node package manager
# https://github.com/npm/cli
export NPM_CONFIG_USERCONFIG="${XDG_CONFIG_HOME}/npm/npmrc"
add path "${XDG_DATA_HOME}"/npm/bin

# opentofu: open-source terraform fork, installed via mise
# https://github.com/opentofu/opentofu
export TF_PLUGIN_CACHE_DIR="${XDG_CACHE_HOME}/opentofu/plugins"
mkdir -p "${TF_PLUGIN_CACHE_DIR}"

alias tf="tofu"
alias tf-each=':each */terraform.mk(:h) do'
alias tf-parallel=':parallel */terraform.mk(:h) do'

:opentofu-load() {
    complete -o nospace -C tofu tofu
}

zi auto with"mise" wait1 for opentofu

# parallel: run commands in parallel
# https://www.gnu.org/software/parallel/
export PARALLEL_HOME="${XDG_CONFIG_HOME}/parallel"
mkdir -p ${PARALLEL_HOME}

# postgresql: object-relational database
# https://www.postgresql.org
:postgresql-load() {
    local __postgresql_brew_dir=("${HOMEBREW_PREFIX}"/opt/postgresql@*(N,n,On[1]))
    if [[ -n "${__postgresql_brew_dir}" ]]; then
        add path "${__postgresql_brew_dir}/bin"
        add ldflags "-L${__postgresql_brew_dir}/lib"
        add cppflags "-I${__postgresql_brew_dir}/include"
    fi
}

zi auto has"psql" for postgresql

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

:ruby-load() {
    local __ruby_brew_dir=("${HOMEBREW_PREFIX}"/opt/ruby@*(N,n,On[1]))
    if [[ -n "${__ruby_brew_dir}" ]]; then
        export RUBYHOME="${__ruby_brew_dir}"
        add path "${RUBYHOME}/bin"
    fi
}

zi auto has"ruby" for ruby

# sops: editor of encrypted files (age, gpg, cloud KMS)
# https://github.com/getsops/sops
export SOPS_AGE_KEY_FILE="${XDG_CONFIG_HOME}/sops/age/keys.txt"

# sqlite: database engine
# https://sqlite.org
export SQLITE_HISTORY=${XDG_DATA_HOME}/sqlite/history

# ssh: secure shell
# https://www.openssh.com

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

# sshp: Parallel SSH Executor
# https://github.com/bahamas10/sshp
zi make as"program" for bahamas10/sshp

# tmux: a terminal multiplexer
# https://github.com/tmux/tmux
:tmux-load() {
    export TMUX_PLUGIN_MANAGER_PATH="${XDG_CACHE_HOME}/tmux/plugins"
    export ZSH_TMUX_CONFIG="${XDG_CONFIG_HOME}/tmux/tmux.conf"
    export ZSH_TMUX_DEFAULT_SESSION_NAME="default"
    export ZSH_TMUX_FIXTERM="false"
    alias T=tmux
}

:tmux-update() {
    :tmux-load
    clone tmux-plugins/tpm "${TMUX_PLUGIN_MANAGER_PATH}/tpm"
    ${TMUX_PLUGIN_MANAGER_PATH}/tpm/bin/install_plugins
}

zi auto has"tmux" silent for OMZP::tmux

# tmux/xpanes: run commands across synchronized tmux panes
# https://github.com/greymd/tmux-xpanes
zi auto has"tmux" wait for greymd/tmux-xpanes

# vim: vi improved, via neovim
# https://neovim.io
zi auto has"nvim" for neovim
alias vim=nvim
export VIMINIT="set nocp | source ${XDG_CONFIG_HOME}/vim/vimrc"
export EDITOR="${commands[nvim]}"

# vscode: visual studio code editor
# https://code.visualstudio.com
:vscode-load() {
    if ! has "${HOME}/Library/Application Support/Code/User"; then
        return
    fi

    for i in settings keybindings mcp; do
        link "vscode/${i}.json" "Library/Application Support/Code/User/${i}.json"
    done
}

zi auto has"code" wait for vscode

# wget: retrieve files using HTTP, HTTPS, FTP and FTPS
# https://www.gnu.org/software/wget/
export WGETRC="${XDG_CONFIG_HOME}/wgetrc"
alias wget="wget --hsts-file=\"${XDG_CACHE_HOME}/wget-hsts\""

# youtube: download audio
# https://github.com/yt-dlp/yt-dlp
alias yta="yt-dlp --extract-audio --audio-format mp3 --add-metadata"

# misc other aliases
alias X="TERM=xterm-256color ssh -t 10.0.0.11 \"/usr/local/bin/zsh -i -c T\""

# zsh-you-should-use: reminds you to use existing aliases for commands you just typed
# https://github.com/MichaelAquilina/zsh-you-should-use
if has tput; then
    zi auto wait for MichaelAquilina/zsh-you-should-use
    YSU_MESSAGE_POSITION="after"
fi

# starship: minimal, blazing-fast, customizable prompt
# https://starship.rs
if has starship; then
    eval "$(starship init zsh)"
    # `starship init zsh` sets both PROMPT and RPROMPT, so the starship binary
    # is spawned twice per prompt redraw (~40ms each). The right prompt is
    # empty by default — drop RPROMPT to halve command_lag.
    unset RPROMPT
fi

# zsh-completions: extra completion functions. Loads before compinit so they
# land in fpath, then its atload runs compinit once — replaying the compdefs
# queued by every completion plugin above — before fzf-tab and the widget
# wrappers below.
# https://github.com/zsh-users/zsh-completions
zi auto blockf atpull'zinit creinstall -q zsh-users/zsh-completions' \
    atload"zicompinit; zicdreplay" wait for zsh-users/zsh-completions

# fzf-tab: replace the completion menu with fzf. Must load after compinit (above)
# and before the widget-wrapping plugins (autosuggestions, F-Sy-H) below.
# https://github.com/Aloxaf/fzf-tab
zi auto has"fzf" wait for Aloxaf/fzf-tab

# preview directory content with eza when completing cd. =always forces color and
# icons even though the preview is piped (eza auto-disables both off a TTY); icons
# need a Nerd Font, which the terminal already uses.
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --all --long --group --color=always --icons=always $realpath'

# zsh/completion
zmodload -i zsh/complist            # list-colors support + native menu
unsetopt flowcontrol                # reclaim ^S/^Q from terminal flow control
setopt complete_in_word             # allow completing with the cursor mid-word
setopt always_to_end                # ...and jump the cursor to the word end afterwards

# fzf-tab's recommended `menu no`, and intentionally NO menu_complete: zsh inserts
# the longest common prefix on the first TAB (the auto-insert we want) and fzf-tab's
# menu opens once there's nothing more to insert. With case-sensitive matching
# (below) a prefix like `CL` resolves to one match and just completes, so the old
# `CL`→`CLaude` two-tab annoyance is gone. (`setopt menu_complete` would force the
# menu onto the first TAB everywhere but never auto-insert a common prefix.)
zstyle ':completion:*' menu no

# case-sensitive matching, keeping partial-word (r:) and substring (l:/r:) matchers.
# Dropping the leading `m:{...}={...}` case-fold makes e.g. `CL` match only
# CLAUDE.md (not claude_desktop_config.json), so it completes directly — the
# ambiguity behind the old `CL`→`CLaude` two-tab problem can't arise.
zstyle ':completion:*' matcher-list 'r:|=*' 'l:|=* r:|=*'

# completer chain: exact, then spelling correction, then fuzzy/approximate with an
# error budget that scales with word length. fzf filters the candidate list itself,
# but _correct/_approximate also repair typos in the typed prefix, which fzf can't.
# https://zsh.sourceforge.io/Doc/Release/Completion-System.html#Control-Functions
zstyle ':completion:*' completer _complete _correct _approximate
zstyle -e ':completion:*:approximate:*' max-errors 'reply=($((($#PREFIX+$#SUFFIX)/3>7?7:($#PREFIX+$#SUFFIX)/3))numeric)'

# candidates
zstyle ':completion:*' special-dirs true        # offer the `.` and `..` directories
zstyle ':completion:*' use-cache yes            # cache results for completers that support it
zstyle ':completion:*' cache-path "${ZSH_CACHE_DIR}"

# `cd`: real subdirs, then the dir stack, then $cdpath — and never guess named dirs
zstyle ':completion:*:cd:*' tag-order local-directories directory-stack path-directories

# process lists (kill, etc.) via macOS ps, with the PID/owner colorized
zstyle ':completion:*:*:*:*:processes' command 'ps -u $USERNAME -o pid,user,comm -w -w'
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'

# hide macOS service accounts (_spotlight, _mdnsresponder, …) from `users`
# completion, but still show one if it is the only match
zstyle ':completion:*:*:*:*:users' ignored-patterns '_*'
zstyle '*' single-ignored show

# don't complete zsh's own completion/widget functions as function names
zstyle ':completion:*:functions' ignored-patterns '_*'

# git: never offer ORIG_HEAD as a ref, and keep checkout's native branch order
# https://stackoverflow.com/questions/12508595/ignore-orig-head-in-zsh-git-autocomplete#comment99936479_14325591
zstyle ':completion:*:*:git*:*' ignored-patterns '*ORIG_HEAD'
zstyle ':completion:*:git-checkout:*' sort false

# make: invoke the makefile so macro-defined targets are completed too
# https://unix.stackexchange.com/questions/657256/autocompletion-of-makefile-with-makro-in-zsh-not-correct-works-in-bash
zstyle ':completion::complete:make:*:targets' call-command true

# group matches by type; fzf-tab reads this format for its group headers (no color
# escapes here — fzf-tab strips them). The rest style zsh's status lines.
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*:messages' format '%d'
zstyle ':completion:*:warnings' format 'No matches for: %d'
zstyle ':completion:*:corrections' format '%d (errors: %e)'

# bash-style `complete -C` programmable completion (consul, nomad, tofu use it)
autoload -U +X bashcompinit && bashcompinit

# zsh/f-sy-h: feature-rich syntax highlighting for ZSH (loads last, after fzf-tab)
# https://github.com/z-shell/F-Sy-H
zi auto wait for z-shell/F-Sy-H

# zsh/autosuggestions: fish-like autosuggestions for zsh
# https://github.com/zsh-users/zsh-autosuggestions
zi auto atload"_zsh_autosuggest_start" \
    wait for zsh-users/zsh-autosuggestions

# zsh/autopair: automatically close quotes, brackets and other delimiters
# https://github.com/hlissner/zsh-autopair
zi auto wait for hlissner/zsh-autopair

# zsh-bench: benchmark zsh startup and interactive lag
# https://github.com/romkatv/zsh-bench
zi as"program" wait for romkatv/zsh-bench

# Load .envrc after shell initialization if present
if [[ -e .envrc ]]; then
    pushd "${HOME}" &>/dev/null && popd
fi
