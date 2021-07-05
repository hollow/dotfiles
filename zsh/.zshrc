# User information (for git, gpg, etc)
export USER_NAME="Benedikt Böhm"
export USER_EMAIL="bb@xnull.de"

# Force locale to english
export LANG="en_US.UTF-8"
export LC_CTYPE=$LANG

# User paths
export ZDOTDIR=${${(%):-%x}:A:h}
export XDG_CONFIG_HOME=${ZDOTDIR:h}
export XDG_CACHE_HOME="${HOME}/.cache"
export XDG_DATA_HOME="${HOME}/.local/share"

# System paths
typeset -TUx PATH path=("${XDG_CONFIG_HOME}/bin" /{usr/,}{local/,}{s,}bin)
typeset -TUx MANPATH manpath=(${(s[:])$(manpath)})
typeset -TUx FPATH fpath=(${ZDOTDIR} ${fpath[@]})

# Error handling
autoload -Uz add-zsh-hook die
add-zsh-hook precmd die

# Load custom functions
autoload -Uz path-{add,mkdirname}

# History configuration
# https://zsh.sourceforge.io/Doc/Release/Options.html#History
setopt extended_history       # record timestamp of command in HISTFILE
setopt hist_expire_dups_first # delete duplicates first when HISTFILE size exceeds HISTSIZE
setopt hist_ignore_all_dups   # ignore duplicated commands history list
setopt hist_ignore_space      # ignore commands that start with space
setopt hist_reduce_blanks     # remove superfluous blanks from each command line
setopt hist_verify            # show command with history expansion to user before running it
setopt inc_append_history     # immediately append to history file
unsetopt share_history        # do not share command history data

HISTSIZE=1000000000 SAVEHIST=1000000000
HISTFILE=$(path-mkdirname "${XDG_DATA_HOME}/zsh/history")

# Completion configuration
# https://zsh.sourceforge.io/Doc/Release/Completion-System.html#Completion-System-Configuration
zstyle ':completion:*' use-cache yes
zstyle ':completion:*' cache-path $(path-mkdirname "${XDG_CACHE_HOME}/zsh")

# Use approximate completion with error correction
zstyle ':completion:*' completer _complete _correct _approximate

# Case insensitive, partial-word and substring completion
zstyle ':completion:*' matcher-list 'r:|=*' 'l:|=* r:|=*'

# Complete . and .. special directories
zstyle ':completion:*' special-dirs true

# Improve completion output format
zstyle ':completion:*' verbose yes
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%d'
zstyle ':completion:*:messages' format '%d'
zstyle ':completion:*:warnings' format 'No matches for: %d'
zstyle ':completion:*:corrections' format '%d (errors: %e)'

# kill/ps completion
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'
zstyle ':completion:*:*:*:*:processes' command "ps -u ${USERNAME} -o pid,user,comm -w -w"

# Pager configuration
# https://man7.org/linux/man-pages/man1/less.1.html#OPTIONS
export PAGER="less"
export LESS="-iMRSW -x4"
export LESSHISTFILE=$(path-mkdirname "${XDG_DATA_HOME}/less/history")
sl() { sort -u | less }

# Editor configuration
export EDITOR="${commands[code]:-${commands[vim]}}"

# SSH configuration
ln -nfs "${XDG_CONFIG_HOME}/ssh" "${HOME}/.ssh"
ssu() { ssh -t "$1" sudo -Hi }

# Key bindings
bindkey -e
bindkey -M emacs "${terminfo[khome]}" beginning-of-line
bindkey -M emacs "${terminfo[kend]}"  end-of-line

# Words are complete shell command arguments
autoload -Uz select-word-style
select-word-style shell

# zinit: zsh plugin manager
# https://github.com/zdharma/zinit
autoload -Uz zinit
alias zre="exec zsh"
alias zx="rm -rf ${XDG_CACHE_HOME} && zre"

# https://github.com/romkatv/powerlevel10k
zinit wait'!' nocd depth'1' \
    atload'source "${ZDOTDIR}/.p10k.zsh"' \
    atload'_p9k_precmd' \
    for romkatv/powerlevel10k

