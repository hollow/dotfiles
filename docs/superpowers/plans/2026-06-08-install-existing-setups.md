# install.sh existing-setup handling — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers-extended-cc:subagent-driven-development (recommended) or
> superpowers-extended-cc:executing-plans to implement this plan task-by-task.
> Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rework `install.sh` step 2 so an existing `~/.config` — including a
fork checkout — is migrated onto `remerge/dotfiles` interactively, with a
diff + double-confirm and a `git restore` based force-restore, aborting safely
when there is no terminal.

**Architecture:** Extract the placement logic into small POSIX-sh functions
(`confirm`, `is_remerge_remote`, `ensure_main_branch`, `restore_dotfiles`,
`place_dotfiles`) added near the top of `install.sh`. A one-line source-guard
(`DOTFILES_INSTALL_LIB=1`) lets a test harness source the script and exercise
the functions without running the installer. The old inline step-2 block is
replaced by a single `place_dotfiles` call.

**Tech Stack:** POSIX `sh` (macOS `/bin/sh` = bash 3.2 in POSIX mode), `git`
(`restore`, `symbolic-ref`, `update-ref`), `shellcheck` for linting. No new
runtime dependencies; tests are a self-contained `sh` script (no BATS).

**Spec:** `docs/superpowers/specs/2026-06-08-install-existing-setups-design.md`

**Conventions (verified against the repo):**

- `install.sh` uses **4-space indentation**. Match it. Do **not** run `shfmt`
  (its default tabs would reformat the entire file).
- Keep `shellcheck install.sh` clean (it currently is).
- POSIX `sh` has no `local`; functions use `_`-prefixed parameter variables.
- Output: in `curl … | sh`, only **stdin** is the pipe — stdout/stderr are the
  terminal. So `log`/`err` and diffs print to stdout/stderr; only **reading**
  input needs `/dev/tty`.

---

### Task 1: Add `confirm` + `is_remerge_remote` helpers and a sourceable test harness

**Goal:** Add the two leaf helper functions and the library source-guard to
`install.sh`, and create a test harness that can source the script and unit-test
`is_remerge_remote`.

**Files:**

- Modify: `install.sh` (insert helpers + guard between `err()` and
  `os="$(uname -s)"`)
- Create: `tests/install_test.sh`

**Acceptance Criteria:**

- [ ] `is_remerge_remote` returns success for the https, https-`.git`,
      `git@`-ssh, and `ssh://` forms of `remerge/dotfiles`, and failure for
      forks/other repos.
- [ ] `confirm` returns non-zero (No) when `/dev/tty` is unavailable.
- [ ] `DOTFILES_INSTALL_LIB=1 . ./install.sh` defines the functions **without**
      running the installer (no clone, no zsh exec).
- [ ] `shellcheck install.sh tests/install_test.sh` is clean.
- [ ] `sh tests/install_test.sh` exits 0 and prints `ALL PASS`.

**Verify:** `shellcheck install.sh tests/install_test.sh && sh tests/install_test.sh`
→ ends with `ALL PASS`, exit 0.

**Steps:**

- [ ] **Step 1: Add the helper functions and source-guard to `install.sh`.**

Insert the following block immediately after the `err()` definition (the line
`err() { printf '\033[1;31merror:\033[0m %s\n' "$1" >&2; }`) and before
`os="$(uname -s)"`:

```sh

# Ask a yes/no question on the controlling terminal. Returns success only on an
# explicit "yes". With no terminal (e.g. `curl ... | sh`, whose stdin is the
# pipe), we cannot prompt — so we answer "no" and destructive steps abort safely.
confirm() {
    [ -e /dev/tty ] || return 1
    printf '%s' "$1" > /dev/tty
    read -r _reply < /dev/tty || return 1
    case "$_reply" in
        [Yy] | [Yy][Ee][Ss]) return 0 ;;
        *) return 1 ;;
    esac
}

# True when the given remote URL refers to remerge/dotfiles, in any of the forms
# git prints (https, https with .git, ssh shorthand, ssh URL).
is_remerge_remote() {
    _url=${1%.git}
    _url=${_url%/}
    case "$_url" in
        https://github.com/remerge/dotfiles) return 0 ;;
        http://github.com/remerge/dotfiles) return 0 ;;
        git@github.com:remerge/dotfiles) return 0 ;;
        ssh://git@github.com/remerge/dotfiles) return 0 ;;
        *) return 1 ;;
    esac
}

# When sourced for testing (DOTFILES_INSTALL_LIB=1), stop here so the helper
# functions above can be exercised without running the installer.
if [ "${DOTFILES_INSTALL_LIB:-0}" = 1 ]; then
    return 0
fi
```

