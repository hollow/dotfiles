# Python / uv / mise / argparse Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers-extended-cc:subagent-driven-development (recommended) or superpowers-extended-cc:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reactivate and fix the Python tooling in the zsh config so Homebrew owns the system Python (read-only to anything but `brew`), per-repo versions come from mise + uv, all Python CLIs are uv/uvx based, and argparse programs get tab completion again.

**Architecture:** Three non-overlapping layers — (1) brew = system `python3`/`pip` (on PATH via `brew shellenv`, no `PYTHONHOME`); (2) mise = per-repo Python versions with auto-`.venv` activation; (3) uv/uvx = all CLI tools and per-repo venvs. pip is confined to virtualenvs and the per-user site is disabled, so nothing but `brew` writes to the brew interpreter. argcomplete moves from a brew formula to a uv tool and registers zsh global completion.

**Tech Stack:** zsh + `zi` plugin manager (with the local `z-a-auto`/eval annexes), Homebrew, uv 0.11.x, mise 2026.4.x, argcomplete 3.x.

**Reference spec:** `docs/superpowers/specs/2026-06-05-python-uv-mise-integration-design.md`

**Verified environment facts (probed during planning):**
- `python3` → `/opt/homebrew/bin/python3` (3.14.4); `uv`/`uvx` → `/opt/homebrew/bin` (0.11.7); `mise` 2026.4.20.
- `register-python-argcomplete` currently → brew formula `python-argcomplete` 3.6.3 (Brewfile:43).
- `register-python-argcomplete --shell zsh <tool>` emits a native `#compdef` zsh function.
- `activate-global-python-argcomplete --dest=-` emits a zsh global completer ending in `compdef _python_argcomplete_global -default-` (replayed by the existing `zicompinit; zicdreplay` at zshrc:671).
- `python.uv_venv_auto = "create|source"` is accepted by the installed mise.
- `UV_TOOL_BIN_DIR=/Users/bene/.cache/uv/bin` is prepended to PATH (zshrc:218), so uv tools win over brew.

---

### Task 1: Reactivate Python core block and lock the system interpreter

**Goal:** Restore `PYTHONSTARTUP`, remove the dead `PYTHONHOME`/`OMZP::python` lines, add guards that prevent pip/user-site writes to the brew Python, and harden `python/startup.py`.

**Files:**
- Modify: `zsh/.zshrc:196-211` (python core block)
- Modify: `python/startup.py:6` (XDG fallback)

**Acceptance Criteria:**
- [ ] In a fresh shell, `command -v python3` is under `${HOMEBREW_PREFIX}` and `PYTHONHOME` is unset.
- [ ] `PYTHONSTARTUP`, `PIP_REQUIRE_VIRTUALENV=1`, `PIP_USER=0`, `PYTHONNOUSERSITE=1` are exported.
- [ ] `pip install requests` outside a virtualenv is refused.
- [ ] No `:python-load` function and no `OMZP::python` line remain.
- [ ] `python/startup.py` does not crash when `XDG_DATA_HOME` is unset.

**Verify:**
```
zsh -ic 'echo home=${PYTHONHOME:-unset}; echo startup=$PYTHONSTARTUP; echo rv=$PIP_REQUIRE_VIRTUALENV nus=$PYTHONNOUSERSITE; command -v python3'
```
Expected: `home=unset`, a `startup=` path, `rv=1 nus=1`, and a `/opt/homebrew/...python3` path.

**Steps:**

- [ ] **Step 1: Replace the python core block in `zsh/.zshrc`.**

Replace lines 196-211 (the current block reproduced below):

```zsh
# python: programming language
# https://docs.python.org/3/
#export PYTHONSTARTUP="${XDG_CONFIG_HOME}/python/startup.py"

#:python-load() {
#    local __python_brew_dir=("${HOMEBREW_PREFIX}"/opt/python@*(N,n,On[1]))
#    if [[ -n "${__python_brew_dir}" ]]; then
#        export PYTHONHOME="${__python_brew_dir}"
#        add path "${PYTHONHOME}/libexec/bin"
#    fi
#}

#zi auto has"python3" silent for OMZP::python

alias python-each=':each */python.mk(:h) do'
alias python-parallel=':parallel */python.mk(:h) do'
```

with:

