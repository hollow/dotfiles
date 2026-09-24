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
ZSH_STATE_DIR="${XDG_STATE_HOME}/zsh"

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
mkdirp "${ZSH_STATE_DIR}"
# endregion

# region zi: Flexible and fast ZSH plugin manager
# https://github.com/z-shell/zi
typeset -Ag ZI
ZI[HOME_DIR]="${XDG_CACHE_HOME}/zi"
ZI[BIN_DIR]="${ZI[HOME_DIR]}/bin"
source "${ZDOTDIR}/zzinit" && zzinit

alias zre="exec zsh"
alias zx="sudo rm -rf ${XDG_CACHE_HOME} && zre"
dotfiles-update-check notice
dotfiles-update-check start

zup() {
	set -e
	# pipefail so the awk-filtered `zi update` pipeline (and any other pipe in
	# zup) still trips `set -e` when an upstream stage fails; local_options
	# scopes the change to this function.
	setopt local_options pipefail
	local oldpwd="${PWD}"

	# Pull the dotfiles first so the rest of zup (Brewfile, plugin list, …)
	# and the final `exec zsh` run against the latest config. Non-fatal:
	# offline or diverged checkouts print git's error and zup carries on.
	# On success, clear any cached background-check notice.
	if git -C "${XDG_CONFIG_HOME}" pull --ff-only --quiet; then
		dotfiles-update-check mark-up-to-date >/dev/null 2>&1 || :
	fi

	:brew-update
	:uv-update
	:tmux-update
	:gcloud-update

	zi self-update -q
	# zi update is chatty: a "Updating: <plugin>" header for every plugin,
	# git commit logs for plugins that advanced, curl --progress-bar frames
	# for snippet downloads, fast-forward/diff stats. -q only kills some of
	# it. Filter the rest: buffer "Updating:" lines and only release them
	# when followed by a real commit line, so we see which plugins moved.
	# sed converts the \r-overwritten progress frames into separate lines
	# so the awk anchors can match them.
	zi update --all --no-pager 2>&1 | sed -E 's/\r/\n/g' | awk '
		/^Updating: / { pending = $0; next }
		/^\* [0-9a-fA-F]+ - .*<.*>$/ {
			if (pending != "") { print pending; pending = "" }
			next
		}
		/^Updating [0-9a-fA-F]+\.\.[0-9a-fA-F]+$/ { next }
		/^Fast-forward$/ { next }
		/^Updating snippet: / { next }
		/^Downloading: / { next }
		/^From https?:\/\// { next }
		/^ +\* branch +[^ ]+ +-> / { next }
		/^ +[^ ]+ +\| +[0-9]+/ { next }
		/^ +[0-9]+ files? changed/ { next }
		/^[#[:space:]]+[0-9]+\.[0-9]+%[[:space:]]*$/ { next }
		/^[[:space:]]*$/ { next }
		{
			if (pending != "") { print pending; pending = "" }
			print
		}
	'

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
	OMZL::spectrum.zsh \
	OMZL::termsupport.zsh

# region zle: command-line editor key bindings
# Keep default emacs-style ZLE behavior, then add only the transport bindings
# needed for Ghostty's macOS-style navigation chords to work in the prompt:
#   Cmd+Left/Right     -> start/end of line
#   Option+Left/Right  -> previous/next shell word
#   Shift+Tab          -> reverse completion menu
bindkey -e
# Load $terminfo when Ghostty provides a TERMINFO database; literal fallback
# bindings below keep the common xterm-style sequences working either way.
zmodload zsh/terminfo 2>/dev/null || true

# Application cursor/keypad mode makes terminfo Home/End/arrow sequences match
# what Ghostty sends while ZLE is active. Hook instead of replacing
# zle-line-init/finish so later widgets can coexist.
if ((${+terminfo[smkx]})) && ((${+terminfo[rmkx]})); then
	autoload -Uz add-zle-hook-widget
	:zle-application-mode-start() { echoti smkx; }
	:zle-application-mode-stop() { echoti rmkx; }
	add-zle-hook-widget line-init :zle-application-mode-start
	add-zle-hook-widget line-finish :zle-application-mode-stop
fi

# Up/Down: :line-or-beginning-search (in ZDOTDIR) replaces the stock
# widgets, which stall when async plugin callbacks reset $LASTWIDGET.
zle -N up-line-or-beginning-search :line-or-beginning-search
zle -N down-line-or-beginning-search :line-or-beginning-search

autoload -Uz edit-command-line
zle -N edit-command-line

# Up/Down use prefix-history search: type a prefix, then walk only matching
# history entries. Bind both CSI and SS3 forms because the application-cursor
# hook can make terminals switch between them.
bindkey "^[[A" up-line-or-beginning-search
bindkey "^[[B" down-line-or-beginning-search
bindkey "^[OA" up-line-or-beginning-search
bindkey "^[OB" down-line-or-beginning-search
[[ -n "${terminfo[kcuu1]}" ]] && bindkey "${terminfo[kcuu1]}" up-line-or-beginning-search
[[ -n "${terminfo[kcud1]}" ]] && bindkey "${terminfo[kcud1]}" down-line-or-beginning-search

# Home/End: Ghostty sends CSI H/F for Cmd+Left/Right; xterm-ghostty terminfo
# uses SS3 OH/OF. Bind both so ZLE accepts either transport.
[[ -n "${terminfo[khome]}" ]] && bindkey "${terminfo[khome]}" beginning-of-line
[[ -n "${terminfo[kend]}" ]] && bindkey "${terminfo[kend]}" end-of-line
bindkey "^[[H" beginning-of-line
bindkey "^[[F" end-of-line
bindkey "^[OH" beginning-of-line
bindkey "^[OF" end-of-line

# Option+Left/Right: Ghostty sends Shift+Left/Right so Vim/Neovim can use their
# default word motions; map the same sequences to shell-word motion in ZLE.
bindkey "^[[1;2D" backward-word
bindkey "^[[1;2C" forward-word

# Common terminal Ctrl+Left/Right fallback. Not emitted by Ghostty for Option,
# but useful if another terminal sends it.
bindkey "^[[1;5D" backward-word
bindkey "^[[1;5C" forward-word

# Editing conveniences. Ctrl+R, Ctrl+U, Backspace, and Option+Backspace remain
# zsh defaults from bindkey -e/select-word-style; the lines here add terminal
# transport fallbacks plus magic-space history expansion.
[[ -n "${terminfo[kdch1]}" ]] && bindkey "${terminfo[kdch1]}" delete-char
bindkey "^[[3~" delete-char
bindkey " " magic-space
bindkey "^[[5~" up-line-or-history
bindkey "^[[6~" down-line-or-history
bindkey "^[[Z" reverse-menu-complete
bindkey "^X^E" edit-command-line
# endregion

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
	alias bbd="brew bundle dump --no-describe --force"
	alias bz="brew uninstall --zap"
}

:brew-update() {
	if ! has brew; then
		# NONINTERACTIVE skips the installer's "Press RETURN to continue"
		# confirmation; the sudo password prompt still appears when needed.
		NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
		eval "$(/opt/homebrew/bin/brew shellenv)"
		:brew-init
	fi

	# HOMEBREW_NO_ASK skips the "Do you want to proceed?" prompt that brew
	# upgrade/install added in 4.4+. HOMEBREW_NO_ENV_HINTS suppresses the
	# "Disable this behaviour by setting..." hints after each step.
	local -x HOMEBREW_NO_ASK=1
	local -x HOMEBREW_NO_ENV_HINTS=1

	brew update --quiet
	brew upgrade --quiet
	brew bundle install --quiet
	brew autoremove
	brew cleanup -s --prune=all --quiet
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

# add local bin so user binaries take precedence over tool/brew paths
add path "${HOME}/.local/bin"

# region 1password: remembers all your passwords for you
# https://1password.com
:1password-cli-init() {
	mkdirp "${XDG_CONFIG_HOME}/op" 0700
}

:1password-cli-completion() {
	op completion zsh
}

zi auto has"op" wait1 for 1password-cli
# endregion

# region android: development kit
# https://developer.android.com/studio/command-line/variables
export ANDROID_EMULATOR_HOME="${XDG_CONFIG_HOME}/android"
# endregion

# region ansible: simple IT automation
# https://github.com/ansible/ansible
# ANSIBLE_HOME is the base for collections, roles, plugins and the galaxy token
# (all data); tmp/cp go to runtime and the galaxy cache to cache instead.
:ansible-init() {
	export ANSIBLE_GALAXY_CACHE_DIR="${XDG_CACHE_HOME}/ansible"
	export ANSIBLE_LOCAL_TEMP="${XDG_RUNTIME_DIR}/ansible/tmp"
	export ANSIBLE_PERSISTENT_CONTROL_PATH_DIR="${XDG_RUNTIME_DIR}/ansible/cp"
	export ANSIBLE_DISPLAY_SKIPPED_HOSTS=no
	export ANSIBLE_DISPLAY_OK_HOSTS=no
}

:ansible-load() {
	alias ad="ansible-doc"
	alias ai="ansible-inventory"
	alias ap="ansible-playbook"
}

zi auto has"ansible" wait1 for ansible
# endregion

# region ansible/ara: ARA Records Ansible
# https://github.com/ansible-community/ara
#
# server and client both come from `uv tool install 'ara[server]' --with
# gunicorn --python 3.14`. the server is kept running by launchd
# (launchd/ara-server.plist, settings in ara/settings.yaml);
# the client is ara's callback plugin, which Ansible loads from that same tool
# env so the ansible repos themselves carry no ara dependency or config.
:ara-init() {
	export ARA_BASE_DIR="${XDG_DATA_HOME}/ara/server"
	export ARA_SETTINGS="${XDG_CONFIG_HOME}/ara/settings.yaml"
	export ARA_API_CLIENT="http"
	export ARA_API_SERVER="http://127.0.0.1:8100"

	link launchd/ara-server.plist Library/LaunchAgents/ara-server.plist

	# the callback runs inside each repo's venv python, which must import `ara`
	# (and requests, which the repos have). expose only the ara package through
	# a dedicated import dir so nothing else from the tool env shadows the venv.
	# not ARA_*: ara's dynaconf would read any such variable as a setting.
	local -a site=(${UV_TOOL_DIR}/ara/lib/python3.<->/site-packages(N/))
	typeset -g _ara_callback_plugins="${site[1]}/ara/plugins/callback"
	typeset -g _ara_pythonpath="${XDG_DATA_HOME}/ara/pythonpath"
	mkdirp "${_ara_pythonpath}"
	link "${site[1]}/ara" "${_ara_pythonpath}/ara"
}

# the ansible repos' .envrc overwrites ANSIBLE_CALLBACK_PLUGINS and PYTHONPATH,
# so a plain global export never reaches ansible there. direnv puts its hook
# first in both chpwd_functions and precmd_functions; this hook is registered
# on both as well, runs after it, and appends ara's paths whenever direnv has
# set ANSIBLE_CALLBACK_PLUGINS (i.e. in a repo that runs ansible). chpwd covers
# helpers like :each that cd and run a command before the next prompt; :parallel
# clears the hook arrays and re-runs the chpwd hooks itself after loading direnv.
# leaving the repo, direnv restores both variables itself.
:ara-hook() {
	[[ -n ${ANSIBLE_CALLBACK_PLUGINS-} && ${ANSIBLE_CALLBACK_PLUGINS} != *"${_ara_callback_plugins}"* ]] || return 0
	export ANSIBLE_CALLBACK_PLUGINS="${ANSIBLE_CALLBACK_PLUGINS}:${_ara_callback_plugins}"
	export PYTHONPATH="${PYTHONPATH:+${PYTHONPATH}:}${_ara_pythonpath}"
}

:ara-load() {
	autoload -Uz add-zsh-hook
	add-zsh-hook chpwd :ara-hook
	add-zsh-hook precmd :ara-hook

	# bootstrap is a no-op once the agent is loaded (exit 37), so fire-and-forget
	# like colima: launchctl forks are slow and must not block the prompt.
	launchctl bootstrap gui/${UID} "${HOME}/Library/LaunchAgents/ara-server.plist" &>/dev/null &|
}

# tab completion: zsh/_ara
zi auto has"ara-manage" wait1 for ara
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

# region aws: Amazon Web Services CLI
# https://aws.amazon.com/cli/
:aws-init() {
	export SHOW_AWS_PROMPT=false
}

zi auto has"aws" wait1 for OMZP::aws
# endregion

# region aws/boto: AWS SDK for Python
# https://github.com/boto/boto3
export BOTO_CONFIG="${XDG_DATA_HOME}/boto"
print -r -- "[GSUtil]
state_dir = ${XDG_DATA_HOME}/gsutil
parallel_composite_upload_threshold = 150M" >"${BOTO_CONFIG}"
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
	local src="${HOME}/Library/Application Support/Claude/claude_desktop_config.json"
	local dst="${HOME}/.claude/claude_desktop_config.json"
	[[ -e ${src} ]] && cp "${src}" "${dst}"
}

:claude-load() {
	alias c="claude"
	alias cr="claude -r"
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

# region consul: distributed, highly available service discovery
# https://github.com/hashicorp/consul
:consul-load() {
	complete -o nospace -C consul consul
}

zi auto has"consul" wait1 for consul
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
	# --quiet only skips prompts; the banner and progress output bypass
	# --verbosity, so silence everything (failures are ignored anyway).
	gcloud components update --quiet >/dev/null 2>&1 || :
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

export GOOGLE_WORKSPACE_CLI_KEYRING_BACKEND=file

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
	alias gr="git restore"
	alias grh="git reset HEAD"
	alias gsm="git switch \$(git main-branch)"
	alias gsp="git show -p"
	alias gss="git stash show -p"
	alias gup="git up"
	alias s="git st ."
}

zi auto has"git" wait1 for git
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

# region leaf: terminal markdown previewer
# https://leaf.rivolink.mg
:leaf-completion() {
	leaf --auto-complete zsh:dump
}

zi auto has"leaf" wait1 for leaf
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

# region nomad: workload orchestrator
# https://github.com/hashicorp/nomad
:nomad-load() {
	complete -o nospace -C nomad nomad
}

zi auto has"nomad" wait1 for nomad
# endregion

# region terraform: infrastructure as code
# https://github.com/hashicorp/terraform
:terraform-init() {
	export TF_PLUGIN_CACHE_DIR="${XDG_CACHE_HOME}/terraform/plugins"
	mkdirp "${TF_PLUGIN_CACHE_DIR}"
	link terraform .terraform.d
}

:terraform-load() {
	alias tf="terraform"

	complete -o nospace -C terraform terraform
}

zi auto has"terraform" wait1 for terraform
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

# region sqlite: database engine
# https://sqlite.org
:sqlite-init() {
	export SQLITE_HISTORY="${XDG_DATA_HOME}/sqlite/history"
}

zi auto has"sqlite3" wait1 for sqlite
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

# region sshp: Parallel SSH Executor
# https://github.com/bahamas10/sshp
zi make as"program" for bahamas10/sshp
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
	# tpm has no quiet flag; filter the per-plugin "Already installed" noise
	# but keep real install/update lines. grep exits 1 when nothing passes,
	# which is normal here, so absorb it.
	${TMUX_PLUGIN_MANAGER_PATH}/tpm/bin/install_plugins | grep -v '^Already installed' || :
}

