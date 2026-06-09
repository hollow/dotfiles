# install.sh fresh-provision Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers-extended-cc:subagent-driven-development (recommended) or superpowers-extended-cc:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Make `install.sh` install Homebrew + the committed Brewfile and then run `zup` before handing off, so the first `:brew-update` dump can't clobber the Brewfile / cause missing packages on a fresh setup.

**Architecture:** Add a `provision_macos` helper (above the `DOTFILES_INSTALL_LIB` test-lib guard so it's unit-testable), and change the script tail to call it then hand off via `exec zsh -ic zup` on macOS+tty. `zsh/.zshrc`/`:brew-update` are NOT touched (kept byte-identical to upstream). Apple-Silicon `/opt/homebrew` only.

**Tech Stack:** POSIX `sh` (`install.sh`), shell unit tests (`tests/install_test.sh` sourced in `DOTFILES_INSTALL_LIB=1` mode with PATH-shimmed fakes), `sh -n`, `shellcheck`.

**Spec:** `docs/superpowers/specs/2026-06-09-install-fresh-provision-design.md`
**Branch:** `IT-8323-install-fresh-provision` (already created; spec already committed).

---

### Task 1: `provision_macos` helper + unit tests

**Goal:** Add a `provision_macos <dir>` function to `install.sh` (above the test-lib guard) that ensures Homebrew is installed and runs `brew bundle install` of the committed Brewfile, with bundle failure non-fatal; cover its control flow with unit tests.

**Files:**
- Modify: `install.sh` (add `provision_macos` among the helper functions, before the `if [ "${DOTFILES_INSTALL_LIB:-0}" = 1 ]` guard at line ~140)
- Modify: `tests/install_test.sh` (add a `provision_macos` scenario block before the final `Result:` summary, ~line 136)

**Acceptance Criteria:**
- [x] `provision_macos` is defined above the `DOTFILES_INSTALL_LIB` guard (so `DOTFILES_INSTALL_LIB=1 . install.sh` defines it without running main).
- [x] When `brew` is already on `PATH`: it does NOT invoke the Homebrew installer (`curl`), and DOES run `brew bundle install` with `HOMEBREW_BUNDLE_FILE=<dir>/Brewfile` and `HOMEBREW_BUNDLE_NO_LOCK=1`.
- [x] A failing `brew bundle install` is non-fatal: `provision_macos` returns 0.
- [x] `sh tests/install_test.sh` ends `ALL PASS` (existing scenarios still pass + the two new cases).

**Verify:** `sh tests/install_test.sh` → `ALL PASS`

**Steps:**

- [x] **Step 1: Add the failing tests** to `tests/install_test.sh`, immediately before the `echo` / `Result:` summary block (currently ~line 136). Insert:

```sh
echo
echo "# provision_macos"

# Fakes: a brew that logs its args + bundle env, and a curl that must NOT be
# called when brew is already present. Prepend a shim dir to PATH.
PBIN="$WORK/pbin"; mkdir -p "$PBIN"
export PLOG="$WORK/plog"; : > "$PLOG"
cat > "$PBIN/brew" <<'SH'
#!/bin/sh
printf 'brew %s\n' "$*" >> "$PLOG"
if [ "$1" = bundle ]; then
    printf 'BUNDLE_FILE=%s NO_LOCK=%s\n' "${HOMEBREW_BUNDLE_FILE:-}" "${HOMEBREW_BUNDLE_NO_LOCK:-}" >> "$PLOG"
    exit "${BREW_BUNDLE_RC:-0}"
fi
exit 0
SH
cat > "$PBIN/curl" <<'SH'
#!/bin/sh
printf 'curl %s\n' "$*" >> "$PLOG"
exit 0
SH
chmod +x "$PBIN/brew" "$PBIN/curl"

# Case A: brew already present -> no Homebrew install (no curl), bundle install
# runs with the right env.
PC="$WORK/pc"; mkdir -p "$PC"; printf 'brew-upstream\n' > "$PC/Brewfile"
: > "$PLOG"; BREW_BUNDLE_RC=0 PATH="$PBIN:$PATH" provision_macos "$PC" > /dev/null 2>&1; rc=$?
if [ "$rc" -eq 0 ] \
    && ! grep -q '^curl ' "$PLOG" \
    && grep -q "BUNDLE_FILE=$PC/Brewfile NO_LOCK=1" "$PLOG"; then
    ok "brew present: skips Homebrew install, bundle install has BUNDLE_FILE+NO_LOCK"
else
    bad "brew present: skips Homebrew install, bundle install has BUNDLE_FILE+NO_LOCK"
fi

# Case B: bundle install fails -> provision_macos is non-fatal (returns 0).
: > "$PLOG"; BREW_BUNDLE_RC=1 PATH="$PBIN:$PATH" provision_macos "$PC" > /dev/null 2>&1; rc=$?
if [ "$rc" -eq 0 ]; then
    ok "bundle failure is non-fatal (returns 0)"
else
    bad "bundle failure is non-fatal (returns 0)"
fi
```

- [x] **Step 2: Run the tests — expect failure** (function not yet defined):

Run: `sh tests/install_test.sh`
Expected: the two new `provision_macos` lines `FAIL` (and likely a `command not found: provision_macos` to stderr); existing scenarios still `ok`.

- [x] **Step 3: Implement `provision_macos`** in `install.sh`. Insert it among the helper functions, immediately BEFORE the test-lib guard (the `if [ "${DOTFILES_INSTALL_LIB:-0}" = 1 ]; then return 0; fi` block at ~line 139):

```sh
# Ensure Homebrew is installed and the committed Brewfile is fully installed,
# so the first `:brew-update` dump (later, via zup) cannot drop packages.
# Apple-Silicon (/opt/homebrew) only. A bundle failure is warned, not fatal.
provision_macos() {
    _dir=$1
    if ! command -v brew > /dev/null 2>&1; then
        if [ ! -x /opt/homebrew/bin/brew ]; then
            log "Installing Homebrew..."
            NONINTERACTIVE=1 /bin/bash -c \
                "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" \
                < /dev/tty
        fi
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi

    log "Installing packages from the Brewfile (this can take a while)..."
    if ! HOMEBREW_BUNDLE_FILE="$_dir/Brewfile" HOMEBREW_BUNDLE_NO_LOCK=1 brew bundle install; then
        err "Some Brewfile packages failed to install; continuing."
        err "Re-run 'zup' later to retry."
    fi
}
```

- [x] **Step 4: Run the tests — expect pass**:

Run: `sh tests/install_test.sh`
Expected: `ALL PASS` (all existing scenarios + both new `provision_macos` cases `ok`).

- [x] **Step 5: Syntax + lint:**

Run: `sh -n install.sh && sh -n tests/install_test.sh && echo SYNTAX_OK`
Expected: `SYNTAX_OK`. If `shellcheck` is available: `shellcheck install.sh tests/install_test.sh` (clean, or only pre-existing/style notes).

- [x] **Step 6: Commit:**

```bash
git add install.sh tests/install_test.sh
git commit -m "$(cat <<'EOF'
feat(install): add provision_macos (Homebrew + brew bundle install) (IT-8323)

Installs Homebrew if missing (Apple-Silicon) and bundle-installs the
committed Brewfile, so a later :brew-update dump can't drop packages.
Bundle failure is non-fatal. Unit-tested via PATH-shimmed brew/curl.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 2: Wire `provision_macos` into the install handoff

**Goal:** Change the tail of `install.sh` so that on macOS with a usable terminal it provisions then hands off via `zup`; non-macOS and no-tty behavior is unchanged.

**Files:**
- Modify: `install.sh` (the final handoff block, currently the Linux notice + `if [ -e /dev/tty ]; then exec zsh -i </dev/tty; else …; fi` at ~lines 196–207)

**Acceptance Criteria:**
- [x] On macOS + `/dev/tty`: the tail calls `provision_macos "$CONFIG_DIR"` then `exec zsh -ic zup </dev/tty`.
- [x] On non-macOS + `/dev/tty`: unchanged — `exec zsh -i </dev/tty`.
- [x] On no-tty: unchanged — prints the "Open a new terminal window…" guidance.
- [x] `zsh/.zshrc` is NOT modified by this task.
- [x] `sh -n install.sh` parses; `sh tests/install_test.sh` still `ALL PASS` (the lib-mode `return 0` short-circuit means the tail never runs under test).

**Verify:** `sh -n install.sh && sh tests/install_test.sh` → parses + `ALL PASS`

**Steps:**

- [x] **Step 1: Replace the handoff block.** The current tail (Step-4 comment through the final `fi`) reads:

```sh
# 4. Hand off to a fresh interactive zsh to run the first-run bootstrap.
if [ "$os" != "Darwin" ]; then
    log "Linux detected (best-effort): Homebrew and starship will NOT auto-install."
    log "See the README for manual steps: $REPO_URL"
fi

log "Done. Starting zsh — the first launch installs Homebrew, plugins, and the prompt."
if [ -e /dev/tty ]; then
    exec zsh -i </dev/tty
else
    log "Open a new terminal window to finish setup (zsh bootstraps on first launch)."
fi
```

Replace it with:

```sh
# 4. Provision (macOS) and hand off to a fresh interactive zsh.
if [ "$os" != "Darwin" ]; then
    log "Linux detected (best-effort): Homebrew and starship will NOT auto-install."
    log "See the README for manual steps: $REPO_URL"
fi

if [ -e /dev/tty ]; then
    if [ "$os" = "Darwin" ]; then
        provision_macos "$CONFIG_DIR"
        log "Provisioning done. Updating everything via zup and starting zsh..."
        exec zsh -ic zup </dev/tty
    else
        log "Starting zsh..."
        exec zsh -i </dev/tty
    fi
else
    log "Open a new terminal window to finish setup (zsh bootstraps on first launch)."
fi
```

- [x] **Step 2: Confirm `.zshrc` untouched and syntax OK:**

Run:
```bash
git diff --name-only | grep -qx 'zsh/.zshrc' && echo "ZSHRC CHANGED (BAD)" || echo "zshrc untouched OK"
sh -n install.sh && echo SYNTAX_OK
sh tests/install_test.sh | tail -1
```
Expected: `zshrc untouched OK`, `SYNTAX_OK`, `ALL PASS`.

- [x] **Step 3: Commit:**

```bash
git add install.sh
git commit -m "$(cat <<'EOF'
feat(install): provision + run zup on first install (macOS) (IT-8323)

On macOS with a terminal, install.sh now runs provision_macos (Homebrew +
brew bundle install) then hands off via `exec zsh -ic zup`, so the machine
is fully provisioned/updated before any :brew-update dump. Non-macOS and
no-tty behavior unchanged.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 3: Mark plan tasks complete + final verify

**Goal:** Flip this plan's checkboxes, sync `.tasks.json`, run the full check suite, and commit the bookkeeping (the final commit before the PR).

**Files:**
- Modify: `docs/superpowers/plans/2026-06-09-install-fresh-provision.md`
- Modify: `docs/superpowers/plans/2026-06-09-install-fresh-provision.md.tasks.json`

**Acceptance Criteria:**
- [x] Task 1–2 checkboxes checked in this plan; Task 1–2 statuses `completed` in `.tasks.json`.
- [x] Full check suite passes (commands below).

**Verify:** `sh tests/install_test.sh && sh -n install.sh && echo DONE`

**Steps:**

- [x] **Step 1: Full re-verification:**

```bash
cd /Users/bene/src/remerge/dotfiles
sh tests/install_test.sh | tail -2          # -> ALL PASS
sh -n install.sh && sh -n tests/install_test.sh && echo SYNTAX_OK
git diff --name-only main..HEAD             # only install.sh, tests/install_test.sh, docs/superpowers/*
grep -c 'provision_macos' install.sh        # >=2 (definition + call)
git diff --quiet main..HEAD -- zsh/.zshrc && echo "zshrc untouched OK"
```
Expected: `ALL PASS`, `SYNTAX_OK`, only the expected files, `provision_macos` count ≥ 2, `zshrc untouched OK`.

- [x] **Step 2:** Check the boxes in Tasks 1–2 of this plan doc and set Task 1–2 status to `completed` in `2026-06-09-install-fresh-provision.md.tasks.json`.

- [x] **Step 3: Commit:**

```bash
git add docs/superpowers/plans/2026-06-09-install-fresh-provision.md docs/superpowers/plans/2026-06-09-install-fresh-provision.md.tasks.json
git commit -m "$(cat <<'EOF'
docs(install): mark fresh-provision plan tasks complete (IT-8323)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Notes for the implementer

- **Do NOT run the real `install.sh` or `zup`** — they install Homebrew and mutate the machine. Verification here is the unit tests (`sh tests/install_test.sh`) + `sh -n`. The real fresh-install run is a separate **manual** check (Bene / a teammate, screen-share), exactly as the original bug was found.
- **Do NOT modify `zsh/.zshrc`** — the fix is `install.sh`-only by design (keeps `.zshrc` byte-identical to upstream).
- Keep edits POSIX `sh` (the script's `#!/bin/sh` + `set -eu`); the `if ! cmd; then …; fi` form is required so a failure doesn't abort under `set -e`.
- **No PR is opened by this plan.** After Task 3, hand back for the user to review and push/open the `IT-8323: …` PR.