```zsh
# python: programming language
# https://docs.python.org/3/
# brew owns the system python (on PATH via `brew shellenv`). PYTHONHOME is
# deliberately left unset so mise/uv-managed venvs are never overridden.
# Per-repo python versions come from mise, per-repo venvs from uv.
export PYTHONSTARTUP="${XDG_CONFIG_HOME}/python/startup.py"

# never let anything but `brew` write to the system python: confine pip to
# virtualenvs and disable the per-user site (no ~/.local/lib/pythonX clutter).
export PIP_REQUIRE_VIRTUALENV=1
export PIP_USER=0
export PYTHONNOUSERSITE=1

alias python-each=':each */python.mk(:h) do'
alias python-parallel=':parallel */python.mk(:h) do'
```

- [ ] **Step 2: Harden `python/startup.py`.**

Replace line 6:

```python
history = os.path.join(os.getenv("XDG_DATA_HOME"), "python/history")
```

with:

```python
history = os.path.join(
    os.getenv("XDG_DATA_HOME") or os.path.expanduser("~/.local/share"),
    "python/history",
)
```

- [ ] **Step 3: Verify the interpreter, guards, and startup file.**

Run:
```
zsh -ic 'echo home=${PYTHONHOME:-unset}; echo startup=$PYTHONSTARTUP; echo rv=$PIP_REQUIRE_VIRTUALENV nus=$PYTHONNOUSERSITE; command -v python3'
python3 -c "import os; os.environ.pop('XDG_DATA_HOME', None); exec(open('python/startup.py').read()); print('startup-ok')"
```
Expected: `home=unset`, `startup=/Users/bene/.config/python/startup.py`, `rv=1 nus=1`, `/opt/homebrew/bin/python3`, then `startup-ok`.

- [ ] **Step 4: Verify pip refuses a system install.**

Run:
```
zsh -ic 'pip install --dry-run requests' 2>&1 | grep -i virtualenv
```
Expected: a "Could not find an activated virtualenv (required)." line (non-empty match).

- [ ] **Step 5: Commit.**

```bash
git add zsh/.zshrc python/startup.py
git commit -m "Reactivate python startup, drop PYTHONHOME, lock system pip"
```

---

### Task 2: Move argcomplete to uv and wire zsh global + per-tool completion

**Goal:** Replace the brew `python-argcomplete` formula with a uv-installed `argcomplete`, register argcomplete's zsh global completer via the eval annex, and fix the broken `:checkov-eval` shell flag.

**Files:**
- Modify: `zsh/.zshrc:230-242` (argcomplete block)
- Modify: `zsh/.zshrc:326-328` (`:checkov-eval`)
- Modify: `Brewfile:43` (remove `python-argcomplete`)

**Acceptance Criteria:**
- [ ] `python-argcomplete` is no longer in `Brewfile`.
- [ ] After `uv tool install argcomplete`, `register-python-argcomplete` resolves to `${UV_TOOL_BIN_DIR}` (`~/.cache/uv/bin`), not `/opt/homebrew/bin`.
- [ ] zshrc declares `zi auto with"uv" for argcomplete` and an `:argcomplete-eval` running `activate-global-python-argcomplete --dest=-`.
- [ ] `:checkov-eval` calls `register-python-argcomplete --shell zsh checkov`.
- [ ] In a fresh shell, the `_python_argcomplete_global` function is defined.

**Verify:**
```
zsh -ic 'command -v register-python-argcomplete; print "fn=${+functions[_python_argcomplete_global]}"'
```
Expected: a `/Users/bene/.cache/uv/bin/register-python-argcomplete` path and `fn=1`.

**Steps:**

- [ ] **Step 1: Install argcomplete as a uv tool and remove the brew formula.**

```bash
uv tool install argcomplete
brew uninstall python-argcomplete
command -v register-python-argcomplete
```
Expected last line: `/Users/bene/.cache/uv/bin/register-python-argcomplete` (open a new shell if the old brew path is still cached).

- [ ] **Step 2: Remove `python-argcomplete` from `Brewfile`.**

Delete this line (Brewfile:43):

```ruby
brew "python-argcomplete"
```

- [ ] **Step 3: Replace the argcomplete block in `zsh/.zshrc`.**

Replace lines 230-242 (current commented block):

