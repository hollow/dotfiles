# zshrc `:*-init` / `:*-load` consistency — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers-extended-cc:subagent-driven-development (recommended) or superpowers-extended-cc:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Convert every per-tool config block in `zsh/.zshrc` to the uniform `z-a-auto` hook shape — env/paths/filesystem setup in `:<name>-init`, interactive sugar in `:<name>-load` — triggered by a gated `zi auto … for <name>` line, modeled on `:brew-init`.

**Architecture:** Each block's inline statements move into `:<name>-init` (atinit: `export`/`add`/`mkdirp`/`link`) and/or `:<name>-load` (atload: `alias`/`complete`/`source`). Config-only blocks get a **new** `zi auto has"<cmd>" wait1 for <name>` trigger (turbo-deferred, gated on the binary). Blocks that already load a plugin reuse their existing trigger and inherit its timing. Generic/prerequisite env (PAGER, EDITOR, PATH) stays synchronous.

**Tech Stack:** zsh, the `z-shell/zi` plugin manager, the local `z-a-auto` annex (`zsh/z-a-auto/z-a-auto.plugin.zsh`).

**Spec:** `docs/superpowers/specs/2026-06-08-zshrc-init-load-consistency-design.md`

---

## Cross-cutting conventions (apply to EVERY task)

1. **Define hook functions BEFORE their `zi auto … for <name>` line.** The annex resolves `:<name>-eval` at the moment the `zi auto` line is *executed* (during sourcing), and `-init`/`-load` at hook-fire time. Defining all hooks before the trigger line matches the existing file convention (`:brew-init` at the top of its block, trigger at the bottom) and avoids ordering surprises. Several blocks below require **reordering** because the current trigger line sits above the statements.

