# Remerge dotfiles — Ring 14 (sync 93b9788 → c8a74a6) design

**Date:** 2026-06-08
**Status:** Approved (design); ready for implementation planning
**Repo:** <https://github.com/remerge/dotfiles>
**Builds on:** Rings 0–13 (merged) plus the `IT-8323-install-existing-setups`
work — see `docs/superpowers/specs/2026-06-08-zsh-dotfiles-ring13-design.md`
**Upstream pin:** `hollow/dotfiles@main` at commit `c8a74a6`
(`refactor(zsh): convert ssh section to the zi auto :ssh-init convention`),
advanced from Ring 13's pin `93b9788`.

## Goal

Sync the fork forward over the **15 upstream commits** `93b9788..c8a74a6` in a
**single ring**. Unlike a tool-slice ring, this window is dominated by a
file-wide structural refactor of `zsh/.zshrc` (fold-region markers on every
section, an init/bootstrap consolidation, the `js/*` split, the `ssh` →
`:ssh-init` convention) plus two feature slices (bun/biome; per-language VSCode
format-on-save). The changes are entangled — the fold-marker refactor touches
every section including the new `js/*` ones — so they ship together and land on
a state byte-identical to `c8a74a6` for every section/tool the fork carries (with
the single documented `claude`-section exception, Deviation 6).

Upstream window (`git log 93b9788..c8a74a6`):

| Commit | Subject | Fork disposition |
|---|---|---|
| `eca2fae` | feat(js): add bun and biome support | **port** |
| `965b0ab` | Add VSCode extensions for bun/biome | **port** |
| `5460ada` | feat(vscode): wire up format-on-save per language | **port** |
| `4ab43f7` | feat(vscode): add go and ruby formatters | **port** (full go support, see §D) |
| `2b90a15` | feat(vscode): add opentofu and hcl formatters | **port** |
| `16c7bcc` | refactor(zsh): simplify postgres brew path | **port** (new section, see §A5) |
| `c3074e4` | style(zsh): add fold-region markers to every section | **port** (carried sections) |
| `88d0604` | refactor(zsh): consolidate and fold the init/bootstrap section | **port** (see §A1) |
| `e8db4a4` | refactor(zsh): namespace boto under aws/boto | **N/A** — fork has no aws/boto |
| `69029b3` | refactor(zsh): namespace completion sections under zsh/completion | **port** (carried sections) |
| `b6380b2` | refactor(zsh): move the X ssh shortcut to an autoloaded zsh/X function | **skip** — personal (see Deviation 1) |
| `c8a74a6` | refactor(zsh): convert ssh section to the zi auto :ssh-init convention | **port** (see §A4) |

Merge commits `38fa6c1`, `255c63d`, `a8b2aad` carry no additional tree changes.

## Scope (decided)

Curation calls confirmed with the maintainer:

- **Adopt bun + biome** (js tooling).
- **Adopt ruby** — add `brew "ruby"` and the ruby VSCode tooling (reverses Ring
  13 Deviation 2, which omitted `brew "ruby"` only because upstream `93b9788`
  also omitted it; `c8a74a6` now carries it).
- **Introduce postgres** — the fork has no postgres section today; add it
  byte-identical to `c8a74a6`.
- **Full go VSCode support** — add the `golang.go` extension and
  `go.useLanguageServer` so the new `[go]` formatter block and `gopls` config are
  coherent (the fork carries neither today).

Precondition (verified): the fork's `zsh/.zshrc` is byte-identical to
`93b9788` for every section it carries, so the `93b9788..c8a74a6` diff applies
to the fork's subset without drift.

### A. `zsh/.zshrc` — structural sync

Each carried section ends up byte-identical to `c8a74a6:zsh/.zshrc` (the sole
exception is the `claude` section — see Deviation 6). Sections the fork does not
carry (see Deviation 3) are absent and receive no treatment.

#### A1. Init/bootstrap consolidation + fold (`# region init`)

The top of the file is rewritten to upstream's consolidated `# region init …
# endregion` block. Net moves relative to the fork's current top:

- Every leading comment is reworded to upstream's new wording (locale,
  truecolor, `extendedglob`, `ulimit`, `select-word-style`).