```zsh
# python/argcomplete: completion for python programs
# https://github.com/kislyuk/argcomplete#readme
#:argcomplete-load() {
#    local __argcomplete_brew_dir=("${HOMEBREW_PREFIX}"/Cellar/python-argcomplete/*(N,n,On[1]))
#    if [[ -n "${__argcomplete_brew_dir}" ]]; then
#        local __argcomplete_python_dir=(${__argcomplete_brew_dir}/libexec/lib/python*(N,n,On[1]))
#        if [[ -n "${__argcomplete_python_dir}" ]]; then
#            add fpath ${__argcomplete_python_dir}/site-packages/argcomplete/bash_completion.d
#        fi
#    fi
#}

#zi auto has"register-python-argcomplete" for argcomplete
```

with:

```zsh
# python/argcomplete: tab completion for argparse-based programs, installed via uv
# https://github.com/kislyuk/argcomplete#readme
# :argcomplete-eval emits the zsh global completer; the eval annex sources it and
# the `compdef _python_argcomplete_global -default-` call is replayed by zicdreplay.
:argcomplete-eval() {
    activate-global-python-argcomplete --dest=-
}

zi auto with"uv" for argcomplete
```

- [ ] **Step 4: Fix `:checkov-eval` to emit zsh completion.**

Replace line 328:

```zsh
    register-python-argcomplete checkov
```

with:

```zsh
    register-python-argcomplete --shell zsh checkov
```

- [ ] **Step 5: Verify completion wiring in a fresh shell.**

Run:
```
zsh -ic 'command -v register-python-argcomplete; print "fn=${+functions[_python_argcomplete_global]}"'
```
Expected: `/Users/bene/.cache/uv/bin/register-python-argcomplete` and `fn=1`.

If `fn=0` (the eval ran before the completion system was ready), add `wait` to the load line so it registers after `zicompinit`:
```zsh
zi auto with"uv" wait for argcomplete
```
then re-run the check until `fn=1`.

- [ ] **Step 6: Functional spot check (manual, observed).**