# https://github.com/zdharma/fast-syntax-highlighting
zinit wait \
    atinit'zicompinit && zicdreplay' \
    for zdharma/fast-syntax-highlighting

# https://github.com/hlissner/zsh-autopair
zinit wait \
    for hlissner/zsh-autopair

# https://github.com/knu/zsh-manydots-magic
zinit wait \
    pick'manydots-magic' \
    for knu/zsh-manydots-magic

# https://github.com/zsh-users/zsh-completions
zinit wait blockf \
    atpull'zinit creinstall -q .' \
    for zsh-users/zsh-completions

# homebrew: the missing package manager for macOS
# https://github.com/Homebrew/brew
export HOMEBREW_PREFIX=${HOMEBREW_PREFIX:-"/opt/homebrew"}
export HOMEBREW_BUNDLE_FILE="${XDG_CONFIG_HOME}/Brewfile"
export HOMEBREW_BUNDLE_NO_LOCK=1
export HOMEBREW_AUTO_UPDATE_SECS=86400
export HOMEBREW_CLEANUP_MAX_AGE_DAYS=7
export HOMEBREW_CLEANUP_PERIODIC_FULL_DAYS=1
export HOMEBREW_UPDATE_REPORT_ONLY_INSTALLED=1

zinit if'@is-macos' run-atpull \
    autoload'brew' \
    atpull'brew update' \
    atpull'brew upgrade' \
    atpull'brew autoremove' \
    atpull'brew cleanup -s' \
    atload'alias bbd="brew bundle dump -f"' \
    atload'alias bz="brew uninstall --zap"' \
    id-as'brew' as'null' \
    for Homebrew/install


zinit if'@is-macos' \
    atclone'brew upstall ${ICE[id-as]}' \
    atpull'%atclone' run-atpull \
    atload'brew add-path ${ICE[id-as]}' \
    for \
    coreutils \
    findutils \
    gnu-sed \
    gnu-tar \
    gnu-time \
    gnupg \
    less \
    parallel \
    tree \
    watch

# asdf: extendable version manager
# https://github.com/asdf-vm/asdf
export ASDF_DEFAULT_TOOL_VERSIONS_FILENAME="${XDG_CONFIG_HOME}/.tool-versions"
export ASDF_DATA_DIR="${XDG_CACHE_HOME}/asdf"
export ASDF_USER_SHIMS="${ASDF_DATA_DIR}/shims"
export ASDF_DIR="${ZINIT[PLUGINS_DIR]}/asdf"
export ASDF_BIN="${ASDF_DIR}/bin"
export ASDF_HASHICORP_OVERWRITE_ARCH="amd64"

autoload -Uz asdf

zinit as'null' \
    for @asdf-vm/asdf

# bat: cat(1) clone with wings
# https://github.com/sharkdp/bat
export BAT_CONFIG_PATH="${XDG_CONFIG_HOME}"/bat/config BAT_PAGER="less"
export MANPAGER="sh -c 'col -bx | bat -l man -p'" MANROFFOPT="-c"

zinit wait from'gh-r' lbin \
    mv'**/bat.zsh _bat' \
    for @sharkdp/bat

# bottom: cross-platform graphical process/system monitor
# https://github.com/ClementTsang/bottom
zinit wait from'gh-r' lbin \
    for ClementTsang/bottom

# clipcopy: cross platform clipboard alias
# https://github.com/ohmyzsh/ohmyzsh/blob/master/lib/clipboard.zsh
zinit wait \
    for OMZL::clipboard.zsh

# dircolors: proper colors for `ls` and co
# https://github.com/trapd00r/LS_COLORS
zinit wait \
    atclone'dircolors -b LS_COLORS > dircolors.zsh' \
    pick'dircolors.zsh' nocompile'!' \
    atload'zstyle ":completion:*" list-colors "${(s.:.)LS_COLORS}"' \
    id-as'dircolors' \
    for trapd00r/LS_COLORS

# direnv: change environment based on the current directory
# https://github.com/direnv/direnv
zinit wait \
    atclone'asdf install-fast ${ICE[id-as]} current' \
    atpull'asdf install-fast ${ICE[id-as]} latest' run-atpull \
    atload'asdf add-path ${ICE[id-as]}' \
    atload'eval "$(asdf exec ${ICE[id-as]} hook zsh)"' \
    atload'alias da="direnv allow"' \
    for direnv

