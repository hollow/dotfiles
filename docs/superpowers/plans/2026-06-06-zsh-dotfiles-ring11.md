# Ring 11 (python + uv) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers-extended-cc:subagent-driven-development (recommended) or superpowers-extended-cc:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Port the python + uv slice from `hollow/dotfiles@906b19e` into the fork — a brew-owned system Python locked to virtualenvs, per-repo versions/venvs via mise + uv, uv/uvx CLI tooling, argcomplete completion, and the Python VS Code extensions.

**Architecture:** Three non-overlapping layers (brew = system Python; mise = per-repo versions with auto-`.venv`; uv/uvx = tools + per-repo venvs), with pip confined to virtualenvs. Every added line is byte-identical to upstream `906b19e`; the new `.zshrc` section is dropped into the `brew → [here] → vscode` gap that Ring 10 left. No README change, no `:checkov-eval`, no explicit `brew "python"` (see spec deviations).

**Tech Stack:** zsh + `zi` plugin manager (`z-a-auto`/`z-a-eval` annexes), Homebrew, uv, mise, argcomplete, CPython stdlib (`readline`/`atexit`).

**Reference spec:** `docs/superpowers/specs/2026-06-06-zsh-dotfiles-ring11-design.md`

**Upstream pin:** `hollow/dotfiles@main` = `906b19e` (already fetched as `hollow/main`; `git show 906b19e:<path>` works locally).

---

### Task 1: Vendor `python/startup.py` and `pip/pip.conf`

**Goal:** Add the two new Python config files (REPL startup with a crash-proof history, and the pip require-virtualenv lockdown), byte-identical to upstream `906b19e`.

**Files:**
- Create: `python/startup.py`
- Create: `pip/pip.conf`

**Acceptance Criteria:**
- [ ] `python/startup.py` is byte-identical to `git show 906b19e:python/startup.py`.
- [ ] `pip/pip.conf` is byte-identical to `git show 906b19e:pip/pip.conf`.
- [ ] `python/startup.py` runs without error when `XDG_DATA_HOME` is unset and the history file is empty/missing (libedit crash guard).

**Verify:** `diff <(git show 906b19e:python/startup.py) python/startup.py && diff <(git show 906b19e:pip/pip.conf) pip/pip.conf && echo OK` → prints `OK` (no diff output).

**Steps:**

- [ ] **Step 1: Create `python/startup.py`.**

```python
import atexit
import os
import pathlib
import readline

history = os.path.join(
    os.getenv("XDG_DATA_HOME") or os.path.expanduser("~/.local/share"),
    "python/history",
)

readline.parse_and_bind("tab: complete")

try:
    readline.read_history_file(history)
except OSError:
    # macOS Python links readline against libedit, which returns a stale
    # errno (EPERM/EINVAL) when loading an empty or zero-entry history
    # file. Also covers the file-not-yet-created case. Never let history
    # loading crash interpreter startup.
    pass


@atexit.register
def write_history(history=history):
    pathlib.Path(os.path.dirname(history)).mkdir(parents=True, exist_ok=True)
    try:
        readline.write_history_file(history)
    except OSError:
        pass
```

- [ ] **Step 2: Create `pip/pip.conf`.**

```ini
[global]
require-virtualenv = True
```

- [ ] **Step 3: Verify byte-identity with upstream.**

Run:
```bash
diff <(git show 906b19e:python/startup.py) python/startup.py && diff <(git show 906b19e:pip/pip.conf) pip/pip.conf && echo OK
```
Expected: `OK` with no diff lines.

- [ ] **Step 4: Verify the startup file cannot crash the REPL.**

Run:
```bash
python3 -c "import os; os.environ.pop('XDG_DATA_HOME', None); exec(open('python/startup.py').read()); print('startup-ok')"
```
Expected: `startup-ok` (no traceback), even with `XDG_DATA_HOME` unset.

- [ ] **Step 5: Commit.**

```bash
git add python/startup.py pip/pip.conf
git commit -m "$(printf 'IT-8323: vendor python/startup.py and pip/pip.conf\n\nREPL history with a libedit-crash guard, and require-virtualenv pip\nlockdown. Byte-identical to hollow/dotfiles@906b19e.\n\nCo-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>')"
```

---

### Task 2: Enable mise per-repo uv venv auto-activation

**Goal:** Append the `[settings]` block to `mise/config.toml` so mise auto-creates and sources a repo's uv `.venv`, leaving brew as the global default interpreter.

**Files:**
- Modify: `mise/config.toml`

**Acceptance Criteria:**
- [ ] `mise/config.toml` has a `[settings]` table with `python.uv_venv_auto = "create|source"`.
- [ ] No `python` entry exists under `[tools]`.
- [ ] `mise/config.toml` is byte-identical to `git show 906b19e:mise/config.toml`.

