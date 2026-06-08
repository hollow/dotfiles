# zshrc `:*-init` / `:*-load` consistency — design

Date: 2026-06-08
Status: approved (pending spec review)

## Goal

Make every per-tool configuration block in `zsh/.zshrc` follow one uniform
shape, modeled on `:brew-init`: the block's statements live in `:<name>-*`
hook functions that the `z-a-auto` annex (`zi auto … for <name>`) invokes,
instead of running inline at top level. This replaces the current mix of
"some tools use hook functions, most dump statements inline."

Secondary outcome (a deliberate consequence of the chosen trigger model):
tool configuration that is only relevant once the tool is used becomes
**lazy/turbo-deferred**, gated on the tool actually being installed.

## How `z-a-auto` wires hooks (recap)

`zi auto … for <name>` resolves an "ehid" (the `id-as`, else the last path
component of the plugin spec) and registers annex hooks that fire by name:

- `:<name>-init` → **atinit** (before the plugin body is sourced)
- `:<name>-load` → **atload** (after the plugin body is sourced)
- `:<name>-eval` → added as an `eval'…'` ice (cached eval output)
- `:<name>-update` → **atclone/atpull** (install/update time)

A bare name (no user, no `::`) resolves to the `z-shell/null` plugin, so
`zi auto … for brew` loads nothing — it exists solely to fire `:brew-*`
hooks. `has"<cmd>"` gates the whole load on a command existing; `wait`/`wait1`
turbo-defers it to just after the first prompt. `.zshrc` is sourced for
**interactive** shells only, so turbo-deferral never affects scripts.

## The classification rule (init vs load)

The single rule applied to every converted block:

- **`:<name>-init` — "prepare the environment"** (atinit): `export`,
  `add path` / `add fpath` / `add ldflags` / `add cppflags`, `mkdirp`,
  `link`, and other side-effecting filesystem setup.
  Rationale: these are *prerequisites* other code depends on — e.g. uv's
  `add path` at atinit is exactly what later `has"checkov" wait1` plugins
  rely on to find their binaries.
- **`:<name>-load` — "wire up the loaded tool"** (atload): `alias`,
  `complete -C` / completion setup, `zstyle`, `source`, and anything that
  needs the command actually present.
  Rationale: aliases and friends have no dependents; they are pure
  interactive sugar, correct to run after the tool's own body.
- **`:<name>-eval`** is left untouched (cached eval output).

This rule is applied **uniformly, including to `:brew-init` itself**:
brew's `bbd`/`bz` aliases move out of `:brew-init` into a new `:brew-load`.

## Trigger-timing rule (sync vs turbo)

For **new** trigger lines:

- **Tool-only env → `wait1` (turbo, gated):** state that only matters once
  you invoke the tool. `zi auto has"<cmd>" wait1 for <name>`.
- **Generic / prerequisite env → synchronous (gated, no `wait`):** values the
  shell or other tools read broadly, or PATH entries other plugins depend on.
  `zi auto has"<cmd>" for <name>`.

For tools that **already** have a `zi auto … for <name>` line, the new
functions reuse that line and inherit its existing timing — we do **not**
change whether a tool is sync or turbo.

## Scope — per-block plan

### Group A — new gated trigger + new functions (currently fully inline)

| Block | New trigger | `:<name>-init` (init) | `:<name>-load` (load) |
|---|---|---|---|
| ansible | `has"ansible" wait1 for ansible` | `ANSIBLE_*` exports | `ad`/`ai`/`ap`, `ansible-each`/`-parallel` |
| claude | `has"claude" wait1 for claude` | `CLAUDE_CODE_*` exports + desktop-config copy fn | — |
| glow | `has"glow" wait1 for glow` | `GLAMOUR_STYLE`, `GLOW_STYLE` | — |
| gnupg | `has"gpg" wait1 for gnupg` | `GPG_TTY`, `GNUPGHOME` + mkdirp | — |
| node | `has"node" wait1 for node` | `NODE_REPL_HISTORY` + mkdirp + link npmrc | `node-each`/`-parallel` |
| parallel | `has"parallel" wait1 for parallel` | `PARALLEL_HOME` + mkdirp | — |
| sops | `has"sops" wait1 for sops` | `SOPS_AGE_KEY_FILE` | — |
| sqlite | `has"sqlite3" wait1 for sqlite` | `SQLITE_HISTORY` | — |
| wget | `has"wget" wait1 for wget` | `WGETRC` | `wget` alias |
| youtube | `has"yt-dlp" wait1 for youtube` | — | `yta` alias |
| docker | `has"docker" wait1 for docker` | `link docker .docker` | — |
| ncdu | `has"ncdu" wait1 for ncdu` | `link ncduignore .ncduignore` | — |
| python | `has"python3" for python` (sync, see gotcha) | `PYTHONSTARTUP`, `PIP_*`, `PYTHONNOUSERSITE` + `if has brew` libexec `add path` | `python-each`/`-parallel` |
| less | `has"less" for less` (sync — generic `PAGER`) | `PAGER`, `LESS`, `LESSHISTFILE` + mkdirp | — |