In a fresh interactive shell, type `uv <TAB>` (uv's own completion, proves the completion system is live) and a uv-installed argparse tool such as `checkov --<TAB>`, confirming completions appear. Record the observed result.

- [ ] **Step 7: Commit.**

```bash
git add zsh/.zshrc Brewfile
git commit -m "Move argcomplete to uv tool with zsh global completion"
```

---

### Task 3: Enable mise per-repo uv venv auto-activation

**Goal:** Configure mise to auto-create and source a per-repo `.venv` via uv, without registering any global Python.

**Files:**
- Modify: `mise/config.toml`

**Acceptance Criteria:**
- [ ] `mise/config.toml` has `[settings]` with `python.uv_venv_auto = "create|source"`.
- [ ] No global `python` entry is added under `[tools]`.
- [ ] A scratch repo declaring a Python version gets a `.venv` auto-created/activated by mise.

**Verify:**
```
zsh -ic 'cd $(mktemp -d) && echo "3.13" > .python-version && mise trust -q . && mise install python -q && test -d .venv && python -c "import sys; print(sys.prefix)"'
```
Expected: prints a `sys.prefix` ending in `/.venv` (the auto-created project venv).

**Steps:**

- [ ] **Step 1: Add the settings block to `mise/config.toml`.**

Append to the file (which currently contains only the `[tools]` table):

```toml

[settings]
# uv owns per-repo virtualenvs: auto-source an existing .venv and create one when
# missing. Per-repo python versions are declared per project (.python-version or
# [tools] python = "..."); brew remains the global default interpreter.
python.uv_venv_auto = "create|source"
```

- [ ] **Step 2: Verify auto-venv behavior in a scratch repo.**

Run:
```
zsh -ic 'd=$(mktemp -d); cd "$d"; echo "3.13" > .python-version; mise trust -q .; mise install -q; ls -d .venv 2>/dev/null && python -c "import sys; print(sys.prefix)"; cd /; rm -rf "$d"'
```
Expected: a `.venv` directory exists and `sys.prefix` points inside it.

- [ ] **Step 3: Commit.**

```bash
git add mise/config.toml
git commit -m "Enable mise per-repo uv venv auto-activation"
```

---

### Task 4: Rewrite the README Python section

**Goal:** Make the documentation match the new three-layer model (brew system Python, mise per-repo versions, uv/uvx tooling, pip lockdown, argcomplete via uv).

**Files:**
- Modify: `README.md:469-502` (Python section)

**Acceptance Criteria:**
- [ ] The section no longer claims `PYTHONHOME` is set to brew `python@*`.
- [ ] It documents brew as the system default, mise per-repo versions + `mise sync python --uv`, uv/uvx for tools and venvs, the pip/virtualenv lockdown, and argcomplete-via-uv global completion.
- [ ] No reference to a brew `python-argcomplete` formula remains.

**Verify:**
```
grep -n -iE "PYTHONHOME|python-argcomplete|uv_venv_auto|mise sync python" README.md
```
Expected: matches showing the new `uv_venv_auto`/`mise sync python` content and **no** `PYTHONHOME`/`python-argcomplete` matches in the Python section.

**Steps:**

- [ ] **Step 1: Replace the Python section body (README.md:471-502).**

Replace the existing bullet list under `### Python` with:

```markdown
The Python setup keeps a single, brew-owned system interpreter and pushes all
version- and dependency-management into per-repository tooling, so the system
Python is never clobbered by `pip`.

- **System interpreter (Homebrew):** `python3`/`pip` resolve to the
  Homebrew-installed Python via `brew shellenv` on `PATH`. `PYTHONHOME` is
  deliberately left unset so it never overrides a virtualenv.

- **System lockdown:** `pip/pip.conf` sets `require-virtualenv = True`, and the
  shell exports `PIP_REQUIRE_VIRTUALENV=1`, `PIP_USER=0`, and
  `PYTHONNOUSERSITE=1`. `pip install` outside a virtualenv is refused and no
  per-user site clutter accumulates — only `brew` ever writes to the system
  Python.

- **Per-repo versions (mise + uv):** a repository declares its Python version
  (`.python-version` or `mise.toml` `[tools] python = "…"`). With
  `python.uv_venv_auto = "create|source"` in `mise/config.toml`, mise
  auto-creates and activates the repo's uv `.venv`. `mise sync python --uv`
  aligns mise's installed interpreter with the project's. See the
  [mise uv cookbook](https://mise.jdx.dev/mise-cookbook/python.html).

- **CLI tools (uv/uvx):** standalone Python tools are run with `uvx` or
  installed with `uv tool install`
  ([uv tools](https://docs.astral.sh/uv/concepts/tools/)). Installed tools live
  under `UV_TOOL_DIR` (`~/.cache/uv/tools`) with entry points in
  `UV_TOOL_BIN_DIR` (`~/.cache/uv/bin`) on `PATH`. `:uv-update` (run by `zup`)
  upgrades them all; new tools auto-install on `zi update` via the `z-a-auto`
  annex's `with"uv"` integration.

- **Interactive startup:** `PYTHONSTARTUP` points to `python/startup.py` for
  REPL history.

- **argparse completion:** `argcomplete` is installed as a uv tool and registers
  a zsh global completer (`activate-global-python-argcomplete`), so any
  argparse program marked `PYTHON_ARGCOMPLETE_OK` gets tab completion;
  individual tools (e.g. checkov) also register explicitly via
  `register-python-argcomplete --shell zsh`.

- **XDG-clean:** all Python config, cache, and data honor the XDG layout.
```

- [ ] **Step 2: Verify the doc content.**

Run:
```
grep -n -iE "PYTHONHOME|python-argcomplete|uv_venv_auto|mise sync python" README.md
```
Expected: shows the `uv_venv_auto` and `mise sync python --uv` lines and no `PYTHONHOME`/brew-`python-argcomplete` references in the Python section.

- [ ] **Step 3: Commit.**

```bash
git add README.md
git commit -m "Document brew/mise/uv python model in README"
```

---

## Self-Review

**Spec coverage:** Spec §A→Task 1; §B→Task 1; §C (uv block, no change)→noted, untouched by design; §D→Task 2; §E→Task 3; §F→Task 4; §G (startup.py)→Task 1. All covered.

**Placeholder scan:** No TBD/TODO; every code/command step shows concrete content and expected output.

**Type/name consistency:** `:argcomplete-eval`, `_python_argcomplete_global`, `python.uv_venv_auto`, `UV_TOOL_BIN_DIR`, `register-python-argcomplete --shell zsh` used consistently across tasks and match probed reality.
