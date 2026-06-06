# Remerge dotfiles — Ring 11 (python + uv) design

**Date:** 2026-06-06
**Status:** Approved (design); ready for implementation planning
**Repo:** <https://github.com/remerge/dotfiles>
**Builds on:** Rings 0–10 (merged) — see
`docs/superpowers/specs/2026-06-05-zsh-dotfiles-ring10-design.md`
**Upstream pin:** `hollow/dotfiles@main` at commit `906b19e` (advanced from
Ring 10's `cef10b6`)

## Goal

Port the **python + uv** tool slice from upstream: a brew-owned system Python
locked down so only `brew` ever writes to it, per-repo Python versions/venvs via
mise + uv, all standalone Python CLIs via uv/uvx, and tab completion for
argparse programs via a uv-installed argcomplete. This adds the contiguous
`python → uv → argcomplete` section to `.zshrc` — the exact gap Ring 10's
`vscode` section was documented to sit above — plus the supporting config files,
Brewfile entries, and the Python VS Code extensions.

Upstream assembled this slice across commits `d1fbaff` (python/uv/mise/argparse
integration), `1a2e765` (REPL history crash fix), `43a9226` (mise `[settings]`),
and `906b19e` (PATH-based `python`/`pip` instead of aliases). This ring ports
the **final** state at `906b19e`.

## Mental model — three non-overlapping layers

1. **brew = system Python.** `python3`/`pip3` resolve via `brew shellenv`;
   `${HOMEBREW_PREFIX}/opt/python/libexec/bin` is added to `PATH` so the
   unversioned `python`/`pip` resolve too (in scripts and env-spawned processes,
   not just interactive command resolution). `PYTHONHOME` is deliberately never
   set. Read-only to everything but `brew`.
2. **mise = per-repo Python versions.** A repo declares its version
   (`.python-version` or `mise.toml`); with `python.uv_venv_auto = "create|source"`
   mise auto-creates and sources the repo's uv `.venv`. No global Python is
   registered with mise.
3. **uv / uvx = everything else.** Standalone CLI tools (`uv tool install` /
   `uvx`) under `~/.cache/uv`, and per-repo virtualenvs.

The guard rails (`pip.conf` + env vars) make layer 1 effectively read-only to
anything but `brew`.

## Scope (decided)

### A. New config files

- **`python/startup.py`** (mode `100644`) — `PYTHONSTARTUP` target. Loads REPL
  history from `${XDG_DATA_HOME:-~/.local/share}/python/history`, binds tab
  completion, and guards both the history read and write with `try/except
  OSError`. The guard is required on macOS: Python links `readline` against
  `libedit`, which returns a stale errno (EPERM/EINVAL) when loading an empty or
  zero-entry history file and would otherwise crash interpreter startup; it also
  subsumes the file-not-yet-created case. Byte-identical to upstream `906b19e`.

- **`pip/pip.conf`** (mode `100644`) — `[global]` / `require-virtualenv = True`.
  The repo *is* `~/.config`, so this file lives at `~/.config/pip/pip.conf` with
  no symlink needed (same model as `bat/config`, `git/config`). The exported
  `PIP_REQUIRE_VIRTUALENV=1` (see §D) is the authoritative guard regardless of
  whether pip reads the XDG path on a given platform; `pip.conf` is
  belt-and-suspenders. Byte-identical to upstream.

### B. `mise/config.toml`

Append a `[settings]` block (the `[tools]` table is unchanged — the fork already
matches upstream's post-`43a9226` `opentofu`-only tools list):

```toml

[settings]
# uv owns per-repo virtualenvs: in a uv project (uv.lock present) mise auto-creates
# and sources the .venv. Per-repo python versions are declared per project
# (.python-version or [tools] python = "..."); brew stays the global default.
python.uv_venv_auto = "create|source"
```

No global `python` entry under `[tools]`. Byte-identical to upstream.

### C. `Brewfile`

All added lines are **byte-identical upstream lines** (present at `906b19e`),
so the Brewfile stays a strict subset of upstream — no Brewfile deviation
(unlike Ring 10).

- **Brews (2), alphabetically:**
  - `brew "ruff"` — after `brew "rsync"`, before `brew "sops"`.
  - `brew "uv"` — after `brew "tmux"`, before `brew "watch"`.
  - **Not** `brew "python"` — see Deviation 3.
- **VS Code extensions (7), alphabetically into the existing `vscode` block:**
  - `charliermarsh.ruff` — after `catppuccin.catppuccin-vsc-pack`.
  - `ms-python.debugpy`, `ms-python.isort`, `ms-python.python`,
    `ms-python.vscode-pylance`, `ms-python.vscode-python-envs` — after
    `mkhl.shfmt`, before `redhat.vscode-yaml`.
  - `the0807.uv-toolkit` — after `tamasfe.even-better-toml`, before
    `timonwong.shellcheck`.

### D. `.zshrc` python → uv → argcomplete section

Inserted between the existing `brew` block (after `zi auto has"dscl" for brew`)
and the `# vscode` block — restoring upstream's
`brew → python → uv → argcomplete → vscode` order (Ring 10's spec explicitly
noted vscode sat directly after brew only because this group was un-ported).

The **uv** and **argcomplete** sub-blocks are byte-identical to upstream. The
**python core** sub-block carries two intentional fork deviations (Deviations
4–5): the `python-each`/`python-parallel` aliases are dropped, and the
`opt/python/libexec/bin` PATH addition is guarded by `has brew` so it only
applies on macOS/brew (on Linux `HOMEBREW_PREFIX` is unset, which would
otherwise prepend a bogus `/opt/python/libexec/bin`). `has brew` is the existing
macOS/brew idiom used by `:brew-update` and `:gcloud-load`.

```zsh
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
```

## Deviations (documented)

1. **No README change.** Upstream rewrote its `README.md` "Python" section; the
   fork's README documents no per-tool sections (none of the mise, gcloud,
   opentofu, or sops rings added one), so a Python section would be out of place.
   Deliberate, consistent with every prior tool ring.
2. **No `:checkov-eval`.** Upstream's `d1fbaff` also rerouted `:checkov-eval`
   through `:register-python-argcomplete`. `checkov` is not in the fork, so its
   block is not ported; the generic `:register-python-argcomplete` helper *is*
   ported (it has no checkov dependency) and is ready for a future checkov ring.
3. **No `brew "python"` — relies on transitive `python@3.14`.** The
   `add path "${HOMEBREW_PREFIX}/opt/python/libexec/bin"` line needs the
   unversioned `opt/python` symlink, which exists only when Homebrew's current
   default `python@3.x` is installed. `ruff` and `uv` are dependency-free Rust
   binaries and do **not** provide it; instead `python@3.14` is pulled in
   transitively by `openssh` and `git-delete-merged-branches` (both already in
   the Brewfile), and installing the current-default `python@3.x` creates the
   unversioned `opt/python` alias link. The `add` helper does not prune missing
   dirs, so a dangling path is harmless (no error). Trade-off accepted: the
   Brewfile stays minimal at the cost of an implicit dependency — if those
   formulae ever drop their `python` dependency, the unversioned `python`/`pip`
   shims silently stop resolving (`python3`/`pip3` and venv tooling are
   unaffected).
4. **`python-each`/`python-parallel` aliases dropped.** Upstream defines
   `alias python-each=':each */python.mk(:h) do'` and the `python-parallel`
   mirror (the python analogues of the `tf-each`/`tf-parallel` opentofu
   aliases). The fork omits them — they drive a `python.mk`-per-directory
   convention not used here. Trivially re-added in a later ring if wanted.
5. **`opt/python/libexec/bin` PATH addition guarded by `has brew`.** Upstream
   adds it unconditionally; the fork wraps it in `if has brew; then … fi` so it
   applies on macOS/brew only. On the best-effort Linux path `HOMEBREW_PREFIX`
   is unset, and an unconditional `add path` would prepend a bogus
   `/opt/python/libexec/bin`. `has brew` is the same macOS/brew idiom used by
   `:brew-update` and `:gcloud-load`.

Deviations 4–5 mean the **python core** sub-block is no longer byte-identical to
upstream; the **uv** and **argcomplete** sub-blocks remain byte-identical.

## Dependency analysis

- **`zi auto has"uv" for uv`** — guarded by `has"uv"`; loads only once `uv` is on
  `PATH` (installed by `brew "uv"`). Runs the `:uv-eval` (completion, cached by
  the `z-a-eval` annex) and `:uv-update` (run by `zup`) hooks via the existing
  `z-a-auto` convention — same pattern as `bat`, `duf`, `eza`, etc.
- **`zi auto with"uv" for argcomplete`** — the `with"uv"` annex installs
  `argcomplete` as a uv tool (providing `register-python-argcomplete` and
  `activate-global-python-argcomplete` on `UV_TOOL_BIN_DIR`). `with"…"` is already
  used in the fork (opentofu uses `with"mise"`). `:argcomplete-eval` emits the
  zsh global completer; the `compdef … -default-` it ends with is replayed by the
  existing `zicompinit; zicdreplay` atinit on the F-Sy-H load.
- **`UV_TOOL_BIN_DIR` on `PATH`** — `~/.cache/uv/bin`, prepended via `add path`,
  so uv-installed tools win over brew.
- **No new helpers.** `add`, `has`, `link`, the `z-a-auto`/`z-a-eval` annexes,
  and the `:tool-load`/`:tool-eval`/`:tool-update` hook convention all predate
  this ring.
- **`python/startup.py`** is plain CPython stdlib (`atexit`, `os`, `pathlib`,
  `readline`); no third-party imports, safe to `exec` even outside a REPL.

## File inventory

### Create
- `python/startup.py` (mode `100644`) — byte-identical to upstream `906b19e`.
- `pip/pip.conf` (mode `100644`) — byte-identical to upstream.
- `docs/superpowers/specs/2026-06-06-zsh-dotfiles-ring11-design.md` (this file).
- `docs/superpowers/plans/2026-06-06-zsh-dotfiles-ring11.md` (+ `.tasks.json`).

### Modify
- `Brewfile` — `brew "ruff"`, `brew "uv"`, and 7 `vscode "…"` lines (all
  byte-identical upstream lines, placed in sorted position).
- `mise/config.toml` — append the `[settings]` block.
- `zsh/.zshrc` — insert the python → uv → argcomplete section between the `brew`
  and `vscode` blocks.

## Path mapping

- `python/startup.py` → `~/.config/python/startup.py`, referenced by
  `PYTHONSTARTUP`.
- `pip/pip.conf` → `~/.config/pip/pip.conf` (read directly; no symlink).
- `mise/config.toml` → `~/.config/mise/config.toml` (already linked).
- The `.zshrc` section lives in `~/.config/zsh/.zshrc` (already linked).
- `brew "ruff"`, `brew "uv"`, and the 7 extensions → installed by `brew bundle`.

## Verification

- **`Brewfile`:** every added `brew`/`vscode` line is byte-identical to an
  upstream `906b19e` line (`comm -23` of the added lines against upstream's
  Brewfile is empty); `brew bundle list --file=./Brewfile --all` parses;
  `brew "python"` is absent.
- **`mise/config.toml`:** `[settings]` present with
  `python.uv_venv_auto = "create|source"`; no `python` under `[tools]`; the file
  equals upstream's `906b19e` `mise/config.toml`.
- **`python/startup.py` / `pip/pip.conf`:** byte-identical to upstream; both mode
  `100644`. `python3 -c "import os; os.environ.pop('XDG_DATA_HOME', None);
  exec(open('python/startup.py').read()); print('ok')"` prints `ok` (survives
  unset `XDG_DATA_HOME` and an empty/missing history file).
- **`zsh/.zshrc`:** the **uv** and **argcomplete** sub-blocks (from
  `# python/uv:` through `zi auto with"uv" for argcomplete`) diff clean against
  upstream `906b19e`; the **python core** sub-block matches the deviated form in
  §D (no `python-each`/`python-parallel`; `add path …/opt/python/libexec/bin`
  wrapped in `if has brew; then … fi`); `zsh -n zsh/.zshrc` passes. The `.zshrc`
  is no longer a strict line-subset of upstream — the only fork-only non-blank
  lines are exactly three: the guard comment, `if has brew; then`, and the
  now-indented `add path …/opt/python/libexec/bin` (`fi` already exists
  elsewhere upstream).
- **Fresh-shell smoke test (observed, on this machine):**
  - `zsh -ic 'echo home=${PYTHONHOME:-unset}; echo startup=$PYTHONSTARTUP; echo
    rv=$PIP_REQUIRE_VIRTUALENV nus=$PYTHONNOUSERSITE; command -v python3'` →
    `home=unset`, a startup path, `rv=1 nus=1`, a `${HOMEBREW_PREFIX}` python3.
  - `command -v python` and `command -v pip` resolve under
    `${HOMEBREW_PREFIX}/opt/python/libexec/bin`.
  - `pip install --dry-run requests` outside a venv is refused
    (require-virtualenv).
  - After `brew bundle install`, `uvx --version` works and
    `register-python-argcomplete` is on `PATH` under `${UV_TOOL_BIN_DIR}`;
    `_python_argcomplete_global` is defined in a fresh interactive shell.

## Acceptance criteria

- `Brewfile` contains `brew "ruff"` and `brew "uv"` (sorted positions) and the 7
  Python/uv `vscode` extensions (sorted positions), all byte-identical upstream
  lines; `brew "python"` is **not** added; `brew bundle list --all` parses.
- `python/startup.py` and `pip/pip.conf` exist (mode `100644`), byte-identical to
  upstream `906b19e`.
- `mise/config.toml` has the `[settings]` `python.uv_venv_auto = "create|source"`
  block and no global `python` tool.
- `zsh/.zshrc` has the python → uv → argcomplete section between the `brew` and
  `vscode` blocks; `zsh -n` passes. The uv + argcomplete sub-blocks are
  byte-identical to upstream; the python core sub-block carries Deviations 4–5
  (no `python-each`/`python-parallel` aliases; `add path …/opt/python/libexec/bin`
  guarded by `has brew`).
- No README change; no `:checkov-eval` block; the python core sub-block deviates
  per Deviations 4–5.
- `LICENSE` and all prior-ring files are unchanged except the `Brewfile`,
  `mise/config.toml`, and `zsh/.zshrc` edits and the two new config files
  described here.