Note: `MANPAGER`/`MANROFFOPT` currently live in `:bat-load`, not the less
block — they stay with bat (see Group C). The less block's own contents are
`PAGER`, `LESS`, `LESSHISTFILE` + its mkdirp.

### Group B — reuse existing trigger, add/move functions

| Block | Existing trigger | Change |
|---|---|---|
| mise | `has"mise" for mise` (sync) | add `:mise-init` (`MISE_SOPS_AGE_KEY_FILE`); keep `:mise-load` |
| aws | `has"aws" wait1 for OMZP::aws` | add `:aws-init` (`SHOW_AWS_PROMPT`) |
| uv | `has"uv" for uv` (sync) | add `:uv-init` (`UV_TOOL_DIR`/`UV_TOOL_BIN_DIR` + `add path`); keep `:uv-eval`/`:uv-update` |
| go | rename `for golang` → `has"go" for go` | add `:go-init` (`GOPATH` + `add path`) + `:go-load` (`go-each`/`-parallel`) |
| ruby | `has"ruby" for ruby` (sync) | merge GEM/BUNDLE exports **and** the brew-ruby `RUBYHOME`/`add path` (currently `:ruby-load`) into one `:ruby-init`; drop `:ruby-load` |
| opentofu | `has"tofu" wait1 for opentofu` | add `:opentofu-init` (`TF_PLUGIN_CACHE_DIR` + mkdirp); move `tf`/`tf-each`/`-parallel` into `:opentofu-load` (joins existing `complete -C`) |
| gcloud | `has"gcloud" wait1 for gcloud` | add `:gcloud-init` (inline mkdirp + link); keep `:gcloud-load` intact |
| colima | `has"colima" wait1 for colima` | add `:colima-init` (the four `link`/`mkdirp`); move `alias colima` into `:colima-load` (joins `brew services start`) |
| fzf | `has"fzf" wait1 for fzf` | add `:fzf-init` (`FZF_DEFAULT_OPTS`) |
| copier | `has"copier" wait1 for copier` | add `:copier-load` (`copier-each`/`-parallel`) |
| neovim | `has"nvim" for neovim` (sync) | add `:neovim-init` (`EDITOR`, `VIMINIT`) + `:neovim-load` (`alias vim`) |
| git | `id-as"git" as"completion" … wait1` | add `:git-load` (all `g*` + `git-each`/`-parallel` aliases) — **verify** atload fires for an `as"completion"` plugin (see gotcha) |

### Group C — rule-consistency migrations (already wrapped, wrong hook)

These already live in a function but the statement type says they belong in a
different hook under the rule. The named-five from brainstorming plus two more
the rule clearly implicates:

| Block | Change |
|---|---|
| bat | `:bat-load` (all exports incl. `MANPAGER`/`MANROFFOPT`) → rename to `:bat-init` |
| eza | split `:eza-load` → `:eza-init` (`EZA_ICONS_AUTO`) + `:eza-load` (`l`, `lR`) |
| tmux | split `:tmux-load` → `:tmux-init` (`TMUX_PLUGIN_MANAGER_PATH`, `ZSH_TMUX_*`) + `:tmux-load` (`alias T`); repoint `:tmux-update` to call `:tmux-init` |
| postgresql | `:postgresql-load` is all `add path`/`ldflags`/`cppflags` → rename to `:postgresql-init` |
| vscode | `:vscode-load` is all `link` → rename to `:vscode-init` |

`atuin` and `direnv` need **no change**: their `-load` already holds only an
alias, which is the correct hook.

### Out of scope (left exactly as-is)