- The inline `mkdirp() { … }` **function definition is removed** from `.zshrc`
  and extracted to a new autoloaded file `zsh/mkdirp` (§B).
- The **homebrew `brew shellenv` block moves up**, immediately after the system
  `PATH` array, and switches from `has /opt/homebrew/bin/brew` + `add path …` to
  `[[ -x /opt/homebrew/bin/brew ]]` + inline `path=("${HOMEBREW_PREFIX}/bin"
  "${HOMEBREW_PREFIX}/sbin" ${path[@]})`. (`/opt/homebrew` hardcoding is
  preserved — Apple-Silicon-only, no Intel fallback.)
- The compiler-flags `typeset -TUx LDFLAGS … / CPPFLAGS …` lines **move up** into
  the init region (right after the homebrew block).
- `${HOMEBREW_PREFIX}/share/zsh/site-functions` is **folded directly into the
  `fpath` array** (the old homebrew block's `add fpath …` is removed).
- All `mkdirp` calls (XDG dirs + zsh dirs) **move to after the autoload line**,
  so the autoloaded `mkdirp` is defined before first use.
- `add path "${HOME}/.local/bin"` **moves from the top to the very end of the
  file** (new trailing comment: `# add local bin last so user binaries take
  precedence over tool/brew paths`).

Target init region (byte-identical to `c8a74a6`, tabs as in the file):

```zsh
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
```

And at the very end of the file:

```zsh
# add local bin last so user binaries take precedence over tool/brew paths
add path "${HOME}/.local/bin"
```

#### A2. Fold-region markers + section renames

Every carried section is wrapped in `# region <name>` / `# endregion`, with
upstream's renames where they changed the header text. For the fork's carried
sections this includes:

- `# node/npm:` → `# js/node:` (then split, §A3)
- the completion-cluster headers → `# zsh/completion: …` (the `zsh-completions`,
  `fzf-tab`, the `matcher-list`/`completer`/`git`/`make` `zstyle` blocks, and the
  `bashcompinit` block all become `zsh/completion`)
- `# zsh-you-should-use:` → `# zsh/you-should-use:`
- `# starship:` → `# zsh/starship:`
- `# zsh/f-sy-h:`, `# zsh/autosuggestions:`, `# zsh/autopair:` already carry the
  `zsh/` prefix; they gain markers only.

This is the bulk of the line count and is mechanical, but each carried section
must equal `c8a74a6`'s version of that section.

#### A3. js split (node → js/node + js/npm + js/bun + js/biome)

The current single `node/npm` block becomes four sections. `link npm/npmrc
.npmrc` moves out of `:node-init` into a new `:npm-init`. New `js/bun` and
`js/biome` sections are added. Target (byte-identical to `c8a74a6`):

```zsh
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
```

#### A4. ssh → `:ssh-init` convention

The `ssh` section is rewrapped: its `mkdirp`/`link`/`chmod`-drift logic and the
1Password-agent-socket selection move inside a single `:ssh-init()` function,
followed by `zi auto has"ssh" for ssh`. Target (byte-identical to `c8a74a6`):

```zsh
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
```

#### A5. postgres (new section)

Insert a new `postgresql` section between `parallel` and `rsync` (both carried),
byte-identical to `c8a74a6`'s simplified form:

```zsh
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
```

> Note (carried verbatim from upstream): upstream's path is the unversioned
> `opt/postgres`, while the Brewfile formula is `postgresql@18`. We port the line
> byte-identical to `c8a74a6` rather than second-guessing upstream; the section
> is guarded by `has"psql"`, so it is inert until `psql` is on `PATH`.

#### A6. ruby (markers only)

The fork already carries the `ruby` section byte-identical to upstream; it gains
`# region`/`# endregion` markers only. Its supporting `brew "ruby"` lands in §C.

### B. `zsh/mkdirp` — new autoloaded file

Created byte-identical to `c8a74a6:zsh/mkdirp`:

```zsh
#!zsh

# create a directory only when missing, so a warm shell forks no external mkdir
# here (each fork is ~8ms on macOS; a cold shell still does the work once). the
# optional second arg is the mode, applied atomically at creation for dirs that
# must not be group/world-accessible
[[ -d $1 ]] || mkdir -p ${2:+-m$2} $1
```

It is picked up by the existing `autoload -Uz ${ZDOTDIR}/*(.N:t)` line.

### C. `Brewfile`

New lines, byte-identical to upstream, each placed at upstream's **relative
position** (per the Ring-13 lesson: follow upstream placement, not
fork-alphabetical):

- `brew "biome"` — between `brew "bat"` and `brew "bottom"`.
- `brew "bun"` — between `brew "bottom"` and `brew "ccusage"`.
- `brew "gofumpt"` then `brew "gopls"` — between `brew "go"` and `brew
  "graphviz"` (upstream interleaves `googleworkspace-cli` between them; the fork
  does not carry it, so the two land adjacent, in order).
- `brew "postgresql@18", link: true` — between `brew "poppler"` and `brew
  "pre-commit"`.
- `brew "ruby"` — between `brew "rsync"` and `brew "ruff"`.

New VSCode extensions (the `vscode` block is alphabetical, matching upstream):

- `vscode "biomejs.biome"` — after `bierner.markdown-preview-github-styles`.
- `vscode "golang.go"` — after `fredwangwang.vscode-hcl-format`, before
  `grapecity.gc-excelviewer` (go-support decision; line byte-identical to
  upstream).
- `vscode "oven.bun-vscode"` — after `opentofu.vscode-opentofu`.
- `vscode "shopify.ruby-lsp"` — after `sharat.vscode-brewfile`.
- `vscode "sorbet.sorbet-vscode-extension"` — after `sleistner.vscode-fileutils`.

### D. `vscode/settings.json`

The fork's `settings.json` is a curated subset that deliberately omits a set of
upstream keys (`ansible.*`, `files.associations`, `makefile.configureOnOpen`,
the `window.*` and `workbench.*` UI prefs, `yaml.customTags`). This ring
preserves those omissions and adds **only the formatter-feature keys** from the
`93b9788..c8a74a6` diff, each byte-identical to `c8a74a6`'s value, in its correct
alphabetical slot:

- The per-language formatter blocks: `[css]`, `[go]`, `[hcl]`, `[html]`,
  `[javascript]`, `[json]`, `[jsonc]`, `[markdown]`, `[opentofu]`,
  `[opentofu-vars]`, `[python]`, `[ruby]`, `[shellscript]`, `[typescript]`,
  `[yaml]`. (`[ignore]` already exists.)
- `editor.codeActionsOnSave` (biome / ruff / rumdl / shellcheck / opentofu) —
  between `csv-preview.resizeColumns` and `editor.fontFamily`.
- `go.useLanguageServer: true` and `gopls: { "formatting.gofumpt": true }` —
  between `files.trimTrailingWhitespace` and `markdown.extension.toc.levels`
  (go-support decision).
- `json.schemaDownload.trustedDomains` — same alphabetical neighbourhood, after
  `gopls`.

All referenced formatters resolve to extensions the fork carries or adds this
ring: biome, `golang.go`, `fredwangwang.vscode-hcl-format`,
`opentofu.vscode-opentofu`, `charliermarsh.ruff`, `Shopify.ruby-lsp`,
`mkhl.shfmt`, `rvben.rumdl`, `redhat.vscode-yaml`.

## Deviations (documented)

1. **`zsh/X` skipped.** Upstream `b6380b2` extracts a personal `X` shell
   shortcut (`ssh -t 10.0.0.11 …`) into an autoloaded `zsh/X` function. The fork
   never carried the `alias X` and the target host is a personal box, so neither
   the alias removal nor the new file applies — nothing to do, no `zsh/X`
   created.
2. **`aws/boto` namespacing N/A.** Upstream `e8db4a4` renames a `boto` section to
   `aws/boto` and moves it under `aws`. The fork carries neither an `aws` nor a
   `boto` section, so there is nothing to rename or move.
3. **Curated-subset sections stay absent.** The fork carries 55 of upstream's 70
   `.zshrc` regions. The **15** regions it does not carry are not introduced (no
   marker/rename treatment): `android`, `ansible`, `ansible/ara`, `atuin`, `aws`,
   `aws/boto`, `checkov`, `consul`, `direnv`, `nomad`, `sqlite`, `sshp`,
   `tmux/xpanes`, `youtube`, `zsh/bench`. The trailing `# Load .envrc …` block is
   likewise absent. (`postgresql` was the 16th absent region but is **introduced**
   this ring — see §A5.)
4. **VSCode curation preserved.** `settings.json` keeps its existing omissions
   (Deviation list above); only formatter-feature keys are added.
5. **No README change.** Consistent with every prior ring — the fork's README
   documents no per-tool sections.
6. **`claude` section keeps its fork deviation.** The fork's `:claude-init`
   deliberately omits upstream's `claude_desktop_config.json` sync (the three
   lines `local src=… / local dst=… / [[ -e ${src} && ${src} -nt ${dst} ]] && cp
   …`). `c8a74a6` still carries them (unchanged in this window bar markers). This
   ring **preserves the fork's omission** — the conservative default is to not
   silently reintroduce something the fork deliberately removed. The `claude`
   region therefore equals `c8a74a6`'s **minus** those three lines; it is the one
   carried section that is not byte-identical to upstream.