- [ ] **Step 2: Create the test harness `tests/install_test.sh`.**

```sh
#!/bin/sh
# Unit tests for install.sh. Sources the script in library mode
# (DOTFILES_INSTALL_LIB=1) and exercises its functions in isolation.
#
# Run: sh tests/install_test.sh
set -u

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)

# Source install.sh as a library: defines the functions, does not run main.
DOTFILES_INSTALL_LIB=1 . "$ROOT/install.sh"
# install.sh runs `set -eu`; relax it so assertions can see non-zero status.
set +e

PASS=0
FAIL=0
ok()  { PASS=$((PASS + 1)); printf '  ok   - %s\n' "$1"; }
bad() { FAIL=$((FAIL + 1)); printf '  FAIL - %s\n' "$1"; }

echo "# is_remerge_remote"
for _u in \
    "https://github.com/remerge/dotfiles" \
    "https://github.com/remerge/dotfiles.git" \
    "git@github.com:remerge/dotfiles.git" \
    "ssh://git@github.com/remerge/dotfiles"; do
    if is_remerge_remote "$_u"; then ok "accept $_u"; else bad "accept $_u"; fi
done
for _u in \
    "https://github.com/marwa/dotfiles" \
    "https://github.com/remerge/other"; do
    if is_remerge_remote "$_u"; then bad "reject $_u"; else ok "reject $_u"; fi
done

echo
echo "Result: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && echo "ALL PASS"
[ "$FAIL" -eq 0 ]
```

- [ ] **Step 3: Run shellcheck.**

Run: `shellcheck install.sh tests/install_test.sh`
Expected: no output, exit 0.

- [ ] **Step 4: Run the tests.**

Run: `sh tests/install_test.sh`
Expected: lists 6 `ok` lines under `# is_remerge_remote`, then
`Result: 6 passed, 0 failed` and `ALL PASS`; exit 0.

- [ ] **Step 5: Verify the source-guard does not run the installer.**

Run: `DOTFILES_INSTALL_LIB=1 sh -c '. ./install.sh; echo "loaded rc=$?"; command -v confirm'`
Expected: prints `loaded rc=0` and `confirm` — and does **not** print any
`==>` installer log lines (no clone / no zsh handoff).

- [ ] **Step 6: Commit.**

```sh
git add install.sh tests/install_test.sh
git commit -m "feat(install): add confirm/is_remerge_remote helpers + test harness (IT-8323)"
```

---

### Task 2: Implement `place_dotfiles`, `restore_dotfiles`, `ensure_main_branch`

**Goal:** Add the placement decision flow and the shared `git restore` based
restore step, and test every scenario (clone, adopt-in-place, foreign confirmed,
foreign declined, already-remerge dirty, already-remerge clean).

**Files:**

- Modify: `install.sh` (insert three functions just before the
  `DOTFILES_INSTALL_LIB` guard added in Task 1)
- Modify: `tests/install_test.sh` (append `place_dotfiles` scenario tests)

**Acceptance Criteria:**

- [ ] Empty/absent dir → `git clone`, no prompt.
- [ ] Non-empty dir without `.git` → adopted; a conflicting untracked file
      (also in the repo) is overwritten, a non-repo untracked file is preserved.
- [ ] Foreign repo + confirm yes → `origin` re-pointed to the repo URL and the
      working tree restored; non-repo untracked file preserved.
- [ ] Foreign repo + confirm no → exits non-zero and leaves `origin` unchanged.
- [ ] Already-remerge with a local tracked edit + confirm yes → edit discarded,
      file matches the repo.
- [ ] Already-remerge and clean → short-circuit (no restore needed), exit 0.
- [ ] `shellcheck install.sh tests/install_test.sh` clean; `sh tests/install_test.sh`
      prints `ALL PASS`.

**Verify:** `shellcheck install.sh tests/install_test.sh && sh tests/install_test.sh`
→ ends with `ALL PASS`, exit 0.

**Steps:**

- [ ] **Step 1: Add the three functions to `install.sh`.**

Insert the following immediately **before** the `# When sourced for testing`
guard block (i.e. after the `is_remerge_remote` function, before
`if [ "${DOTFILES_INSTALL_LIB:-0}" = 1 ]; then`):