# dnscontrol: synchronize DNS
# https://github.com/StackExchange/dnscontrol
zinit wait from'gh-r' bpick"*Darwin*" \
    lbin'dnscontrol-* -> dnscontrol'\
    for StackExchange/dnscontrol

# dog: command-line DNS client
# https://github.com/ogham/dog
zinit wait from'gh-r' lbin \
    mv'**/dog.zsh _dog' \
    for ogham/dog

# duf: better `df` alternative
# https://github.com/muesli/duf
zinit wait from'gh-r' lbin \
    atload'alias df=duf' \
    for @muesli/duf

# exa: modern replacement for `ls`
# https://github.com/ogham/exa
zinit wait from'gh-r' lbin \
    mv'**/exa.zsh _exa' \
    atload'alias ls="exa -ghH"' \
    atload'alias l="ls --all --long"' \
    for ogham/exa

# fd: simple, fast and user-friendly alternative to `find`
# https://github.com/sharkdp/fd
zinit wait from'gh-r' lbin \
    mv'**/fd.1 ${ZPFX}/man/man1/fd.1' \
    for @sharkdp/fd

# fzf: command-line fuzzy finder
# https://github.com/junegunn/fzf
zinit wait \
    atclone'asdf install-fast ${ICE[id-as]} current' \
    atpull'asdf install-fast ${ICE[id-as]} latest' run-atpull \
    atload'asdf add-path ${ICE[id-as]}' \
    cp'$(asdf where fzf)/shell/completion.zsh -> _fzf_completion' \
    cp'$(asdf where fzf)/shell/key-bindings.zsh -> key-bindings.zsh' \
    cp'$(asdf where fzf)/man/man1/fzf-tmux.1 -> ${ZPFX}/man/man1/fzf-tmux.1' \
    cp'$(asdf where fzf)/man/man1/fzf.1 -> ${ZPFX}/man/man1/fzf.1' \
    for fzf

typeset -TUx FZF_DEFAULT_OPTS fzf_default_opts ' '
fzf_default_opts=(
    "--ansi"
    "--cycle"
    "--preview-window='right:60%'"
    "--bind='?:toggle-preview'"
    "--prompt='❯ '"
    "--color='bg+:#073642,bg:#002b36,spinner:#719e07,hl:#586e75'"
    "--color='fg:#839496,header:#586e75,info:#cb4b16,pointer:#719e07'"
    "--color='marker:#719e07,fg+:#839496,prompt:#719e07,hl+:#719e07'"
)

# fzf-tab: tab completion on steriods
# https://github.com/Aloxaf/fzf-tab
zinit wait \
    for Aloxaf/fzf-tab

zstyle ':fzf-tab:*' switch-group ',' '.'
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'exa -ghH -al $realpath'

# gh: GitHubs official command line tool
# https://github.com/cli/cli
zinit wait from'gh-r' lbin \
    id-as'gh' \
    for cli/cli

# git: distributed version control system
# https://github.com/git/git
export GIT_AUTHOR_NAME="${USER_NAME}"
export GIT_AUTHOR_EMAIL="${USER_EMAIL}"
export GIT_COMMITTER_NAME="${GIT_AUTHOR_NAME}"
export GIT_COMMITTER_EMAIL="${GIT_AUTHOR_EMAIL}"

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

# glow: render markdown on the cli
# https://github.com/charmbracelet/glow
zinit wait from'gh-r' lbin \
    for charmbracelet/glow

# gnupg: GNU privacy guard
# https://gnupg.org/
export GNUPGHOME="${XDG_CONFIG_HOME}"/gnupg

# grex: generate regular expressions from user-provided test cases
# https://github.com/pemistahl/grex
zinit wait from'gh-r' lbin \
    for pemistahl/grex

# hexyl: command-line hex viewer
# https://github.com/sharkdp/hexyl
zinit wait from'gh-r' lbin \
    for @sharkdp/hexyl

# hub: git with GitHub extensions
# https://github.com/github/hub
zinit wait \
    atclone'asdf install-fast ${ICE[id-as]} current' \
    atpull'asdf install-fast ${ICE[id-as]} latest' run-atpull \
    atload'asdf add-path ${ICE[id-as]}' \
    for hub