Apart from the `claude` deviation above, there are **no line-level deviations**
inside any ported section: every other carried `.zshrc` section, the `zsh/mkdirp`
file, each new `Brewfile` line, and each added `settings.json` key is
byte-identical to `c8a74a6`. (Verified: `diff 93b9788 ↔ fork@HEAD` shows only
whole-section deletions plus the single `claude` intra-section hunk.)

## Dependency analysis

- **`mkdirp` ordering is safe.** Moving `mkdirp` from an inline function to an
  autoloaded `zsh/mkdirp` works because all `mkdirp` calls now sit *after* the
  `autoload -Uz ${ZDOTDIR}/*(.N:t)` line, so the function is defined before first
  use. The file is regular and lowercase, so the existing autoload glob picks it
  up exactly like `add`, `has`, `link`.
- **homebrew-block relocation is load-order-neutral for the fork.** It still runs
  in the init region before any tool section; `HOMEBREW_PREFIX` is set before the
  `fpath` array references `${HOMEBREW_PREFIX}/share/zsh/site-functions` and
  before any `${HOMEBREW_PREFIX}/opt/*` use (ruby, postgres).
- **`.local/bin` last** changes precedence so user binaries win over brew/tool
  paths — intended upstream behaviour, adopted verbatim.
- **All new sections are `has`-guarded** (`has"bun"`, `has"biome"`, `has"npm"`,
  `has"psql"`, `has"ssh"`), so they are inert until their binary is on `PATH`;
  adding them together with their `Brewfile` lines is safe (no-op until `brew
  bundle` installs the tools).