**Verify:** `diff <(git show 906b19e:mise/config.toml) mise/config.toml && echo OK` → prints `OK`.

**Steps:**

- [ ] **Step 1: Append the `[settings]` block.**

The file currently is exactly:
```toml
[tools]
opentofu = "latest"
```

Append (note the leading blank line):
```toml

[settings]
# uv owns per-repo virtualenvs: in a uv project (uv.lock present) mise auto-creates
# and sources the .venv. Per-repo python versions are declared per project
# (.python-version or [tools] python = "..."); brew stays the global default.
python.uv_venv_auto = "create|source"
```

- [ ] **Step 2: Verify byte-identity with upstream.**

Run:
```bash
diff <(git show 906b19e:mise/config.toml) mise/config.toml && echo OK
```
Expected: `OK`.

- [ ] **Step 3: Verify no global python tool was added.**

Run:
```bash
awk '/^\[tools\]/{t=1;next} /^\[/{t=0} t' mise/config.toml | grep -E '^python' && echo "FAIL: global python present" || echo "OK: no global python"
```
Expected: `OK: no global python`.

- [ ] **Step 4: Commit.**

```bash
git add mise/config.toml
git commit -m "$(printf 'IT-8323: enable mise per-repo uv venv auto-activation\n\nAdd [settings] python.uv_venv_auto = "create|source"; no global python\ntool. Byte-identical to hollow/dotfiles@906b19e.\n\nCo-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>')"
```

---

### Task 3: Add ruff + uv brews and the Python VS Code extensions to the Brewfile

**Goal:** Add `brew "ruff"`, `brew "uv"`, and the 7 Python/uv VS Code extensions in alphabetically-sorted positions — all byte-identical upstream lines; do **not** add `brew "python"`.

**Files:**
- Modify: `Brewfile`

**Acceptance Criteria:**
- [ ] `brew "ruff"` sits between `brew "rsync"` and `brew "sops"`.
- [ ] `brew "uv"` sits between `brew "tmux"` and `brew "watch"`.
- [ ] `brew "python"` is **absent**.
- [ ] These 7 `vscode` lines are present, alphabetically placed: `charliermarsh.ruff` (after `catppuccin.catppuccin-vsc-pack`), `ms-python.debugpy`, `ms-python.isort`, `ms-python.python`, `ms-python.vscode-pylance`, `ms-python.vscode-python-envs` (after `mkhl.shfmt`), `the0807.uv-toolkit` (after `tamasfe.even-better-toml`).
- [ ] Every line added in this task exists verbatim in `git show 906b19e:Brewfile`.
- [ ] `brew bundle list --file=./Brewfile --all` parses without error.

**Verify:**
```bash
comm -23 <(git diff -- Brewfile | sed -n 's/^+//p' | grep -vE '^\+\+' | sort -u) <(git show 906b19e:Brewfile | sort -u)
```
→ empty output (every added line exists upstream).

**Steps:**

- [ ] **Step 1: Add the two brews.**

Insert `brew "ruff"` immediately after the `brew "rsync"` line:
```ruby
brew "rsync"
brew "ruff"
brew "sops"
```

Insert `brew "uv"` immediately after the `brew "tmux"` line:
```ruby
brew "tmux"
brew "uv"
brew "watch"
```

- [ ] **Step 2: Add `charliermarsh.ruff`** immediately after `vscode "catppuccin.catppuccin-vsc-pack"`:
```ruby
vscode "catppuccin.catppuccin-vsc-pack"
vscode "charliermarsh.ruff"
vscode "davidanson.vscode-markdownlint"
```

- [ ] **Step 3: Add the five `ms-python.*` extensions** immediately after `vscode "mkhl.shfmt"`:
```ruby
vscode "mkhl.shfmt"
vscode "ms-python.debugpy"
vscode "ms-python.isort"
vscode "ms-python.python"
vscode "ms-python.vscode-pylance"
vscode "ms-python.vscode-python-envs"
vscode "redhat.vscode-yaml"
```

- [ ] **Step 4: Add `the0807.uv-toolkit`** immediately after `vscode "tamasfe.even-better-toml"`:
```ruby
vscode "tamasfe.even-better-toml"
vscode "the0807.uv-toolkit"
vscode "timonwong.shellcheck"
```

- [ ] **Step 5: Verify every added line is an upstream line and `python` was not added.**

Run:
```bash
comm -23 <(git diff -- Brewfile | sed -n 's/^+//p' | grep -vE '^\+\+' | sort -u) <(git show 906b19e:Brewfile | sort -u)
grep -q '^brew "python"$' Brewfile && echo "FAIL: brew python present" || echo "OK: no brew python"
```
Expected: first command prints nothing; second prints `OK: no brew python`.