# insect: high precision scientific calculator
# https://github.com/sharkdp/insect
zinit wait from'gh-r' lbin'insect-* -> insect' \
    for @sharkdp/insect

# just: a command runner
# https://github.com/casey/just
zinit wait from'gh-r' lbin \
    atclone'./just --completions zsh > _just' \
    atclone'cp -v **/just.1 ${ZPFX}/man/man1/just.1' \
    atpull'%atclone' run-atpull \
    for casey/just

# keychain: SSH/GPG agent manager
# https://github.com/funtoo/keychain
zinit wait as'null' lbin \
    atload'source ${ZDOTDIR}/.keychain.zsh' \
    for funtoo/keychain

# mcrcon: Rcon client for Minecraft
# https://github.com/Tiiffi/mcrcon
zinit wait make lbin \
    for Tiiffi/mcrcon

# pastel: generate, analyze, convert and manipulate colors
# https://github.com/sharkdp/pastel
zinit wait from'gh-r' lbin \
    for @sharkdp/pastel

# python: programming language
# https://docs.python.org/3/
export PYTHONSTARTUP="${XDG_CONFIG_HOME}/python/startup.py"

# TODO: use asdf when python plugin support arm64
zinit if'@is-macos' \
    atclone'brew upstall ${ICE[id-as]}' \
    atpull'%atclone' run-atpull \
    for python@3.9

# poetry: python dependency management
# https://github.com/python-poetry/poetry
export POETRY_CACHE_DIR="${XDG_CACHE_HOME}/poetry"

zinit wait \
    atclone'asdf install-fast ${ICE[id-as]} current' \
    atclone'asdf exec poetry completions zsh > _poetry' \
    atpull'asdf install-fast ${ICE[id-as]} latest' run-atpull \
    atpull'asdf exec poetry completions zsh > _poetry' \
    atload'asdf add-path ${ICE[id-as]}' \
    atload'alias pa="poetry add"' \
    atload'alias pi="poetry install"' \
    for poetry

# procs: A modern replacement for ps
# https://github.com/dalance/procs
zinit wait from'gh-r' lbin \
    for dalance/procs

# pw: a simple pwgen replacement
# https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/plugins/genpass/genpass-monkey
autoload -Uz @genpass && pw() {
    @genpass && tee >(clipcopy) <<< "${REPLY}"
}

# ripgrep: fast grep replacement
# https://github.com/BurntSushi/ripgrep
export RIPGREP_CONFIG_PATH="${XDG_CONFIG_HOME}"/ripgrep/config
zinit wait from'gh-r' lbin'**/rg' \
    for BurntSushi/ripgrep

# ruby: programming language
# https://www.ruby-lang.org
export GEM_HOME="${XDG_DATA_HOME}"/gem
export GEM_SPEC_CACHE="${XDG_CACHE_HOME}"/gem
export BUNDLE_USER_CONFIG="${XDG_CONFIG_HOME}"/bundle
export BUNDLE_USER_CACHE="${XDG_CACHE_HOME}"/bundle
export BUNDLE_USER_PLUGIN="${XDG_DATA_HOME}"/bundle

zinit wait \
    atclone'asdf install-fast ${ICE[id-as]} current' \
    atpull'asdf install-fast ${ICE[id-as]} latest' run-atpull \
    atload'asdf add-path ${ICE[id-as]}' \
    for ruby

# sd: intuitive find & replace
# https://github.com/chmln/sd
zinit wait from'gh-r' lbin'sd-* -> sd' \
    for chmln/sd

# xh: friendly and fast tool for sending HTTP requests
# https://github.com/ducaale/xh
zinit wait from'gh-r' lbin \
    for ducaale/xh

# youtube-dl: download YouTube content
# https://github.com/ytdl-org/youtube-dl
zinit wait \
    atload'alias yta="youtube-dl -x --audio-format mp3"' \
    for ytdl-org/youtube-dl

# zoxide: a smarter cd command
# https://github.com/ajeetdsouza/zoxide
# TODO: zinit zoxide
mkcd() { mkdir -p "$1" && "$1" }