- **`:ssh-init` is `has"ssh"`-guarded**; `ssh` is always present on macOS, so the
  section runs as before — only its structure changed (function body vs.
  top-level), preserving the config-mode-drift `chmod` and agent-socket logic.
- **Fold markers and renames are comments only** — no runtime effect.
- **VSCode go support**: `[go]` + `gopls.formatting.gofumpt` require
  `go.useLanguageServer` + the `golang.go` extension + the `gopls`/`gofumpt`
  binaries; all four are added this ring, so go formatting is coherent rather
  than referencing an absent extension.

## File inventory

### Create

- `docs/superpowers/specs/2026-06-08-zsh-dotfiles-ring14-design.md` (this file).
- `docs/superpowers/plans/2026-06-08-zsh-dotfiles-ring14.md` (+ `.tasks.json`).
- `zsh/mkdirp` — autoloaded helper (§B).

### Modify

- `zsh/.zshrc` — §A1–A6: init consolidation, fold markers + renames on carried
  sections, js split, ssh `:ssh-init`, new postgres section, ruby markers,
  `.local/bin` moved to end.
- `Brewfile` — §C: 5 `brew` lines + 5 `vscode` extension lines.
- `vscode/settings.json` — §D: formatter-feature keys.

## Path mapping

- `.zshrc` / `zsh/mkdirp` edits live in `~/.config/zsh/` (already linked).
- `Brewfile` brews/casks/extensions installed by `brew bundle`.
- `vscode/settings.json` → linked to VSCode's `User/settings.json` by the
  existing `:vscode-init`.