- [ ] **Step 6: Verify the Brewfile parses.**

Run:
```bash
brew bundle list --file=./Brewfile --all >/dev/null && echo "OK: parses"
```
Expected: `OK: parses` (lists all entries without a parse error).

- [ ] **Step 7: Commit.**

```bash
git add Brewfile
git commit -m "$(printf 'IT-8323: add ruff + uv brews and Python VS Code extensions\n\nAll byte-identical to hollow/dotfiles@906b19e; no explicit brew python\n(python@3.14 is pulled in transitively by openssh + git-delete-merged-branches).\n\nCo-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>')"
```

---

### Task 4: Add the python → uv → argcomplete `.zshrc` section

**Goal:** Insert the contiguous `python → uv → argcomplete` block into `zsh/.zshrc`, between the `brew` block and the `vscode` block. The uv + argcomplete sub-blocks are byte-identical to upstream `906b19e`; the python core sub-block carries two fork deviations — no `python-each`/`python-parallel` aliases, and the `opt/python/libexec/bin` PATH addition is guarded by `has brew` (macOS/brew only).

**Files:**
- Modify: `zsh/.zshrc` (insert after `zi auto has"dscl" for brew`, before `# vscode: visual studio code editor`)

**Acceptance Criteria:**
- [ ] The `python → uv → argcomplete` block sits immediately after the brew block and immediately before the vscode block. The uv + argcomplete sub-blocks are byte-identical to upstream; the python core sub-block matches the deviated form in Step 1 (no `python-each`/`python-parallel`; `add path …/opt/python/libexec/bin` wrapped in `if has brew; then … fi`).
- [ ] `zsh -n zsh/.zshrc` passes.
- [ ] The only fork-only non-blank lines vs upstream are exactly three: the guard comment, `if has brew; then`, and the now-indented `add path …/opt/python/libexec/bin` (`fi` already exists upstream).
- [ ] In a fresh shell: `PYTHONHOME` unset; `PYTHONSTARTUP`/`PIP_REQUIRE_VIRTUALENV=1`/`PYTHONNOUSERSITE=1` exported; `python3` resolves under `${HOMEBREW_PREFIX}`.

**Verify:**
```bash
diff <(git show 906b19e:zsh/.zshrc | sed -n '/^# python\/uv: an extremely fast/,/^zi auto with"uv" for argcomplete/p') \
     <(sed -n '/^# python\/uv: an extremely fast/,/^zi auto with"uv" for argcomplete/p' zsh/.zshrc) && echo OK
```
→ prints `OK` (the uv + argcomplete sub-blocks match upstream exactly; the python core sub-block deviates per Step 1).

**Steps:**

- [ ] **Step 1: Insert the block.**

In `zsh/.zshrc`, the brew block ends with:
```zsh
zi auto has"dscl" for brew

# vscode: visual studio code editor
```

Insert the following between `zi auto has"dscl" for brew` and the `# vscode:` comment (i.e. replace the single blank line that separates them with: blank line, the block, blank line):

```zsh
zi auto has"dscl" for brew

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

# vscode: visual studio code editor
```

- [ ] **Step 2: Verify the uv + argcomplete sub-blocks match upstream byte-for-byte.**

Run:
```bash
diff <(git show 906b19e:zsh/.zshrc | sed -n '/^# python\/uv: an extremely fast/,/^zi auto with"uv" for argcomplete/p') \
     <(sed -n '/^# python\/uv: an extremely fast/,/^zi auto with"uv" for argcomplete/p' zsh/.zshrc) && echo OK
```
Expected: `OK` (these two sub-blocks are unmodified from upstream).

- [ ] **Step 3: Verify syntax and that the only fork-only lines are the `has brew` guard.**

Run:
```bash
zsh -n zsh/.zshrc && echo "syntax-ok"
comm -23 <(grep -vE '^[[:space:]]*$' zsh/.zshrc | sort -u) <(git show 906b19e:zsh/.zshrc | grep -vE '^[[:space:]]*$' | sort -u)
```
Expected: `syntax-ok`, then the second command prints **only** these three fork-only lines from Deviation 5: the comment `# expose brew's unversioned python/pip shims on PATH (macOS/brew only)`, `if has brew; then`, and the now-indented `    add path "${HOMEBREW_PREFIX}/opt/python/libexec/bin"` (upstream has it unindented). `fi` does **not** appear — it already exists elsewhere in upstream's `.zshrc`. No other fork-only lines.

- [ ] **Step 4: Verify the environment in a fresh shell.**

Run:
```bash
zsh -ic 'echo home=${PYTHONHOME:-unset}; echo startup=$PYTHONSTARTUP; echo rv=$PIP_REQUIRE_VIRTUALENV nus=$PYTHONNOUSERSITE; command -v python3'
```
Expected: `home=unset`, `startup=…/python/startup.py`, `rv=1 nus=1`, and a `${HOMEBREW_PREFIX}/…/python3` path.