zi auto has"tmux" silent for OMZP::tmux
# endregion

# region tmux/xpanes: run commands across synchronized tmux panes
# https://github.com/greymd/tmux-xpanes
zi auto has"tmux" wait1 for greymd/tmux-xpanes
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

# region youtube: download audio
# https://github.com/yt-dlp/yt-dlp
:youtube-load() {
	alias yta="yt-dlp --extract-audio --audio-format mp3 --add-metadata"
}

zi auto has"yt-dlp" wait1 for youtube
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
# land in fpath, then its atload runs compinit once — before fzf-tab and the
# widget wrappers below.
#
# completion contract: a completer is a `#compdef` file on fpath (brew's
# site-functions, zsh-completions, zsh/, and ${ZSH_CACHE_DIR}/completions, which
# :<name>-completion hooks fill at install/update time), so compinit registers
# everything itself. zi only queues `compdef` calls made while a plugin loads;
# zicdreplay runs that queue once, here, for the synchronous blocks above
# (argcomplete's -default-, tmux aliases) — a wait1 block calling compdef is
# lost. bashcompinit is loaded here as well: its `complete` needs compdef, so
# `complete -C` calls belong in wait1 :<name>-load hooks, never at top level.
# https://github.com/zsh-users/zsh-completions
zi auto blockf atpull'zinit creinstall -q .' \
	atload"zicompinit; zicdreplay; autoload -Uz bashcompinit && bashcompinit" \
	wait for zsh-users/zsh-completions
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
# endregion