## Verification

- **Per-section byte-identity:** for every carried section, the fork's
  `zsh/.zshrc` span diffs clean against the same `# region …`/`# endregion` span
  of `git show c8a74a6:zsh/.zshrc`. Spot-checked spans: the `# region init`
  block, `js/node`+`js/npm`+`js/bun`+`js/biome`, `ssh`, `postgresql`, and the
  `zsh/completion` cluster. The **`claude`** region is the one expected
  difference — it must equal `c8a74a6`'s `claude` region with the three
  `claude_desktop_config.json` sync lines removed (Deviation 6).
- **`claude` deviation preserved:** `grep -c 'claude_desktop_config.json'
  zsh/.zshrc` → `0`.
- **`zsh/mkdirp`:** `diff <(git show c8a74a6:zsh/mkdirp) zsh/mkdirp` is empty.
- **No stray personal artifacts:** `grep -c 'alias X' zsh/.zshrc` → `0`; no
  `zsh/X` file; no `aws`/`boto` section introduced.
- **`.local/bin` moved:** `add path "${HOME}/.local/bin"` appears exactly once,
  as the final content of the file (after the last carried section,
  `zsh/autopair`), not in the init region. The fork carries neither the upstream
  `zsh-bench` section nor the trailing `.envrc` block (Deviation 3), so
  `.local/bin` is the file's last line.
- **`Brewfile`:** the 5 new brews appear at the relative positions in §C and the
  5 `vscode` lines in their alphabetical slots; each byte-identical to
  `c8a74a6`; `brew bundle list --file=./Brewfile --all` parses.
- **`vscode/settings.json`:** valid JSON; the added keys equal `c8a74a6`'s
  values; the fork's previously-omitted keys remain absent.
- **Syntax:** `zsh -n zsh/.zshrc` passes; `zsh -n zsh/mkdirp` passes.
- **Smoke-test caveat:** the live `~/.config` on this machine tracks
  `hollow@main`, not the fork branch, so a full interactive `zsh -ic` smoke test
  of the branch is not meaningful here — byte-identity to the already-shipped
  upstream commit `c8a74a6` is the primary guarantee (same caveat as recent
  rings).

## Acceptance criteria

- `zsh/.zshrc`: every carried section is byte-identical to `c8a74a6` (except the
  `claude` region — Deviation 6), including the consolidated `# region init`
  block (homebrew block moved up, `mkdirp` extracted, compiler flags up,
  site-functions folded into `fpath`, `mkdirp` calls after autoload), the
  `js/node`+`js/npm`+`js/bun`+`js/biome` split, the `:ssh-init` ssh section, the
  new `postgresql` section between `parallel` and `rsync`, fold markers + renames
  on all carried sections, and `add path "${HOME}/.local/bin"` as the file's
  final line. The `claude` region carries fold markers but keeps the fork's
  omission of the `claude_desktop_config.json` sync (`grep -c
  'claude_desktop_config.json' zsh/.zshrc` → `0`).
- `zsh/mkdirp` exists and is byte-identical to `c8a74a6:zsh/mkdirp`.
- `Brewfile`: contains `biome`, `bun`, `gofumpt`, `gopls`, `postgresql@18`
  (`link: true`), `ruby`, and the `biomejs.biome`, `golang.go`,
  `oven.bun-vscode`, `shopify.ruby-lsp`, `sorbet.sorbet-vscode-extension`
  extensions — each byte-identical to upstream and at the positions in §C; `brew
  bundle list --all` parses.
- `vscode/settings.json`: valid JSON with the §D formatter keys added
  (byte-identical values, correct slots) and the fork's existing omissions
  preserved.
- `zsh -n zsh/.zshrc` and `zsh -n zsh/mkdirp` pass.
- The only deviations are Deviations 1–6; every ported line is byte-identical to
  `c8a74a6` except the `claude` region's three omitted sync lines (Deviation 6).
- `LICENSE` and all prior-ring files are unchanged except the `zsh/.zshrc`,
  `zsh/mkdirp`, `Brewfile`, and `vscode/settings.json` edits described here.