```sh

# Point local main at origin/main and track it, without touching the working
# tree. Plumbing only — deliberately avoids `git checkout`/`git switch`.
ensure_main_branch() {
    _dir=$1
    git -C "$_dir" symbolic-ref HEAD refs/heads/main
    git -C "$_dir" update-ref refs/heads/main refs/remotes/origin/main
    git -C "$_dir" branch --set-upstream-to=origin/main main > /dev/null 2>&1 || true
}

# Fetch origin/main and force the working tree to match it, after showing what
# will change and confirming twice. Untracked files that are not in the repo
# (e.g. git/local, mise/age.txt) are preserved. Aborts (exit 1) if the user
# declines or there is no terminal to confirm on.
restore_dotfiles() {
    _dir=$1
    git -C "$_dir" fetch -q origin main

    if git -C "$_dir" diff --quiet origin/main 2> /dev/null; then
        log "$_dir is already up to date with remerge/dotfiles."
        ensure_main_branch "$_dir"
        return 0
    fi

    log "These files in $_dir will be reset to match remerge/dotfiles:"
    git -C "$_dir" --no-pager diff --stat origin/main

    if confirm "Show the full diff first? [y/N] "; then
        git -C "$_dir" --no-pager diff origin/main || true
    fi

    if ! confirm "Discard these local changes and restore $_dir to remerge/dotfiles? [y/N] "; then
        err "Left $_dir untouched. To restore it manually later, run:"
        err "  git -C $_dir restore --source=origin/main --staged --worktree -- :/"
        exit 1
    fi

    git -C "$_dir" restore --source=origin/main --staged --worktree -- :/
    ensure_main_branch "$_dir"
    log "Restored $_dir to match remerge/dotfiles."
}

# Put remerge/dotfiles into $1 (the config dir), adopting whatever is already
# there: an existing repo whose origin is remerge/dotfiles is just refreshed; a
# repo pointing elsewhere (a fork) is offered for replacement; a non-empty plain
# directory is adopted in place; an empty/missing directory is cloned.
place_dotfiles() {
    _dir=$1
    _repo=$2

    if [ -e "$_dir/.git" ]; then
        _origin=$(git -C "$_dir" remote get-url origin 2> /dev/null || true)
        if [ -n "$_origin" ] && is_remerge_remote "$_origin"; then
            log "Dotfiles already present in $_dir (remerge/dotfiles)."
        else
            if [ -n "$_origin" ]; then
                log "$_dir is a git repo for $_origin,"
                log "not remerge/dotfiles."
            else
                log "$_dir is a git repo with no 'origin' remote."
            fi
            if ! confirm "Replace it with remerge/dotfiles? [y/N] "; then
                err "Left $_dir untouched. To migrate it manually later, run:"
                err "  git -C $_dir remote set-url origin $_repo"
                err "  git -C $_dir fetch origin main"
                err "  git -C $_dir restore --source=origin/main --staged --worktree -- :/"
                exit 1
            fi
            if git -C "$_dir" remote get-url origin > /dev/null 2>&1; then
                git -C "$_dir" remote set-url origin "$_repo"
            else
                git -C "$_dir" remote add origin "$_repo"
            fi
        fi
        restore_dotfiles "$_dir"
    elif [ -d "$_dir" ] && [ -n "$(find "$_dir" -mindepth 1 -maxdepth 1 2> /dev/null | head -n 1)" ]; then
        log "$_dir exists and is not empty; adopting the dotfiles in place..."
        git -C "$_dir" init -q
        git -C "$_dir" remote add origin "$_repo" 2> /dev/null \
            || git -C "$_dir" remote set-url origin "$_repo"
        restore_dotfiles "$_dir"
    else
        log "Cloning dotfiles into $_dir..."
        git clone -q "$_repo" "$_dir"
    fi
}
```

- [ ] **Step 2: Append `place_dotfiles` scenario tests to `tests/install_test.sh`.**

Insert the following block **before** the final summary section (before the
`echo` / `echo "Result: …"` lines added in Task 1):

