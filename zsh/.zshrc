# region init: shell environment, paths and base directories
# force a UTF-8 english locale so tools emit and expect unicode correctly
export LANG="en_US.UTF-8"
export LC_CTYPE=${LANG}

# advertise 24-bit color so terminal apps enable truecolor output
export COLORTERM="truecolor"

# enable extended globbing (negation, glob flags) used by patterns below
setopt extendedglob

# raise the open-file limit for watchers, fzf and large completions
ulimit -n $((1024 * 1024))

# make word-wise editing (^W, Alt-B/F) operate on whole shell words
autoload -Uz select-word-style
select-word-style shell

# base system PATH as a deduped, exported array; later sections prepend to it
typeset -TUx PATH path=(/{usr/,}{local/,}{s,}bin)

# homebrew, inlined from `brew shellenv zsh` to avoid forking brew (~50ms) per shell
if [[ -x /opt/homebrew/bin/brew ]]; then
	export HOMEBREW_PREFIX="/opt/homebrew"
	export HOMEBREW_CELLAR="/opt/homebrew/Cellar"
	export HOMEBREW_REPOSITORY="/opt/homebrew"
	path=("${HOMEBREW_PREFIX}/bin" "${HOMEBREW_PREFIX}/sbin" ${path[@]})
fi

# LDFLAGS/CPPFLAGS as tied arrays so tool sections can append -L/-I entries
typeset -TUx LDFLAGS ldflags ":"
typeset -TUx CPPFLAGS cppflags ":"

# xdg base directories
# https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
export XDG_CONFIG_HOME="${HOME}/.config"
export XDG_CACHE_HOME="${HOME}/.cache"
export XDG_DATA_HOME="${HOME}/.local/share"
export XDG_STATE_HOME="${HOME}/.local/state"
export XDG_RUNTIME_DIR="${HOME}/.local/run"

# zsh directories (ZDOTDIR selects which startup files load)
# https://zsh.sourceforge.io/Intro/intro_3.html
ZDOTDIR="${XDG_CONFIG_HOME}/zsh"
ZSH_DATA_DIR="${XDG_DATA_HOME}/zsh"
ZSH_CACHE_DIR="${XDG_CACHE_HOME}/zsh"

# fpath: where zsh finds autoloadable functions and completions
typeset -TUx FPATH fpath=(
	${ZDOTDIR}
	${ZSH_CACHE_DIR}/completions
	${HOMEBREW_PREFIX}/share/zsh/site-functions
	${fpath[@]}
)

# append ZDOTDIR so `git foo` and subprocess lookups can find user scripts,
# but `command foo` still resolves to system binaries first
path+=("${ZDOTDIR}")