- [ ] **Step 5: Commit.**

```bash
git add zsh/.zshrc
git commit -m "$(printf 'IT-8323: add python/uv/argcomplete zshrc section\n\nBrew-owned system python (libexec/bin on PATH, PYTHONHOME unset, pip\nconfined to venvs), uv tool dirs + completion, and uv-installed\nargcomplete with the fzf-tab IFS fix. Byte-identical to\nhollow/dotfiles@906b19e; inserted between the brew and vscode blocks.\n\nCo-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>')"
```

---

### Task 5: End-to-end install + completion check

**Goal:** Install the new packages and confirm the wired-up toolchain works in a fresh shell — uv/uvx on PATH, pip refuses a non-venv install, unversioned `python`/`pip` resolve, and the argcomplete global completer is defined.

**Files:** _(none — verification only)_

**Acceptance Criteria:**
- [ ] `brew bundle install --file=./Brewfile` installs `uv` and `ruff` (and the VS Code extensions if `code` is available) without error.
- [ ] In a fresh shell, `uvx --version` works and `register-python-argcomplete` resolves under `${UV_TOOL_BIN_DIR}` (`~/.cache/uv/bin`).
- [ ] `_python_argcomplete_global` is a defined function in a fresh interactive shell.
- [ ] `pip install --dry-run requests` outside a virtualenv is refused (require-virtualenv).
- [ ] `command -v python` and `command -v pip` resolve under `${HOMEBREW_PREFIX}/opt/python/libexec/bin`.

**Verify:**
```bash
zsh -ic 'command -v uvx >/dev/null && echo uvx-ok; command -v register-python-argcomplete; print "glob=${+functions[_python_argcomplete_global]}"; command -v python; command -v pip'
```
→ `uvx-ok`, a `~/.cache/uv/bin/register-python-argcomplete` path, `glob=1`, and `python`/`pip` under `…/opt/python/libexec/bin`.

**Steps:**

- [ ] **Step 1: Install the new packages.**

Run:
```bash
brew bundle install --file=./Brewfile
```
Expected: completes without error; `uv` and `ruff` are installed (this also installs the `with"uv"` argcomplete tool on first `zi update`/new shell).

- [ ] **Step 2: Confirm pip refuses a system install.**

Run:
```bash
zsh -ic 'pip install --dry-run requests' 2>&1 | grep -i virtualenv
```
Expected: a non-empty match — a "Could not find an activated virtualenv (required)." line.

- [ ] **Step 3: Confirm uv, argcomplete, and the python shims in a fresh shell.**

Run:
```bash
zsh -ic 'command -v uvx >/dev/null && echo uvx-ok; command -v register-python-argcomplete; print "glob=${+functions[_python_argcomplete_global]}"; command -v python; command -v pip'
```
Expected: `uvx-ok`; `register-python-argcomplete` under `~/.cache/uv/bin`; `glob=1`; `python`/`pip` under `${HOMEBREW_PREFIX}/opt/python/libexec/bin`.

If `glob=0` (the eval ran before the completion system was ready), open one more fresh shell and re-check — the `z-a-eval` cache is populated on first load and the `compdef` is replayed by the existing `zicompinit; zicdreplay` atinit. Record the observed result.

- [ ] **Step 4: No commit.**

This task changes no tracked files. If `brew bundle install` rewrote `Brewfile.lock.json` or similar, discard it (the repo sets `HOMEBREW_BUNDLE_NO_LOCK=1`, so no lock file should appear).

---

## Self-Review

**Spec coverage:** Spec §A (python/startup.py, pip/pip.conf)→Task 1; §B (mise [settings])→Task 2; §C (ruff/uv brews + 7 vscode extensions)→Task 3; §D (.zshrc block)→Task 4; Verification/smoke section→Tasks 1–5 Verify blocks + Task 5 end-to-end. Deviations: no README (no task — intentional); no `:checkov-eval` (the ported block omits it; Task 4 verify diffs the uv→argcomplete range, which contains no checkov); no `brew "python"` (Task 3 AC asserts absence); python core sub-block drops `python-each`/`python-parallel` and guards the `opt/python/libexec/bin` PATH addition with `has brew` (Task 4 Step 1 + Deviations 4–5). All covered.

**Placeholder scan:** No TBD/TODO; every code/command step shows concrete content and expected output.

**Type/name consistency:** `906b19e`, `:uv-eval`/`:uv-update`, `UV_TOOL_BIN_DIR` (`~/.cache/uv/bin`), `:argcomplete-eval`, `_python_argcomplete_global`, `python.uv_venv_auto`, and the sorted Brewfile/extension positions are used consistently across tasks and match the spec.