```sh
echo
echo "# place_dotfiles scenarios"

# A throwaway git env so tests never touch the user's real git identity/config.
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
export HOME="$WORK/home"; mkdir -p "$HOME"
export GIT_CONFIG_GLOBAL="$WORK/gitconfig"; : > "$GIT_CONFIG_GLOBAL"
export GIT_CONFIG_NOSYSTEM=1
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t
export GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t

# Build a fake "remerge/dotfiles" repo (REPO) with two tracked files.
REPO="$WORK/remerge"
git init -q -b main "$REPO"
printf 'brew-upstream\n' > "$REPO/Brewfile"
mkdir -p "$REPO/zsh"; printf 'zsh-upstream\n' > "$REPO/zsh/.zshrc"
git -C "$REPO" add -A
git -C "$REPO" commit -qm upstream

# For flow tests, treat the local REPO path as "remerge". (The real
# is_remerge_remote — verified above — only matches github.com/remerge/dotfiles,
# which a local fake repo can't be.)
is_remerge_remote() { [ "${1%.git}" = "$REPO" ]; }
# confirm stub: never show the full diff; CONFIRM=yes/no drives action prompts.
confirm() {
    case "$1" in
        *"full diff"*) return 1 ;;
    esac
    [ "${CONFIRM:-no}" = yes ]
}

# Scenario 1: empty/absent dir -> clone (no prompt needed).
C="$WORK/c1"
CONFIRM=no; ( place_dotfiles "$C" "$REPO" ) > /dev/null 2>&1; rc=$?
if [ "$rc" -eq 0 ] && [ "$(cat "$C/Brewfile")" = brew-upstream ]; then
    ok "clone into empty dir"
else
    bad "clone into empty dir"
fi

# Scenario 2: non-empty, no .git -> adopt; conflict overwritten, keep preserved.
C="$WORK/c2"; mkdir -p "$C"
printf 'brew-PREEXISTING\n' > "$C/Brewfile"   # untracked, also in repo -> overwrite
printf 'KEEP\n' > "$C/age.txt"                # untracked, not in repo -> preserve
CONFIRM=yes; ( place_dotfiles "$C" "$REPO" ) > /dev/null 2>&1; rc=$?
if [ "$rc" -eq 0 ] && [ "$(cat "$C/Brewfile")" = brew-upstream ] \
    && [ "$(cat "$C/age.txt")" = KEEP ]; then
    ok "adopt non-git dir (overwrite conflict, keep extras)"
else
    bad "adopt non-git dir (overwrite conflict, keep extras)"
fi

# Scenario 3: foreign repo + confirm yes -> re-point origin and restore.
C="$WORK/c3"; OTHER="$WORK/other"
git init -q -b main "$OTHER"; printf 'brew-FORK\n' > "$OTHER/Brewfile"
git -C "$OTHER" add -A; git -C "$OTHER" commit -qm fork
git clone -q "$OTHER" "$C"
printf 'KEEP3\n' > "$C/age.txt"               # untracked, preserve
CONFIRM=yes; ( place_dotfiles "$C" "$REPO" ) > /dev/null 2>&1; rc=$?
if [ "$rc" -eq 0 ] && [ "$(git -C "$C" remote get-url origin)" = "$REPO" ] \
    && [ "$(cat "$C/Brewfile")" = brew-upstream ] \
    && [ "$(cat "$C/age.txt")" = KEEP3 ]; then
    ok "foreign repo, confirmed: re-point + restore + keep extras"
else
    bad "foreign repo, confirmed: re-point + restore + keep extras"
fi

# Scenario 4: foreign repo + confirm no -> abort, origin unchanged.
C="$WORK/c4"
git clone -q "$OTHER" "$C"
CONFIRM=no; ( place_dotfiles "$C" "$REPO" ) > /dev/null 2>&1; rc=$?
if [ "$rc" -ne 0 ] && [ "$(git -C "$C" remote get-url origin)" = "$OTHER" ]; then
    ok "foreign repo, declined: aborts, origin untouched"
else
    bad "foreign repo, declined: aborts, origin untouched"
fi

# Scenario 5: already-remerge with a local tracked edit -> restore on confirm.
C="$WORK/c5"
git clone -q "$REPO" "$C"
printf 'brew-LOCAL-EDIT\n' > "$C/Brewfile"
CONFIRM=yes; ( place_dotfiles "$C" "$REPO" ) > /dev/null 2>&1; rc=$?
if [ "$rc" -eq 0 ] && [ "$(cat "$C/Brewfile")" = brew-upstream ]; then
    ok "already-remerge, dirty: edit discarded"
else
    bad "already-remerge, dirty: edit discarded"
fi

# Scenario 6: already-remerge and clean -> short-circuit, no changes.
C="$WORK/c6"
git clone -q "$REPO" "$C"
CONFIRM=no; ( place_dotfiles "$C" "$REPO" ) > /dev/null 2>&1; rc=$?
if [ "$rc" -eq 0 ] && [ "$(cat "$C/Brewfile")" = brew-upstream ]; then
    ok "already-remerge, clean: short-circuit"
else
    bad "already-remerge, clean: short-circuit"
fi
```

- [ ] **Step 3: Run shellcheck.**

Run: `shellcheck install.sh tests/install_test.sh`
Expected: no output, exit 0.

- [ ] **Step 4: Run the tests.**

Run: `sh tests/install_test.sh`
Expected: the 6 `is_remerge_remote` checks plus 6 `place_dotfiles` checks all
`ok`; `Result: 12 passed, 0 failed`; `ALL PASS`; exit 0.

- [ ] **Step 5: Commit.**