# autoload all regular files in ZDOTDIR (mkdirp, add, has, link, …)
autoload -Uz ${ZDOTDIR}/*(.N:t)

# create base directories now that mkdirp is autoloaded
mkdirp "${XDG_CONFIG_HOME}"
mkdirp "${XDG_CACHE_HOME}"
mkdirp "${XDG_DATA_HOME}"
mkdirp "${XDG_STATE_HOME}"
mkdirp "${XDG_RUNTIME_DIR}" 0700
mkdirp "${ZSH_DATA_DIR}"
mkdirp "${ZSH_CACHE_DIR}"
mkdirp "${ZSH_CACHE_DIR}/completions"
# endregion

# region zi: Flexible and fast ZSH plugin manager
# https://github.com/z-shell/zi
typeset -Ag ZI
ZI[HOME_DIR]="${XDG_CACHE_HOME}/zi"
ZI[BIN_DIR]="${ZI[HOME_DIR]}/bin"
source "${ZDOTDIR}/zzinit" && zzinit

alias zre="exec zsh"
alias zx="sudo rm -rf ${XDG_CACHE_HOME} && zre"

zup() {
	set -e
	local oldpwd="${PWD}"

	:brew-update
	:uv-update
	:tmux-update
	:gcloud-update

	zi self-update
	zi update --all --no-pager

	cd "${oldpwd}"

	# The installer sets ZUP_NO_EXEC to provision without dropping into an
	# interactive shell, so it can hand off to Ghostty; interactive use re-execs.
	[[ -n ${ZUP_NO_EXEC:-} ]] && return 0
	exec zsh
}
# endregion

# region zi/default: set global default ice
# https://github.com/z-shell/z-a-default-ice
zi id-as for z-shell/z-a-default-ice
zi default-ice -q lucid light-mode
# endregion

# region zi/eval: creates a cache containing the output of a command
# https://github.com/z-shell/z-a-eval
zi id-as for z-shell/z-a-eval
# endregion

# region zi/auto: load plugins with conventions
zi id-as for "${ZDOTDIR}/z-a-auto"
# endregion

# region ohmyzsh: community driven zsh framework
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
# endregion

# region history configuration
# https://zsh.sourceforge.io/Doc/Release/Options.html#History
HISTSIZE=2000000000 SAVEHIST=1000000000
HISTFILE="${ZSH_DATA_DIR}/history"
link "${HISTFILE}" .zsh_history
# endregion

# region brew: the missing package manager
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
}

:brew-load() {
	alias bbd="brew bundle dump -f"
	alias bz="brew uninstall --zap"
}

:brew-update() {
	if ! has brew; then
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
		eval "$(/opt/homebrew/bin/brew shellenv)"
		:brew-init
	fi

	brew update
	brew upgrade
	brew bundle install
	brew autoremove
	brew cleanup -s --prune=all
	chmod go-w "${HOMEBREW_PREFIX}/share"
}

zi auto has"dscl" for brew
# endregion

# region mise: dev tools, env vars, task runner
# https://github.com/jdx/mise
:mise-init() {
	export MISE_SOPS_AGE_KEY_FILE="${XDG_CONFIG_HOME}/sops/age/keys.txt"
}

:mise-load() {
	local _mise_cmd_not_found
	eval "$(mise activate zsh)"
}

zi auto has"mise" for mise
# endregion

# region python: programming language
# https://docs.python.org/3/
:python-init() {
	export PYTHONSTARTUP="${XDG_CONFIG_HOME}/python/startup.py"
	export PIP_REQUIRE_VIRTUALENV="1"
	export PIP_USER="0"
	export PYTHONNOUSERSITE="1"

	# expose brew's unversioned python/pip shims on PATH (macOS/brew only)
	if has brew; then
		add path "${HOMEBREW_PREFIX}/opt/python/libexec/bin"
	fi
}

zi auto has"python3" for python
# endregion

# region python/uv: an extremely fast Python package manager
# https://github.com/astral-sh/uv
:uv-init() {
	export UV_TOOL_DIR="${XDG_CACHE_HOME}/uv/tools"
	export UV_TOOL_BIN_DIR="${XDG_CACHE_HOME}/uv/bin"

	add path "${UV_TOOL_BIN_DIR}"
}

:uv-update() {
	uv tool upgrade --all
}

:uv-eval() {
	uv generate-shell-completion zsh
}

zi auto has"uv" for uv
# endregion

# region python/argcomplete: tab completion for argparse-based programs, installed via uv
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
# endregion

# region go: programming language
# https://www.golang.org
:go-init() {
	export GOPATH="${XDG_CACHE_HOME}/go"
	add path "${GOPATH}/bin"
}

zi auto has"go" for go
# endregion

# region js/node: JavaScript runtime
# https://nodejs.org
:node-init() {
	export NODE_REPL_HISTORY="${XDG_DATA_HOME}/node/repl_history"
	mkdirp "${XDG_DATA_HOME}/node"
}

zi auto has"node" wait1 for node
# endregion

# region js/npm: node package manager
# https://docs.npmjs.com
:npm-init() {
	link npm/npmrc .npmrc
}

zi auto has"npm" wait1 for npm
# endregion

# region js/bun: all-in-one JavaScript runtime & toolkit
# https://bun.sh
:bun-init() {
	export BUN_INSTALL="${XDG_DATA_HOME}/bun"
	export BUN_INSTALL_CACHE_DIR="${XDG_CACHE_HOME}/bun"
	add path "${BUN_INSTALL}/bin"
}

zi auto has"bun" wait1 for bun
# endregion

# region js/biome: formatter & linter for the web (JS/TS/JSON/CSS)
# https://biomejs.dev
:biome-eval() {
	biome completions zsh
}

zi auto has"biome" for biome
# endregion

# region ruby: programming language
# https://www.ruby-lang.org
:ruby-init() {
	export GEM_HOME="${XDG_CACHE_HOME}"/gem
	export GEM_SPEC_CACHE="${XDG_CACHE_HOME}"/gem
	export BUNDLE_USER_CONFIG="${XDG_CONFIG_HOME}"/bundle
	export BUNDLE_USER_CACHE="${XDG_CACHE_HOME}"/bundle
	export BUNDLE_USER_PLUGIN="${XDG_DATA_HOME}"/bundle

	# expose brew's ruby on PATH (macOS/brew only)
	if has brew; then
		add path "${HOMEBREW_PREFIX}/opt/ruby/bin"
	fi
}

zi auto has"ruby" for ruby
# endregion

# region 1password: remembers all your passwords for you
# https://1password.com
:1password-cli-eval() {
	chmod 0700 "${XDG_CONFIG_HOME}/op"
	op completion zsh
}

zi auto has"op" wait1 for 1password-cli
# endregion

# region atuin: magical shell history with optional sync
# https://github.com/atuinsh/atuin
:atuin-load() {
	alias a="atuin"
}

:atuin-eval() {
	atuin init zsh --disable-up-arrow
}

zi auto has"atuin" wait1 for atuin
# endregion

# region bat: cat(1) clone with wings
# https://github.com/sharkdp/bat
:bat-init() {
	export BAT_CONFIG_PATH="${XDG_CONFIG_HOME}"/bat/config BAT_PAGER="less"
	export MANPAGER="sh -c 'col -bx | bat -l man'" MANROFFOPT="-c"
}

zi auto has"bat" wait1 for bat
# endregion

# region claude: AI assistant by Anthropic
# https://claude.ai
:claude-init() {
	export CLAUDE_CODE_NEW_INIT=1
	export ENABLE_CLAUDEAI_MCP_SERVERS=true
}

zi auto has"claude" wait1 for claude
# endregion

# region colima: container runtimes on macOS with minimal setup
# https://github.com/abiosoft/colima
:colima-init() {
	link colima .colima

	# colima has no option to relocate its heavy VM/instance state (_lima) and
	# profile store (_store), so keep them in data (not the repo'd config dir) via
	# symlinks resolved for both the CLI and the launchd service.
	mkdirp "${XDG_DATA_HOME}/colima/_lima"
	mkdirp "${XDG_DATA_HOME}/colima/_store"
	link "${XDG_DATA_HOME}/colima/_lima" "${XDG_CONFIG_HOME}/colima/_lima"
	link "${XDG_DATA_HOME}/colima/_store" "${XDG_CONFIG_HOME}/colima/_store"
}

:colima-load() {
	# unset XDG_CONFIG_HOME so the CLI uses ~/.colima like the brew launchd service
	# does (it has no XDG env), keeping both pointed at the same home; this also
	# silences colima's XDG warning.
	alias colima="env -u XDG_CONFIG_HOME colima"

	# `brew services start` forks brew + launchctl and takes ~900ms; running it
	# synchronously here froze the first prompt's input for ~1s while this plugin
	# loaded in turbo. it's idempotent (the launchd service persists once started),
	# so fire-and-forget in the background and let the shell stay responsive.
	brew services start colima &>/dev/null &|
}

zi auto has"colima" wait1 for colima
# endregion

# region dircolors: setup colors for ls and friends
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

zi auto id-as"dircolors" wait1 for trapd00r/LS_COLORS
# endregion

# region direnv: change environment based on the current directory
# https://github.com/direnv/direnv
:direnv-load() {
	alias da="direnv allow"
}

:direnv-eval() {
	direnv hook zsh
}

zi auto has"direnv" for direnv/direnv
# endregion

# region docker: container runtime CLI
# https://github.com/docker/cli
:docker-init() {
	link docker .docker
}

zi auto has"docker" wait1 for docker
# endregion

# region duf: better `df` alternative
# https://github.com/muesli/duf
:duf-load() {
	alias df=duf
}

zi auto has"duf" wait1 for duf
# endregion

# region eza: a modern replacement for ‘ls’.
# https://github.com/ogham/eza
:eza-init() {
	export EZA_ICONS_AUTO=1
}

:eza-load() {
	alias l="eza --all --long --group"
	alias lR="l -R"
}

zi auto has"eza" wait1 for eza
# endregion

# region fzf: command-line fuzzy finder
# https://github.com/junegunn/fzf
:fzf-init() {
	# https://github.com/catppuccin/fzf/blob/main/themes/catppuccin-fzf-mocha.sh
	export FZF_DEFAULT_OPTS=" \
	    --color=bg+:#313244,bg:#1E1E2E,spinner:#F5E0DC,hl:#F38BA8 \
	    --color=fg:#CDD6F4,header:#F38BA8,info:#CBA6F7,pointer:#F5E0DC \
	    --color=marker:#B4BEFE,fg+:#CDD6F4,prompt:#CBA6F7,hl+:#F38BA8 \
	    --color=selected-bg:#45475A \
	    --color=border:#6C7086,label:#CDD6F4"
}

zi auto has"fzf" wait1 for fzf
# endregion

# region gcloud: Google Cloud SDK
# https://cloud.google.com/sdk
:gcloud-init() {
	mkdirp "${XDG_DATA_HOME}/gcloud"
	link "${XDG_DATA_HOME}/gcloud" "${XDG_CONFIG_HOME}/gcloud"
}

:gcloud-update() {
	gcloud components update --quiet || :
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
# endregion

# region ghostty: fast, native, GPU-accelerated terminal emulator
# https://ghostty.org
add path "${GHOSTTY_BIN_DIR}"
# endregion

# region git: distributed version control system
# https://github.com/git/git
:git-load() {
	alias ga="git add --all"
	alias gap="git add --patch"
	alias gba="git branch -a"
	alias gcl="git cleanup"
	alias gd="git diff"
	alias gdc="git diff --cached"
	alias gdm="git diff origin/\$(git main-branch)"
	alias gf="git fetch"
	alias gl="git lg"
	alias gp="git pull"
	alias grh="git reset HEAD"
	alias gsm="git switch \$(git main-branch)"
	alias gsp="git show -p"
	alias gss="git stash show -p"
	alias gup="git up"
	alias s="git st ."
}

zi auto id-as"git" as"completion" blockf mv"git->_git" wait1 for \
	https://github.com/git/git/blob/master/contrib/completion/git-completion.zsh
# endregion

# region glow: terminal markdown rendering
# https://github.com/charmbracelet/glow
:glow-init() {
	export GLAMOUR_STYLE="${HOME}/.config/glow/styles/catppuccin-mocha.json"
	export GLOW_STYLE="${GLAMOUR_STYLE}"
}

zi auto has"glow" wait1 for glow
# endregion

# region gnupg: GNU privacy guard
# https://gnupg.org/
:gnupg-init() {
	export GPG_TTY="${TTY}"
	export GNUPGHOME="${XDG_DATA_HOME}/gnupg"
	mkdirp "${GNUPGHOME}" 0700
}

zi auto has"gpg" wait1 for gnupg
# endregion

# region less: pager configuration
# https://man7.org/linux/man-pages/man1/less.1.html#OPTIONS
:less-init() {
	export PAGER="${commands[less]}" LESS="--ignore-case --LONG-PROMPT --RAW-CONTROL-CHARS --HILITE-UNREAD --chop-long-lines --tabs=4"
	export LESSHISTFILE="${XDG_DATA_HOME}/less/history"
	mkdirp "${LESSHISTFILE:h}"
}

zi auto has"less" for less
# endregion

# region ncdu: disk usage analyzer
# https://dev.yorhel.nl/ncdu
:ncdu-init() {
	link ncduignore .ncduignore
}

zi auto has"ncdu" wait1 for ncdu
# endregion

# region opentofu: open-source terraform fork, installed via mise
# https://github.com/opentofu/opentofu
:opentofu-init() {
	export TF_PLUGIN_CACHE_DIR="${XDG_CACHE_HOME}/opentofu/plugins"
	mkdirp "${TF_PLUGIN_CACHE_DIR}"
}

:opentofu-load() {
	alias tf="tofu"

	complete -o nospace -C tofu tofu
}

zi auto has"tofu" wait1 for opentofu
# endregion

# region parallel: run commands in parallel
# https://www.gnu.org/software/parallel/
:parallel-init() {
	export PARALLEL_HOME="${XDG_CONFIG_HOME}/parallel"
	mkdirp ${PARALLEL_HOME}
}

zi auto has"parallel" wait1 for parallel
# endregion

# region postgresql: object-relational database
# https://www.postgresql.org
:postgresql-init() {
	if has brew; then
		add path "${HOMEBREW_PREFIX}/opt/postgres/bin"
		add ldflags "-L${HOMEBREW_PREFIX}/opt/postgres/lib"
		add cppflags "-I${HOMEBREW_PREFIX}/opt/postgres/include"
	fi
}

zi auto has"psql" for postgresql
# endregion

# region rsync: fast incremental file transfer
# https://rsync.samba.org
zi auto wait1 for OMZP::rsync
# endregion

# region sops: editor of encrypted files (age, gpg, cloud KMS)
# https://github.com/getsops/sops
:sops-init() {
	export SOPS_AGE_KEY_FILE="${XDG_CONFIG_HOME}/sops/age/keys.txt"
}

zi auto has"sops" wait1 for sops
# endregion

# region ssh: secure shell
# https://www.openssh.com
:ssh-init() {
	mkdirp "${XDG_CACHE_HOME}/ssh"
	mkdirp "${HOME}/.ssh" 0700
	link ssh/config .ssh/config

	# ssh rejects a group/world-writable config; enforce 0600 without forking
	# chmod on every startup — only when the mode has actually drifted
	local -a st
	zmodload -F zsh/stat b:zstat
	zstat -A st +mode -- "${HOME}/.ssh/config" 2>/dev/null &&
		(((st[1] & 8#777) != 8#600)) && chmod 0600 "${HOME}/.ssh/config"

	# prefer 1password's ssh agent socket when present, else OMZP::ssh-agent
	# https://1password.community/discussion/comment/660153/#Comment_660153
	local op_sock="${HOME}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
	if [[ -e "${op_sock}" ]]; then
		export SSH_AUTH_SOCK="${op_sock}"
	else
		zi auto silent wait1 for OMZP::ssh-agent
	fi
}

zi auto has"ssh" for ssh
# endregion

# region tmux: a terminal multiplexer
# https://github.com/tmux/tmux
:tmux-init() {
	export TMUX_PLUGIN_MANAGER_PATH="${XDG_CACHE_HOME}/tmux/plugins"
	export ZSH_TMUX_CONFIG="${XDG_CONFIG_HOME}/tmux/tmux.conf"
	export ZSH_TMUX_DEFAULT_SESSION_NAME="default"
	export ZSH_TMUX_FIXTERM="false"
}

:tmux-load() {
	alias T=tmux
}

:tmux-update() {
	:tmux-init
	clone tmux-plugins/tpm "${TMUX_PLUGIN_MANAGER_PATH}/tpm"
	${TMUX_PLUGIN_MANAGER_PATH}/tpm/bin/install_plugins
}

zi auto has"tmux" silent for OMZP::tmux
# endregion

# region vim: vi improved, via neovim
# https://neovim.io
:neovim-init() {
	export VIMINIT="set nocp | source ${XDG_CONFIG_HOME}/vim/vimrc"
	export EDITOR="${commands[nvim]}"
}

:neovim-load() {
	alias vim=nvim
}

zi auto has"nvim" for neovim
# endregion

# region vscode: visual studio code editor
# https://code.visualstudio.com
:vscode-init() {
	if ! has "${HOME}/Library/Application Support/Code/User"; then
		return
	fi

	for i in settings keybindings mcp; do
		link "vscode/${i}.json" "Library/Application Support/Code/User/${i}.json"
	done
}

zi auto has"code" wait1 for vscode
# endregion

# region wget: retrieve files using HTTP, HTTPS, FTP and FTPS
# https://www.gnu.org/software/wget/
:wget-init() {
	export WGETRC="${XDG_CONFIG_HOME}/wgetrc"
}

:wget-load() {
	alias wget="wget --hsts-file=\"${XDG_CACHE_HOME}/wget-hsts\""
}

zi auto has"wget" wait1 for wget
# endregion

# region zsh/you-should-use: reminds you to use existing aliases for commands you just typed
# https://github.com/MichaelAquilina/zsh-you-should-use
if has tput; then
	zi auto wait1 for MichaelAquilina/zsh-you-should-use
	YSU_MESSAGE_POSITION="after"
fi
# endregion

# region zsh/starship: minimal, blazing-fast, customizable prompt
# https://starship.rs
if has starship; then
	eval "$(starship init zsh)"
	# `starship init zsh` sets both PROMPT and RPROMPT, so the starship binary
	# is spawned twice per prompt redraw (~40ms each). The right prompt is
	# empty by default — drop RPROMPT to halve command_lag.
	unset RPROMPT
fi
# endregion

# region zsh/completion: extra completion functions. Loads before compinit so they
# land in fpath, then its atload runs compinit once — replaying the compdefs
# queued by every completion plugin above — before fzf-tab and the widget
# wrappers below.
# https://github.com/zsh-users/zsh-completions
zi auto blockf atpull'zinit creinstall -q zsh-users/zsh-completions' \
	atload"zicompinit; zicdreplay" wait for zsh-users/zsh-completions
# endregion

# region zsh/completion: replace the completion menu with fzf-tab. Must load after compinit (above)
# and before the widget-wrapping plugins (autosuggestions, F-Sy-H) below.
# https://github.com/Aloxaf/fzf-tab
zi auto has"fzf" wait for Aloxaf/fzf-tab

# preview directory content with eza when completing cd. =always forces color and
# icons even though the preview is piped (eza auto-disables both off a TTY); icons
# need a Nerd Font, which the terminal already uses.
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --all --long --group --color=always --icons=always $realpath'

# zsh/completion
zmodload -i zsh/complist # list-colors support + native menu
unsetopt flowcontrol     # reclaim ^S/^Q from terminal flow control
setopt complete_in_word  # allow completing with the cursor mid-word
setopt always_to_end     # ...and jump the cursor to the word end afterwards

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
# endregion

# region zsh/completion: completer chain — exact, then spelling correction, then fuzzy/approximate with an
# error budget that scales with word length. fzf filters the candidate list itself,
# but _correct/_approximate also repair typos in the typed prefix, which fzf can't.
# https://zsh.sourceforge.io/Doc/Release/Completion-System.html#Control-Functions
zstyle ':completion:*' completer _complete _correct _approximate
zstyle -e ':completion:*:approximate:*' max-errors 'reply=($((($#PREFIX+$#SUFFIX)/3>7?7:($#PREFIX+$#SUFFIX)/3))numeric)'

# candidates
zstyle ':completion:*' special-dirs true # offer the `.` and `..` directories
zstyle ':completion:*' use-cache yes     # cache results for completers that support it
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
# endregion

# region zsh/completion: git — never offer ORIG_HEAD as a ref, and keep switch/checkout's native branch order
# https://stackoverflow.com/questions/12508595/ignore-orig-head-in-zsh-git-autocomplete#comment99936479_14325591
zstyle ':completion:*:*:git*:*' ignored-patterns '*ORIG_HEAD'
zstyle ':completion:*:git-checkout:*' sort false
zstyle ':completion:*:git-switch:*' sort false
# endregion

# region zsh/completion: make — invoke the makefile so macro-defined targets are completed too
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
# endregion

# region zsh/f-sy-h: feature-rich syntax highlighting for ZSH (loads last, after fzf-tab)
# https://github.com/z-shell/F-Sy-H
zi auto wait for z-shell/F-Sy-H
# endregion

# region zsh/autosuggestions: fish-like autosuggestions for zsh
# https://github.com/zsh-users/zsh-autosuggestions
zi auto atload"_zsh_autosuggest_start" \
	wait for zsh-users/zsh-autosuggestions
# endregion

# region zsh/autopair: automatically close quotes, brackets and other delimiters
# https://github.com/hlissner/zsh-autopair
zi auto wait for hlissner/zsh-autopair
# endregion

# add local bin last so user binaries take precedence over tool/brew paths
add path "${HOME}/.local/bin"

# Load .envrc after shell initialization if present
if [[ -e .envrc ]]; then
	pushd "${HOME}" &>/dev/null && popd
fi