- **Core/global infra:** locale/term/`setopt`/`ulimit`, the `mkdirp` helper,
  system `PATH`, XDG dirs + their mkdirps, zsh `fpath`/paths, the early
  Homebrew `shellenv` inline block, `LDFLAGS`/`CPPFLAGS` decl, ZI bootstrap,
  `zre`/`zx`, `zup`, the annex/`default-ice`/`eval`/`auto` loads, the OMZL
  loads, the `cd` aliases, **history** config (HISTSIZE/HISTFILE/link — must
  be synchronous for the session).
- **ssh** — `SSH_AUTH_SOCK` (1Password agent) and the config symlink/chmod
  stay synchronous; deferring the auth sock would break git-over-ssh in the
  first prompt. Untouched.
- **ghostty** — `add path "${GHOSTTY_BIN_DIR}"` is conditioned on an env var
  the terminal sets, not on a command; the `has"<cmd>"` model doesn't fit.
  Untouched.
- **boto, ara, android, the `X` alias** — explicitly left as-is per
  brainstorming.
- **YSU, starship, completion/fzf-tab/F-Sy-H/autosuggestions/autopair config,
  zsh-bench, `.envrc` loader** — plugin/prompt/completion infra, not tool env
  blocks. Untouched.

## Gotchas / special handling

1. **python — no `has"python"` gate (deadlock).** The brew
   `python/libexec/bin` path the block adds is what *provides* the unversioned
   `python`. Gating on `python` would prevent the path from ever being added.
   Gate on **`python3`** (Homebrew's `python3` is already on `PATH` via the
   early `brew shellenv` block, independent of the libexec dir), and keep the
   `if has brew` guard *inside* `:python-init` for the libexec `add path`.
   Synchronous trigger (no `wait1`) — minor, keeps the unversioned `python`
   shim available immediately.

2. **git — verify `as"completion"` fires atload.** `:git-load` relies on the
   existing completion line's atload hook running. Confirm during
   implementation (e.g. `alias gd` present after first prompt). **Fallback if
   it does not fire:** leave the git aliases inline rather than introduce a
   second `id-as"git"` line (id collision risk). Document whichever path is
   taken.

3. **tmux `:tmux-update` dependency.** It calls `:tmux-load` today to obtain
   `TMUX_PLUGIN_MANAGER_PATH`; after the split that export lives in
   `:tmux-init`, so repoint the call.

4. **uv / go / ruby stay synchronous.** Their existing trigger lines have no
   `wait` and must keep it: uv's `add path` must precede the `wait1`
   uv-installed-tool plugins; go/ruby `PATH` should be available immediately.

5. **go ehid.** `for golang` currently resolves ehid `golang` and fires no
   hooks at all (none exist). Rename the trigger to `for go` so the ehid is
   `go` and the functions read `:go-init`/`:go-load` and actually fire.

6. **claude desktop-config copy.** The anonymous `cp` becomes part of
   `:claude-init`; it now runs gated on `has"claude"` and turbo-deferred
   instead of unconditionally at sourcing. Acceptable — it only mirrors
   Claude Desktop's config into `~/.claude`.

## Behavior changes (accepted)

- Group A `wait1` blocks set their env/aliases **just after the first prompt**
  instead of during sourcing, and **only if the tool is installed**. Approved
  in brainstorming. Generic env (`PAGER` via less, `EDITOR` via neovim) and
  prerequisite `PATH` (uv/go/ruby/python) deliberately stay synchronous.
- Tool env becomes **conditional on the binary existing**. For all blocks here
  the env is meaningless without the tool, so this is desirable.

## Verification plan

1. `zre` (`exec zsh`) in an interactive shell — no errors, no zi
   duplicate-`id-as` warnings.
2. After the first prompt, spot-check turbo blocks:
   `print -r -- $ANSIBLE_HOME $SOPS_AGE_KEY_FILE $NODE_REPL_HISTORY` and
   `alias ad ai ap tf l T yta gd`.
3. Confirm prerequisite `PATH` synchronously present at startup:
   `print -l $path | grep -E 'gnubin|uv/bin|go/bin|gem'`.
4. Confirm `EDITOR`/`PAGER` set: `print -r -- $EDITOR $PAGER`.
5. git fallback decision (gotcha 2): confirm `:git-load` fired or document the
   inline fallback.
6. `zsh-bench` before/after to confirm no first-prompt-lag or
   command-lag regression.
</content>
</invoke>