2. **Indentation:** function bodies use a single leading **tab** (the file's existing style).

3. **The file is the live config.** `/Users/bene/.config/zsh/.zshrc` *is* `$ZDOTDIR/.zshrc`. A fresh `zsh -ic '…'` re-sources the edited file.

4. **Standard verify commands** (used throughout):
   - Syntax: `zsh -n /Users/bene/.config/zsh/.zshrc && echo SYNTAX-OK`
   - Clean sourcing: `zsh -ic 'true' 2>&1 | grep -iE 'parse error|bad pattern|bad option|defined|substitution' && echo SAW-ERRORS || echo SOURCE-CLEAN`
   - Function defined: `zsh -ic 'functions :<name>-init >/dev/null && echo ok'`
   - Body correctness (calls the hook directly, bypassing turbo timing): `zsh -ic ':<name>-init; print -r -- $SOME_VAR'`

   **Turbo caveat:** `wait1` hooks fire after the first interactive prompt, which a `zsh -ic '…'` one-shot does **not** reach. So automated checks call the hook function *directly* to verify its body; confirmation that the trigger actually fires is done once, interactively, in Task 7 (`zre` then inspect).

5. **Commit per task.** Conventional-commit style, scope `zsh`.

---

### Task 1: Create branch + split the brew template

**Goal:** Branch the work, and bring `:brew-init` itself under the init/load rule by moving its aliases into a new `:brew-load`.

**Files:**
- Modify: `/Users/bene/.config/zsh/.zshrc` (the `:brew-init` block, ~lines 143-162)

**Acceptance Criteria:**
- [ ] On a new branch off `main`.
- [ ] `:brew-init` contains only `export` + `add path`/`add fpath`.
- [ ] New `:brew-load` contains the `bbd`/`bz` aliases.
- [ ] `:brew-update` (which calls `:brew-init`) is unchanged.
- [ ] Syntax + sourcing clean; `bbd`/`bz` resolvable via `:brew-load`.

**Verify:** `zsh -ic ':brew-load; alias bbd bz' ` → prints both alias definitions.

**Steps:**

- [ ] **Step 1: Branch off main**

```bash
cd /Users/bene/.config
git switch -c zshrc-init-load-consistency
```

(Personal dotfiles repo — no Jira ticket; descriptive branch name is fine.)

- [ ] **Step 2: Replace the `:brew-init` definition (lines 143-162)**

Replace the existing `:brew-init() { … }` (everything from `:brew-init() {` through its closing `}` that currently includes the `bbd`/`bz` aliases) with:

```zsh
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
```

The existing `zi auto has"dscl" for brew` line (below `:brew-update`) is unchanged — it now fires both `:brew-init` (atinit) and `:brew-load` (atload).

- [ ] **Step 3: Syntax + sourcing check**

Run: `zsh -n /Users/bene/.config/zsh/.zshrc && echo SYNTAX-OK`
Expected: `SYNTAX-OK`

Run: `zsh -ic 'true' 2>&1 | grep -iE 'parse error|bad pattern|bad option' && echo SAW-ERRORS || echo SOURCE-CLEAN`
Expected: `SOURCE-CLEAN`

- [ ] **Step 4: Verify the alias split**

Run: `zsh -ic ':brew-load; alias bbd bz'`
Expected: `bbd='brew bundle dump -f'` and `bz='brew uninstall --zap'`

Run: `zsh -ic ':brew-init; print -r -- $HOMEBREW_BUNDLE_FILE'`
Expected: `/Users/bene/.config/Brewfile`

- [ ] **Step 5: Commit**

```bash
git add zsh/.zshrc docs/superpowers/specs docs/superpowers/plans
git commit -m "refactor(zsh): split brew aliases into :brew-load"
```

---

### Task 2: Group A — init-only blocks (new gated wait1 triggers)

**Goal:** Convert the eight config-only blocks whose contents are purely `export`/`mkdirp`/`link` into `:<name>-init` + a new `zi auto has"<cmd>" wait1 for <name>` line.

**Files:**
- Modify: `/Users/bene/.config/zsh/.zshrc` (sops, sqlite, glamour/glow, gnupg, parallel, claude, docker, ncdu blocks)

**Acceptance Criteria:**
- [ ] Each block's inline statements live in `:<name>-init`.
- [ ] Each has a new gated `wait1` trigger with the ehid matching the function prefix.
- [ ] No top-level (inline) `export`/`link` remain for these tools.
- [ ] Syntax + sourcing clean; each `:<name>-init` body sets its var/link.

**Verify:** `zsh -ic 'for f in sops sqlite glow gnupg parallel claude docker ncdu; do functions :$f-init >/dev/null && echo "$f ok"; done'` → eight `ok` lines.

**Steps:**

- [ ] **Step 1: sops block** — replace the inline `export SOPS_AGE_KEY_FILE=…` with:

```zsh
:sops-init() {
	export SOPS_AGE_KEY_FILE="${XDG_CONFIG_HOME}/sops/age/keys.txt"
}

zi auto has"sops" wait1 for sops
```

- [ ] **Step 2: sqlite block** — replace the inline `export SQLITE_HISTORY=…` with:

```zsh
:sqlite-init() {
	export SQLITE_HISTORY="${XDG_DATA_HOME}/sqlite/history"
}

zi auto has"sqlite3" wait1 for sqlite
```

- [ ] **Step 3: glamour/glow block** — replace the two inline exports with:

```zsh
:glow-init() {
	export GLAMOUR_STYLE="${HOME}/.config/glow/styles/catppuccin-mocha.json"
	export GLOW_STYLE="${GLAMOUR_STYLE}"
}

zi auto has"glow" wait1 for glow
```

- [ ] **Step 4: gnupg block** — replace the two exports + mkdirp with:

```zsh
:gnupg-init() {
	export GPG_TTY="${TTY}"
	export GNUPGHOME="${XDG_DATA_HOME}/gnupg"
	mkdirp "${GNUPGHOME}" 0700
}

zi auto has"gpg" wait1 for gnupg
```

- [ ] **Step 5: parallel block** — replace the export + mkdirp with:

```zsh
:parallel-init() {
	export PARALLEL_HOME="${XDG_CONFIG_HOME}/parallel"
	mkdirp ${PARALLEL_HOME}
}

zi auto has"parallel" wait1 for parallel
```

- [ ] **Step 6: claude block** — replace the two exports + the anonymous `() { … cp … }` function with:

```zsh
:claude-init() {
	export CLAUDE_CODE_NEW_INIT=1
	export ENABLE_CLAUDEAI_MCP_SERVERS=true

	local src="${HOME}/Library/Application Support/Claude/claude_desktop_config.json"
	local dst="${HOME}/.claude/claude_desktop_config.json"
	[[ -e ${src} && ${src} -nt ${dst} ]] && cp "${src}" "${dst}"
}

zi auto has"claude" wait1 for claude
```

- [ ] **Step 7: docker block** — replace the inline `link docker .docker` with:

```zsh
:docker-init() {
	link docker .docker
}

zi auto has"docker" wait1 for docker
```

- [ ] **Step 8: ncdu block** — replace the inline `link ncduignore .ncduignore` with:

```zsh
:ncdu-init() {
	link ncduignore .ncduignore
}

zi auto has"ncdu" wait1 for ncdu
```

- [ ] **Step 9: Syntax + sourcing check**

Run: `zsh -n /Users/bene/.config/zsh/.zshrc && echo SYNTAX-OK`
Expected: `SYNTAX-OK`

Run: `zsh -ic 'true' 2>&1 | grep -iE 'parse error|bad pattern|bad option' && echo SAW-ERRORS || echo SOURCE-CLEAN`
Expected: `SOURCE-CLEAN`

- [ ] **Step 10: Verify functions + representative bodies**

Run: `zsh -ic 'for f in sops sqlite glow gnupg parallel claude docker ncdu; do functions :$f-init >/dev/null && echo "$f ok"; done'`
Expected: eight `ok` lines.

Run: `zsh -ic ':sops-init; :gnupg-init; print -r -- $SOPS_AGE_KEY_FILE $GNUPGHOME'`
Expected: `…/sops/age/keys.txt …/gnupg`

- [ ] **Step 11: Commit**

```bash
git add zsh/.zshrc
git commit -m "refactor(zsh): wrap sops/sqlite/glow/gnupg/parallel/claude/docker/ncdu in :*-init"
```

---

### Task 3: Group A — init+load and synchronous blocks

**Goal:** Convert ansible, node, wget, youtube (gated `wait1`, with aliases → `:<name>-load`), and the two synchronous blocks less and python (generic/prerequisite env, no `wait`, python gated on `python3`).

**Files:**
- Modify: `/Users/bene/.config/zsh/.zshrc` (ansible, node, wget, youtube, less, python blocks)

**Acceptance Criteria:**
- [ ] ansible/node/wget have `:<name>-init` (exports/links) + `:<name>-load` (aliases); youtube has `:youtube-load` only.
- [ ] less + python use **synchronous** triggers (`for less` / `for python`, no `wait`); python gated on `python3`, keeping the `if has brew` libexec guard inside `:python-init`.
- [ ] `PAGER`/`EDITOR`-class generic env still set at sourcing (synchronous).
- [ ] Syntax + sourcing clean.

**Verify:** `zsh -ic 'print -r -- $PAGER; functions :python-init :ansible-load :wget-load >/dev/null && echo hooks-ok'` → a less path then `hooks-ok`.

**Steps:**

- [ ] **Step 1: ansible block** — replace the four inline `ANSIBLE_*` exports and the five aliases (`ansible-each`/`ansible-parallel`/`ad`/`ai`/`ap`) with (leave the separate `ara:` block below untouched):

```zsh
:ansible-init() {
	export ANSIBLE_HOME="${XDG_DATA_HOME}/ansible"
	export ANSIBLE_GALAXY_CACHE_DIR="${XDG_CACHE_HOME}/ansible"
	export ANSIBLE_LOCAL_TEMP="${XDG_RUNTIME_DIR}/ansible/tmp"
	export ANSIBLE_PERSISTENT_CONTROL_PATH_DIR="${XDG_RUNTIME_DIR}/ansible/cp"
}

:ansible-load() {
	alias ansible-each=':each */ansible.mk(:h) do'
	alias ansible-parallel=':parallel */ansible.mk(:h) do'

	alias ad="ansible-doc"
	alias ai="ansible-inventory"
	alias ap="ansible-playbook"
}

zi auto has"ansible" wait1 for ansible
```

- [ ] **Step 2: node/npm block** — replace the export + mkdirp + link + two aliases with:

```zsh
:node-init() {
	export NODE_REPL_HISTORY="${XDG_DATA_HOME}/node/repl_history"
	mkdirp "${XDG_DATA_HOME}/node"
	link npm/npmrc .npmrc
}

:node-load() {
	alias node-each=':each */nodejs.mk(:h) do'
	alias node-parallel=':parallel */nodejs.mk(:h) do'
}

zi auto has"node" wait1 for node
```

- [ ] **Step 3: wget block** — replace the inline export + alias with:

```zsh
:wget-init() {
	export WGETRC="${XDG_CONFIG_HOME}/wgetrc"
}

:wget-load() {
	alias wget="wget --hsts-file=\"${XDG_CACHE_HOME}/wget-hsts\""
}

zi auto has"wget" wait1 for wget
```

- [ ] **Step 4: youtube block** — replace the inline `alias yta=…` with:

```zsh
:youtube-load() {
	alias yta="yt-dlp --extract-audio --audio-format mp3 --add-metadata"
}

zi auto has"yt-dlp" wait1 for youtube
```

- [ ] **Step 5: less block** — replace the three inline statements (`export PAGER…`, `export LESSHISTFILE…`, `mkdirp`) with (note: **synchronous** trigger — `PAGER`/`LESS` are read broadly):

```zsh
:less-init() {
	export PAGER="${commands[less]}" LESS="--ignore-case --LONG-PROMPT --RAW-CONTROL-CHARS --HILITE-UNREAD --chop-long-lines --tabs=4"
	export LESSHISTFILE="${XDG_DATA_HOME}/less/history"
	mkdirp "${LESSHISTFILE:h}"
}

zi auto has"less" for less
```

- [ ] **Step 6: python block** — replace the four exports, the `if has brew; then add path …` block, and the two aliases with (gate on `python3` — gating on `python` would deadlock the libexec path that *provides* unversioned `python`; **synchronous**):

```zsh
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

:python-load() {
	alias python-each=':each */python.mk(:h) do'
	alias python-parallel=':parallel */python.mk(:h) do'
}

zi auto has"python3" for python
```

- [ ] **Step 7: Syntax + sourcing check**

Run: `zsh -n /Users/bene/.config/zsh/.zshrc && echo SYNTAX-OK`
Expected: `SYNTAX-OK`

Run: `zsh -ic 'true' 2>&1 | grep -iE 'parse error|bad pattern|bad option' && echo SAW-ERRORS || echo SOURCE-CLEAN`
Expected: `SOURCE-CLEAN`

- [ ] **Step 8: Verify synchronous env is set at sourcing + hooks exist**

Run: `zsh -ic 'print -r -- $PAGER; print -l $path | grep -q "python/libexec/bin" && echo py-path-ok'`
Expected: a path ending `/less`, then `py-path-ok` (python trigger is synchronous, so its init runs during sourcing).

Run: `zsh -ic 'functions :ansible-init :ansible-load :node-init :wget-load :youtube-load :python-init >/dev/null && echo hooks-ok'`
Expected: `hooks-ok`

- [ ] **Step 9: Commit**

```bash
git add zsh/.zshrc
git commit -m "refactor(zsh): wrap ansible/node/wget/youtube/less/python in :*-init/:*-load"
```

---

### Task 4: Group B — reuse existing trigger (no load-body interplay)

**Goal:** Add `:<name>-init` (and `:<name>-load` where aliases exist) to seven tools that already have a `zi auto … for <name>` line, reusing that line and its current timing. Includes renaming go's trigger `for golang` → `for go`, and merging ruby's brew-path `:ruby-load` into `:ruby-init`.

**Files:**
- Modify: `/Users/bene/.config/zsh/.zshrc` (mise, aws, uv, go, ruby, fzf, copier blocks)

**Acceptance Criteria:**
- [ ] mise/aws/uv/fzf gain `:<name>-init`; go gains `:go-init`+`:go-load` and its trigger becomes `for go`; ruby merges into a single `:ruby-init` (old `:ruby-load` removed); copier gains `:copier-load`.
- [ ] uv/go/ruby triggers stay **synchronous** (no `wait`); existing `:uv-eval`/`:uv-update` preserved.
- [ ] All new hook functions are defined **before** their trigger line.
- [ ] Syntax + sourcing clean; uv/go/ruby PATH entries present at sourcing.

**Verify:** `zsh -ic 'print -l $path | grep -E "uv/bin|go/bin|gem" ; functions :go-load :copier-load :aws-init :mise-init :fzf-init >/dev/null && echo hooks-ok'` → the three path lines then `hooks-ok`.

**Steps:**

- [ ] **Step 1: mise block** — keep the existing `:mise-load` and `zi auto has"mise" for mise`; move the inline `export MISE_SOPS_AGE_KEY_FILE=…` into a new `:mise-init` defined above `:mise-load`:

```zsh
:mise-init() {
	export MISE_SOPS_AGE_KEY_FILE="${XDG_CONFIG_HOME}/sops/age/keys.txt"
}

:mise-load() {
	local _mise_cmd_not_found
	eval "$(mise activate zsh)"
}

zi auto has"mise" for mise
```

- [ ] **Step 2: aws block** — move the inline `export SHOW_AWS_PROMPT=false` into `:aws-init` above the trigger:

```zsh
:aws-init() {
	export SHOW_AWS_PROMPT=false
}

zi auto has"aws" wait1 for OMZP::aws
```

- [ ] **Step 3: uv block** — move the two exports + `add path` into a new `:uv-init` above the existing `:uv-update`/`:uv-eval`; keep the trigger synchronous:

```zsh
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
```

- [ ] **Step 4: go block** — replace the inline `export GOPATH`/`add path`, the `zi auto has"go" for golang` line, and the two aliases with `:go-init`/`:go-load` and a renamed `for go` trigger:

```zsh
:go-init() {
	export GOPATH="${XDG_CACHE_HOME}/go"
	add path "${GOPATH}/bin"
}

:go-load() {
	alias go-each=':each */go.mk(:h) do'
	alias go-parallel=':parallel */go.mk(:h:a) do'
}

zi auto has"go" for go
```

- [ ] **Step 5: ruby block** — replace the five inline `GEM_*`/`BUNDLE_*` exports AND the existing `:ruby-load` (brew-ruby detection) with a single merged `:ruby-init`; keep the synchronous trigger:

```zsh
:ruby-init() {
	export GEM_HOME="${XDG_CACHE_HOME}"/gem
	export GEM_SPEC_CACHE="${XDG_CACHE_HOME}"/gem
	export BUNDLE_USER_CONFIG="${XDG_CONFIG_HOME}"/bundle
	export BUNDLE_USER_CACHE="${XDG_CACHE_HOME}"/bundle
	export BUNDLE_USER_PLUGIN="${XDG_DATA_HOME}"/bundle

	local __ruby_brew_dir=("${HOMEBREW_PREFIX}"/opt/ruby@*(N,n,On[1]))
	if [[ -n "${__ruby_brew_dir}" ]]; then
		export RUBYHOME="${__ruby_brew_dir}"
		add path "${RUBYHOME}/bin"
	fi
}

zi auto has"ruby" for ruby
```

- [ ] **Step 6: fzf block** — move the `export FZF_DEFAULT_OPTS=…` (multi-line, preserve the continuation lines and their color values verbatim) into `:fzf-init` above the trigger:

```zsh
:fzf-init() {
	export FZF_DEFAULT_OPTS=" \
	    --color=bg+:#313244,bg:#1E1E2E,spinner:#F5E0DC,hl:#F38BA8 \
	    --color=fg:#CDD6F4,header:#F38BA8,info:#CBA6F7,pointer:#F5E0DC \
	    --color=marker:#B4BEFE,fg+:#CDD6F4,prompt:#CBA6F7,hl+:#F38BA8 \
	    --color=selected-bg:#45475A \
	    --color=border:#6C7086,label:#CDD6F4"
}

zi auto has"fzf" wait1 for fzf
```

- [ ] **Step 7: copier block** — move the two aliases into a `:copier-load` defined **above** the existing `zi auto has"copier" wait1 for copier` line (reorder so the function precedes the trigger):

```zsh
:copier-load() {
	alias copier-each=':each */.copier-answers.yml(:h) do'
	alias copier-parallel=':parallel */.copier-answers.yml(:h) do'
}

zi auto has"copier" wait1 for copier
```

- [ ] **Step 8: Syntax + sourcing check**

Run: `zsh -n /Users/bene/.config/zsh/.zshrc && echo SYNTAX-OK`
Expected: `SYNTAX-OK`

Run: `zsh -ic 'true' 2>&1 | grep -iE 'parse error|bad pattern|bad option' && echo SAW-ERRORS || echo SOURCE-CLEAN`
Expected: `SOURCE-CLEAN`

- [ ] **Step 9: Verify synchronous PATH + hooks; confirm no stale `:golang-*` / old `:ruby-load`**

Run: `zsh -ic 'print -l $path | grep -E "uv/bin|go/bin|gem"'`
Expected: lines for `…/uv/bin`, `…/go/bin`, `…/gem` (uv/go/ruby init are synchronous).

Run: `zsh -ic 'functions :go-load :copier-load :aws-init :mise-init :uv-init :fzf-init :ruby-init >/dev/null && echo hooks-ok'`
Expected: `hooks-ok`

Run: `zsh -ic 'functions :ruby-load :golang-init 2>/dev/null; true' ; echo checked`
Expected: no function bodies printed for `:ruby-load`/`:golang-init` (they should not exist), then `checked`.

- [ ] **Step 10: Commit**

```bash
git add zsh/.zshrc
git commit -m "refactor(zsh): fold mise/aws/uv/go/ruby/fzf/copier env into :*-init"
```

---

### Task 5: Group B — blocks with `-load` body interplay (incl. git verification)

**Goal:** Convert opentofu, gcloud, colima, neovim — which interleave init-type and load-type statements or already have a `:<name>-load` — and add `:git-load`, verifying the `as"completion"` trigger fires atload (with a documented fallback).

**Files:**
- Modify: `/Users/bene/.config/zsh/.zshrc` (opentofu, gcloud, colima, neovim/vim, git blocks)

**Acceptance Criteria:**
- [ ] opentofu: `:opentofu-init` (cache export + mkdirp); `tf*` aliases joined into `:opentofu-load` alongside the existing `complete -C`.
- [ ] gcloud: new `:gcloud-init` (mkdirp + link); `:gcloud-load` left intact.
- [ ] colima: `:colima-init` (the four `link`/`mkdirp`); `alias colima` joined into `:colima-load` alongside `brew services start`.
- [ ] neovim: `:neovim-init` (`VIMINIT`/`EDITOR`) + `:neovim-load` (`alias vim`); synchronous trigger; `EDITOR` set at sourcing.
- [ ] git: `:git-load` holds all `g*` + `git-each`/`git-parallel` aliases, triggered by the existing completion line — OR, if atload does not fire for `as"completion"`, aliases remain inline (fallback documented in commit).
- [ ] Syntax + sourcing clean.

**Verify:** `zsh -ic 'print -r -- $EDITOR; functions :opentofu-init :colima-init :gcloud-init :neovim-init >/dev/null && echo hooks-ok'` → nvim path then `hooks-ok`.

**Steps:**

- [ ] **Step 1: opentofu block** — replace the inline `export TF_PLUGIN_CACHE_DIR`/`mkdirp`, the three `tf*` aliases, and the existing `:opentofu-load` with:

```zsh
:opentofu-init() {
	export TF_PLUGIN_CACHE_DIR="${XDG_CACHE_HOME}/opentofu/plugins"
	mkdirp "${TF_PLUGIN_CACHE_DIR}"
}

:opentofu-load() {
	alias tf="tofu"
	alias tf-each=':each */terraform.mk(:h) do'
	alias tf-parallel=':parallel */terraform.mk(:h) do'

	complete -o nospace -C tofu tofu
}

zi auto has"tofu" wait1 for opentofu
```

- [ ] **Step 2: gcloud block** — move the inline `mkdirp`/`link` (just below the `# gcloud:` header) into a new `:gcloud-init` placed above `:gcloud-update`; leave `:gcloud-update`, `:gcloud-load`, and the trigger unchanged:

```zsh
:gcloud-init() {
	mkdirp "${XDG_DATA_HOME}/gcloud"
	link "${XDG_DATA_HOME}/gcloud" "${XDG_CONFIG_HOME}/gcloud"
}
```

(Insert above the existing `:gcloud-update() { … }`. Do not modify `:gcloud-load` — its `export CLOUDSDK_HOME`/`add path` are entangled with `source …/completion.zsh.inc` and stay together as a load-time unit.)

- [ ] **Step 3: colima block** — replace the inline `link colima .colima`, the `alias colima=…`, the two `mkdirp`, the two `link`, and the existing `:colima-load` with (moving comments with their statements):

```zsh
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
```

- [ ] **Step 4: vim/neovim block** — replace the `zi auto has"nvim" for neovim` line + `alias vim=nvim` + `export VIMINIT` + `export EDITOR` with `:neovim-init`/`:neovim-load` defined above the (unchanged, synchronous) trigger:

```zsh
:neovim-init() {
	export VIMINIT="set nocp | source ${XDG_CONFIG_HOME}/vim/vimrc"
	export EDITOR="${commands[nvim]}"
}

:neovim-load() {
	alias vim=nvim
}

zi auto has"nvim" for neovim
```

- [ ] **Step 5: git block** — define `:git-load` (placed directly under the `# git:` header comments, **above** the completion `zi auto` line) containing the `git-each`/`git-parallel` aliases and all `g*`/`s` aliases; remove those aliases from top level. Leave the completion line itself unchanged:

```zsh
:git-load() {
	alias git-each=':each */.git(:h) do'
	alias git-parallel=':parallel */.git(:h) do'

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
```

- [ ] **Step 6: Syntax + sourcing check**

Run: `zsh -n /Users/bene/.config/zsh/.zshrc && echo SYNTAX-OK`
Expected: `SYNTAX-OK`

Run: `zsh -ic 'true' 2>&1 | grep -iE 'parse error|bad pattern|bad option' && echo SAW-ERRORS || echo SOURCE-CLEAN`
Expected: `SOURCE-CLEAN`

- [ ] **Step 7: Verify synchronous EDITOR + hook bodies**

Run: `zsh -ic 'print -r -- $EDITOR'`
Expected: the nvim path (neovim trigger is synchronous).

Run: `zsh -ic 'functions :opentofu-init :opentofu-load :gcloud-init :colima-init :colima-load :neovim-init :neovim-load :git-load >/dev/null && echo hooks-ok'`
Expected: `hooks-ok`

Run: `zsh -ic ':opentofu-init; print -r -- $TF_PLUGIN_CACHE_DIR'`
Expected: `…/opentofu/plugins`

- [ ] **Step 8: VERIFY the git `as"completion"` trigger fires atload (interactive)**

Open a fresh interactive shell that settles turbo, then check a git alias:

```bash
{ sleep 2; print 'alias gd && echo GIT-LOAD-FIRED || echo GIT-LOAD-MISSED'; sleep 1; print exit } | zsh -i 2>/dev/null | grep -E 'GIT-LOAD-(FIRED|MISSED)'
```

Expected: `GIT-LOAD-FIRED` (with `gd='git diff'` printed just before).

**If `GIT-LOAD-MISSED`** (atload does not fire for `as"completion"` plugins): revert Step 5 — move the git aliases back to top level (inline, as originally), delete `:git-load`. Do **not** add a second `id-as"git"` line. Record the outcome in the commit message.

- [ ] **Step 9: Commit**

```bash
git add zsh/.zshrc
git commit -m "refactor(zsh): wrap opentofu/gcloud/colima/neovim/git in :*-init/:*-load"
```

(If the git fallback was taken, append to the message: `git aliases kept inline — as\"completion\" does not fire atload`.)

---

### Task 6: Group C — rule-consistency migrations of existing hooks

**Goal:** Move statements that already live in a hook function to the *correct* hook under the rule: bat (`-load`→`-init`), eza (split), tmux (split + repoint `:tmux-update`), postgresql (`-load`→`-init`), vscode (`-load`→`-init`).

**Files:**
- Modify: `/Users/bene/.config/zsh/.zshrc` (bat, eza, tmux, postgresql, vscode blocks)

**Acceptance Criteria:**
- [ ] bat: `:bat-load` renamed to `:bat-init` (all exports).
- [ ] eza: `:eza-init` (`EZA_ICONS_AUTO`) + `:eza-load` (`l`/`lR`).
- [ ] tmux: `:tmux-init` (exports) + `:tmux-load` (`alias T`); `:tmux-update` calls `:tmux-init`.
- [ ] postgresql: `:postgresql-load` renamed to `:postgresql-init`.
- [ ] vscode: `:vscode-load` renamed to `:vscode-init`.
- [ ] atuin/direnv left unchanged (their `-load` is correctly alias-only).
- [ ] Syntax + sourcing clean.

**Verify:** `zsh -ic 'functions :bat-init :eza-init :eza-load :tmux-init :tmux-load :postgresql-init :vscode-init >/dev/null && echo hooks-ok; functions :bat-load :tmux-load 2>/dev/null | grep -q "TMUX_PLUGIN" && echo LEAKED || echo clean'` → `hooks-ok` then `clean`.

**Steps:**

- [ ] **Step 1: bat block** — rename the `:bat-load` function to `:bat-init` (body unchanged); trigger line unchanged:

```zsh
:bat-init() {
	export BAT_CONFIG_PATH="${XDG_CONFIG_HOME}"/bat/config BAT_PAGER="less"
	export MANPAGER="sh -c 'col -bx | bat -l man'" MANROFFOPT="-c"
}

zi auto has"bat" wait1 for bat
```

- [ ] **Step 2: eza block** — split `:eza-load` into `:eza-init` (export) + `:eza-load` (aliases):

```zsh
:eza-init() {
	export EZA_ICONS_AUTO=1
}

:eza-load() {
	alias l="eza --all --long --group"
	alias lR="l -R"
}

zi auto has"eza" wait1 for eza
```

- [ ] **Step 3: tmux block** — split `:tmux-load` into `:tmux-init` (exports) + `:tmux-load` (`alias T`), and repoint `:tmux-update` to call `:tmux-init`:

```zsh
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
```

(The `tmux/xpanes` block below — `zi auto has"tmux" wait1 for greymd/tmux-xpanes` — is unchanged.)

- [ ] **Step 4: postgresql block** — rename `:postgresql-load` to `:postgresql-init` (body unchanged); trigger unchanged:

```zsh
:postgresql-init() {
	local __postgresql_brew_dir=("${HOMEBREW_PREFIX}"/opt/postgresql@*(N,n,On[1]))
	if [[ -n "${__postgresql_brew_dir}" ]]; then
		add path "${__postgresql_brew_dir}/bin"
		add ldflags "-L${__postgresql_brew_dir}/lib"
		add cppflags "-I${__postgresql_brew_dir}/include"
	fi
}

zi auto has"psql" for postgresql
```

- [ ] **Step 5: vscode block** — rename `:vscode-load` to `:vscode-init` (body unchanged); trigger unchanged:

```zsh
:vscode-init() {
	if ! has "${HOME}/Library/Application Support/Code/User"; then
		return
	fi

	for i in settings keybindings mcp; do
		link "vscode/${i}.json" "Library/Application Support/Code/User/${i}.json"
	done
}

zi auto has"code" wait1 for vscode
```

- [ ] **Step 6: Syntax + sourcing check**

Run: `zsh -n /Users/bene/.config/zsh/.zshrc && echo SYNTAX-OK`
Expected: `SYNTAX-OK`

Run: `zsh -ic 'true' 2>&1 | grep -iE 'parse error|bad pattern|bad option' && echo SAW-ERRORS || echo SOURCE-CLEAN`
Expected: `SOURCE-CLEAN`

- [ ] **Step 7: Verify renames + split + no leakage**

Run: `zsh -ic 'functions :bat-init :eza-init :eza-load :tmux-init :tmux-load :postgresql-init :vscode-init >/dev/null && echo hooks-ok'`
Expected: `hooks-ok`

Run: `zsh -ic 'functions :bat-load :postgresql-load :vscode-load 2>/dev/null; true'; echo checked`
Expected: no bodies printed (old names gone), then `checked`.

Run: `zsh -ic ':tmux-init; print -r -- $TMUX_PLUGIN_MANAGER_PATH'`
Expected: `…/tmux/plugins`

- [ ] **Step 8: Commit**

```bash
git add zsh/.zshrc
git commit -m "refactor(zsh): migrate bat/eza/tmux/postgresql/vscode to correct :*-init/:*-load hooks"
```

---

### Task 7: Full verification pass

**Goal:** Confirm the whole file behaves correctly in a real interactive shell — no regressions in env, aliases, PATH, or startup performance — and that turbo triggers actually fire.

**Files:**
- (No edits expected; verification only. Fix-ups land here if a check fails.)

**Acceptance Criteria:**
- [ ] Fresh interactive shell loads with no errors or zi `id-as` collision warnings.
- [ ] A turbo-deferred env var and alias are present *after* the first prompt (proving triggers fire, not just function bodies).
- [ ] Synchronous prerequisites (`EDITOR`, `PAGER`, uv/go/ruby/gnubin PATH) present immediately.
- [ ] No inline tool `export`/`alias`/`link` remain except the intentionally-skipped blocks (ssh, ghostty, boto, ara, android, `X` alias, history, core infra).
- [ ] `zsh-bench` shows no meaningful first-prompt-lag / command-lag regression vs. `main`.

**Verify:** see steps below.

**Steps:**

- [ ] **Step 1: Clean interactive load + no id collisions**

```bash
zsh -ic 'true' 2>&1 | grep -iE 'error|collision|already.*loaded|parse|bad ' && echo SAW-ISSUES || echo CLEAN
```
Expected: `CLEAN`

- [ ] **Step 2: Turbo trigger actually fires (env + alias after first prompt)**

```bash
{ sleep 2; print 'print -r -- "SOPS=$SOPS_AGE_KEY_FILE"; alias ad'; sleep 1; print exit } | zsh -i 2>/dev/null | grep -E 'SOPS=|ad='
```
Expected: `SOPS=/Users/bene/.config/sops/age/keys.txt` and `ad='ansible-doc'` (these are `wait1` — present only because the trigger fired).

- [ ] **Step 3: Synchronous prerequisites present immediately**

```bash
zsh -ic 'print -r -- "EDITOR=$EDITOR PAGER=$PAGER"; print -l $path | grep -E "gnubin|uv/bin|go/bin|gem|python/libexec" | wc -l'
```
Expected: non-empty `EDITOR`/`PAGER`, and a PATH match count ≥ 4.

- [ ] **Step 4: Audit for stragglers** — confirm no unexpected inline tool statements remain. Review the diff for any top-level `export`/`alias`/`link` outside the allowed list:

```bash
git diff main -- zsh/.zshrc | grep -E '^\+' | grep -nE '^\+(export|alias|link|add |mkdirp)' 
```
Expected: every hit is *inside* a `:<name>-init`/`:<name>-load` function (indented with a tab), not at column 0. Manually confirm the only column-0 `export`/`alias`/`link` left in the file belong to: core infra, history, ssh, ghostty, boto, ara, android, the `X` alias.

- [ ] **Step 5: Performance check with zsh-bench**

```bash
# baseline from main
git stash --include-untracked 2>/dev/null; git switch main
zsh-bench 2>/dev/null | tee /tmp/bench-main.txt
git switch zshrc-init-load-consistency; git stash pop 2>/dev/null || true
zsh-bench 2>/dev/null | tee /tmp/bench-branch.txt
diff <(grep -E 'first_prompt_lag|command_lag' /tmp/bench-main.txt) <(grep -E 'first_prompt_lag|command_lag' /tmp/bench-branch.txt) || true
```
Expected: `first_prompt_lag_ms` and `command_lag_ms` within noise of `main` (deferral should keep them flat or slightly better; flag any regression > ~10ms for investigation).

- [ ] **Step 6: Interactive smoke (human-in-the-loop)**

Run `zre` (reloads the shell). Confirm the prompt renders, then spot-check a few real commands: `gd` (git diff), `l` (eza), `tf` (after a beat for turbo). Confirm no error spew on load.

- [ ] **Step 7: Final commit (if any fix-ups were made)**

```bash
git add -A
git commit -m "test(zsh): verify :*-init/:*-load consistency refactor" || echo "nothing to commit"
```

---

## Self-Review

**Spec coverage:** Every spec block is covered — Group A (Tasks 2-3), Group B reuse-trigger (Task 4), Group B load-interplay incl. git verification (Task 5), Group C migrations incl. the two extras postgresql/vscode (Task 6), brew template split (Task 1), full verification incl. zsh-bench and the straggler audit (Task 7). Out-of-scope blocks (ssh, ghostty, boto, ara, android, `X`, history, core infra) are explicitly checked-against in Task 7 Step 4. All five spec gotchas are encoded: python `python3` gate (Task 3 Step 6), git atload verification + fallback (Task 5 Step 8), tmux `:tmux-update` repoint (Task 6 Step 3), uv/go/ruby stay synchronous (Task 4), go `for go` rename (Task 4 Step 4).

**Placeholders:** none — every code step shows complete target code; every verify step shows an exact command and expected output.

**Consistency:** function names use the ehid that each trigger resolves (`:glow-*` for `for glow`, `:gnupg-*` for `for gnupg`, `:go-*` for the renamed `for go`, `:opentofu-*` for `for opentofu`, etc.); the cross-cutting "define hooks before the trigger line" rule is applied in every reorder (copier, git, neovim, fzf, mise, aws, uv).
</content>