# region zsh/f-sy-h: feature-rich syntax highlighting for ZSH (loads last, after fzf-tab)
# https://github.com/z-shell/F-Sy-H
zi auto wait for z-shell/F-Sy-H
# endregion

# region zsh/autosuggestions: fish-like autosuggestions for zsh
# https://github.com/zsh-users/zsh-autosuggestions
:zsh-autosuggestions-load() {
	# F-Sy-H keeps the original of every widget it wraps under fsh-orig-*
	# (orig-* before its 2026-08 rewrite, which autosuggestions ignores by
	# default). Without this entry the copies get wrapped as "modify" widgets
	# too, and every Up press fetches a needless suggestion. Must precede the
	# first bind below.
	ZSH_AUTOSUGGEST_IGNORE_WIDGETS+=('fsh-orig-*')
	_zsh_autosuggest_start
}
zi auto wait for zsh-users/zsh-autosuggestions
# endregion

# region zsh/autopair: automatically close quotes, brackets and other delimiters
# https://github.com/hlissner/zsh-autopair
zi auto wait for hlissner/zsh-autopair
# endregion

# region zsh/bench: benchmark zsh startup and interactive lag
# https://github.com/romkatv/zsh-bench
zi as"program" wait1 for romkatv/zsh-bench
# endregion

# Load .envrc after shell initialization if present
if [[ -e .envrc ]]; then
	pushd "${HOME}" &>/dev/null && popd
fi
