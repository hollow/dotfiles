# Python / uv / mise / argparse integration — design

Date: 2026-06-05
Status: approved (pending spec review)

## Goal

Reactivate and fix the Python tooling integration in the zsh config so that:

- **Homebrew owns the system Python.** `python3`/`pip` resolve to the
  Homebrew-installed interpreter, and nothing but `brew` is ever allowed to
  write into it.
- **Per-repository Python versions come from mise**, and per-repository
  virtualenvs come from uv, following the mise "uv" cookbook
  (<https://mise.jdx.dev/mise-cookbook/python.html>).
- **All standalone Python CLI tooling is uv/uvx based**
  (<https://docs.astral.sh/uv/concepts/tools/>).
- **It is not possible to install packages into the system Python via pip**
  (or accidentally via uv).
- **argparse-based programs get tab completion** again via argcomplete, with
  the previously-dead brew-based wiring replaced by a uv-installed argcomplete.

## Mental model — three non-overlapping layers

1. **brew = system Python.** Already on `PATH` via `brew shellenv` (zshrc:60-62).
   Default `python3`/`pip`. Read-only to everything except `brew`.
2. **mise = per-repo Python versions.** A repo declares its version
   (`.python-version` or `mise.toml`); mise installs it and auto-activates the
   repo's `.venv`. No global Python is registered with mise — brew stays the
   default interpreter.
3. **uv / uvx = everything else.** Standalone CLI tools
   (`uv tool install` / `uvx`) and per-repo virtualenvs (`uv venv` / `uv sync`).

The guard rails (Section B) make layer 1 effectively read-only to anything but
`brew`.

## Decisions (from brainstorming)

- **PYTHONHOME:** dropped. Do not pin `PYTHONHOME` to brew `python@*`; it
  overrides the interpreter home for every invocation and breaks mise/uv venvs.
  Brew-on-PATH is sufficient.
- **argcomplete:** global completion hook, backed by a uv-installed
  `argcomplete`; keep per-tool `register-python-argcomplete` for tools like
  checkov.
- **mise Python:** per-repo only. No global `python` entry in mise's config.
- **System-Python protection:** `require-virtualenv` (pip.conf) plus env-var
  guards (`PIP_REQUIRE_VIRTUALENV`, `PIP_USER`, `PYTHONNOUSERSITE`).
- **`python.uv_venv_auto`:** `"create|source"` — auto-activate an existing
  repo `.venv`, and auto-create one when missing.

## Changes by component

### A. Python core block — `zsh/.zshrc` (~196-211)

- Reactivate `export PYTHONSTARTUP="${XDG_CONFIG_HOME}/python/startup.py"`.
- Delete (not just keep commented) the `:python-load` / `PYTHONHOME` block and
  the `OMZP::python` plugin line. Leave a one-line comment noting that
  brew-on-PATH + mise/uv is intentional and `PYTHONHOME` is deliberately unset.
- Keep the `python-each` / `python-parallel` aliases.

### B. System-Python protection — `zsh/.zshrc` + `pip/pip.conf`

- Keep `pip/pip.conf` → `require-virtualenv = True`.
- Add env guards in the zshrc python block:
  - `export PIP_REQUIRE_VIRTUALENV=1`
  - `export PIP_USER=0`
  - `export PYTHONNOUSERSITE=1`
- No uv wrapper needed: `uv pip` refuses the system environment unless an
  explicit `--system` is passed.
- Net effect: `pip install X` outside a venv is refused; no
  `~/.local/lib/pythonX` user-site clutter.

### C. uv block — `zsh/.zshrc` (~213-228)

- No changes. `UV_TOOL_DIR`, `UV_TOOL_BIN_DIR`, the `add path`, `:uv-update`,
  `:uv-eval`, and `zi auto has"uv" for uv` already work and stay as-is.

### D. argparse / argcomplete — `zsh/.zshrc` (~230-242)

- Install argcomplete as a uv tool via the existing annex:
  `zi auto with"uv" for argcomplete` → provides `register-python-argcomplete`
  and `activate-global-python-argcomplete` on `UV_TOOL_BIN_DIR`.
- Replace the dead brew-fpath `:argcomplete-load` with a global-completion
  enabler wired through the eval-annex pattern (an `:argcomplete-eval`,
  mirroring `:uv-eval`), using argcomplete's zsh support.
- The exact zsh incantation (zsh-native vs. `bashcompinit` + global script)
  will be **verified to actually complete** during implementation rather than
  assumed.
- This also un-breaks `:checkov-eval`'s `register-python-argcomplete checkov`,
  which fails silently today because argcomplete is not installed.

### E. mise — `mise/config.toml` + README

- Add to `mise/config.toml`:
  ```toml
  [settings]
  python.uv_venv_auto = "create|source"
  ```
- No global `python` entry.
- Document the per-repo workflow: declare the version (`.python-version` or
  `mise.toml` `[tools] python = "..."`), then `uv venv` / `uv sync`, and
  `mise sync python --uv` to align mise's installed version with the project's.

### F. README — `README.md` "Python" section (~469-502)

- Rewrite to reflect the three-layer model: drop the PYTHONHOME/runtime-
  discovery paragraph; describe brew = system default, mise per-repo versions,
  uv/uvx for tools and venvs, the pip lockdown, and argcomplete global
  completion. Touch the mise section if it implies anything contradictory.

### G. `python/startup.py` robustness fix

- Fall back to `~/.local/share` when `XDG_DATA_HOME` is unset, so the file
  cannot crash a non-interactive/imported invocation
  (`os.path.join(None, ...)` currently raises).

## Verification (real shell, observed — not assumed)

In a fresh `zsh` session:

- `command -v python3` resolves under `${HOMEBREW_PREFIX}`.
- `pip install requests` outside a venv is **refused** (require-virtualenv).
- `uvx --version` works; `register-python-argcomplete` is on PATH.
- argcomplete completion fires for a registered argparse program.
- A scratch repo with a `.python-version` + `uv venv` auto-activates its
  `.venv` under mise (`python.uv_venv_auto`).
- `checkov` completion registration no longer errors.

## Out of scope

- No global mise Python.
- No migration of existing per-repo projects.
- No changes to unrelated language blocks (node, ruby, etc.).