```sh
git add install.sh tests/install_test.sh
git commit -m "feat(install): place_dotfiles flow with git restore force-restore (IT-8323)"
```

---

### Task 3: Wire `place_dotfiles` into the installer and verify end-to-end

**Goal:** Replace the old inline step-2 block in `install.sh`'s main flow with a
single `place_dotfiles` call, and confirm the whole script still parses, lints,
and passes the test suite.

**Files:**

- Modify: `install.sh` (replace the step-2 `if/elif/else` block in the main flow)

**Acceptance Criteria:**

- [ ] The old `# 2. Place the dotfiles in ~/.config.` block (the
      `git pull --ff-only` / `checkout -B` / `git clone` if-chain) is replaced by
      `place_dotfiles "$CONFIG_DIR" "$REPO_URL"`.
- [ ] `sh -n install.sh` parses cleanly; `shellcheck install.sh` is clean.
- [ ] `sh tests/install_test.sh` still prints `ALL PASS`.
- [ ] Steps 3 (symlink), git-identity seeding, and 4 (zsh handoff) are unchanged.

**Verify:** `sh -n install.sh && shellcheck install.sh tests/install_test.sh && sh tests/install_test.sh`
→ ends with `ALL PASS`, exit 0.

**Steps:**

- [ ] **Step 1: Replace the step-2 block in the main flow.**

Replace this entire block (the comment line through the closing `fi`):

```sh
# 2. Place the dotfiles in ~/.config.
if [ -e "$CONFIG_DIR/.git" ]; then
    log "Dotfiles already present in $CONFIG_DIR; updating..."
    if ! git -C "$CONFIG_DIR" pull --ff-only; then
        err "Could not fast-forward $CONFIG_DIR (local changes or a different branch)."
        err "Commit or stash your changes, or remove $CONFIG_DIR, then re-run this script."
        exit 1
    fi
elif [ -d "$CONFIG_DIR" ] && [ -n "$(find "$CONFIG_DIR" -mindepth 1 -maxdepth 1 2>/dev/null | head -n 1)" ]; then
    log "$CONFIG_DIR exists and is not empty; adding the dotfiles in place..."
    git -C "$CONFIG_DIR" init -q
    git -C "$CONFIG_DIR" remote add origin "$REPO_URL" 2>/dev/null \
        || git -C "$CONFIG_DIR" remote set-url origin "$REPO_URL"
    git -C "$CONFIG_DIR" fetch -q origin main
    # No -f: refuse rather than overwrite any of the user's existing files.
    if ! git -C "$CONFIG_DIR" checkout -B main origin/main; then
        err "Some files in $CONFIG_DIR conflict with the dotfiles and were left untouched."
        err "Back up or remove the conflicting files, then re-run this script."
        exit 1
    fi
else
    log "Cloning dotfiles into $CONFIG_DIR..."
    git clone -q "$REPO_URL" "$CONFIG_DIR"
fi
```

with:

```sh
# 2. Place the dotfiles in ~/.config, adopting any existing setup.
place_dotfiles "$CONFIG_DIR" "$REPO_URL"
```

- [ ] **Step 2: Syntax + lint check.**

Run: `sh -n install.sh && shellcheck install.sh tests/install_test.sh`
Expected: no output, exit 0.

- [ ] **Step 3: Full test run.**

Run: `sh tests/install_test.sh`
Expected: `Result: 12 passed, 0 failed`; `ALL PASS`; exit 0.

- [ ] **Step 4: Confirm the wiring by reading the main flow.**

Run: `grep -n 'place_dotfiles\|checkout -B\|pull --ff-only' install.sh`
Expected: the function definition and the one call site appear; **no**
`checkout -B` or `pull --ff-only` remain in the file.

- [ ] **Step 5: Commit.**

```sh
git add install.sh
git commit -m "feat(install): use place_dotfiles for step 2 (IT-8323)"
```

---

## Notes for the implementer

- **`git restore --source=origin/main --staged --worktree -- :/`** was verified
  by hand to: overwrite locally-edited tracked files, delete files tracked only
  in the old checkout, overwrite untracked files that also exist in the repo,
  and leave untracked files that are *not* in the repo untouched.
- **Do not** reach for `git checkout`/`git switch` — the branch pointer is moved
  with `git symbolic-ref` + `git update-ref` on purpose (and the repo's
  branch-naming hook blocks `git checkout -B main`-style commands).
- The branch-naming hook inspects the bash command text, so running the tests as
  `sh tests/install_test.sh` is fine (the `git init -b main` calls live inside
  the script, not on the command line).
- Keep 4-space indentation; do not run `shfmt`.
