# Ring 7 (gh config + zsh helpers + parallel + z-a-auto sync) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers-extended-cc:subagent-driven-development (recommended) or superpowers-extended-cc:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Vendor upstream `hollow/dotfiles@c662cda`'s `gh/` config, the missing `gh-*`/`git-*`/`pr`/`debug` zsh helper scripts, and the `parallel` config; add `brew "parallel"` + the parallel `.zshrc` section; and sync the `z-a-auto` annex — all as a faithful subset.

**Architecture:** Almost entirely vendored-verbatim files copied from the upstream reference clone (so byte-fidelity is guaranteed by `cp`). The scripts in `zsh/` auto-join `PATH`/`FPATH` via the existing `.zshrc` bootstrap, so they need no wiring. The only edits are: one `Brewfile` line, one `.zshrc` section (parallel), and re-syncing one annex file. A final faithfulness audit confirms mode+content fidelity via `git ls-files -s`.

**Tech Stack:** zsh, Homebrew (`Brewfile`), zi / z-a-auto annex, gh CLI, GNU parallel, git helper subcommands.

**Spec:** `docs/superpowers/specs/2026-06-01-zsh-dotfiles-ring7-design.md`

---

## File Structure

- `gh/config.yml`, `gh/.gitignore` (create, mode 644).
- `parallel/.gitignore`, `parallel/will-cite`, `parallel/runs-without-willing-to-cite` (create, mode 644).
- `zsh/git-checkout-main`, `zsh/git-clone-clean-main`, `zsh/git-dmb-configure`, `zsh/git-is-dirty`, `zsh/git-merged-branches`, `zsh/git-submodules-fetch-latest` (create, mode **755**).
- `zsh/gh-repo-list`, `zsh/gh-clone-all`, `zsh/gh-remove-archived`, `zsh/pr` (create, mode **755**).
- `zsh/debug` (create, mode 644 — sourced, not executed).
- `zsh/z-a-auto/z-a-auto.plugin.zsh` (modify → byte-identical to upstream).
- `Brewfile` (modify — add `brew "parallel"`).
- `zsh/.zshrc` (modify — add the parallel section).

**Mode discipline:** the 10 git-*/gh-*/pr scripts are tracked `100755`; `debug`, `gh/*`, `parallel/*` are `100644`. Every task verifies mode+content together by diffing `git ls-files -s` against the upstream clone.

---

### Task 0: Set up upstream reference clone

**Goal:** Have a byte-exact copy of `hollow/dotfiles@c662cda` on disk so vendored files can be copied verbatim and diffed (including tracked file modes).

**Files:**
- Create: `/tmp/hollow-dotfiles` (ephemeral working clone, not part of the repo)

**Acceptance Criteria:**
- [ ] `git -C /tmp/hollow-dotfiles rev-parse --short HEAD` prints `c662cda`.

**Verify:** `git -C /tmp/hollow-dotfiles rev-parse --short HEAD` → `c662cda`

**Steps:**

- [ ] **Step 1: Clone and check out the pin**

```bash
rm -rf /tmp/hollow-dotfiles
git clone -q https://github.com/hollow/dotfiles /tmp/hollow-dotfiles
git -C /tmp/hollow-dotfiles checkout -q c662cda
```

- [ ] **Step 2: Confirm**

Run: `git -C /tmp/hollow-dotfiles rev-parse --short HEAD`
Expected: `c662cda`

(No commit — scratch clone.)

---

### Task 1: Vendor gh config

**Goal:** Vendor upstream's `gh/config.yml` and `gh/.gitignore` byte-identical (gh reads `~/.config/gh/` directly; no `.zshrc` change).

**Files:**
- Create: `gh/config.yml` (mode 644)
- Create: `gh/.gitignore` (mode 644)

**Acceptance Criteria:**
- [ ] `gh/config.yml` and `gh/.gitignore` are byte-identical to upstream, tracked as mode `100644`.

**Verify:** `git add gh/config.yml gh/.gitignore && diff <(cd /tmp/hollow-dotfiles && git ls-files -s gh/config.yml gh/.gitignore) <(git ls-files -s gh/config.yml gh/.gitignore)` → empty (mode+hash match)

**Steps:**

- [ ] **Step 1: Copy the files**

```bash
cd /Users/bene/src/remerge/dotfiles
mkdir -p gh
cp /tmp/hollow-dotfiles/gh/config.yml gh/config.yml
cp /tmp/hollow-dotfiles/gh/.gitignore gh/.gitignore
```

- [ ] **Step 2: Verify mode + content vs upstream**

```bash
git add gh/config.yml gh/.gitignore
diff <(cd /tmp/hollow-dotfiles && git ls-files -s gh/config.yml gh/.gitignore) \
     <(git ls-files -s gh/config.yml gh/.gitignore) && echo "GH CONFIG IDENTICAL"
```
Expected: `GH CONFIG IDENTICAL` (empty diff). Both lines start `100644`.

- [ ] **Step 3: Commit**

```bash
git commit -m "Ring 7: vendor gh config (config.yml, .gitignore)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: Vendor the missing git-* helper scripts

**Goal:** Vendor the six missing `git-*` helper scripts byte-identical, preserving the executable bit (they run as `git <sub>` subcommands).

**Files:**
- Create (mode 755): `zsh/git-checkout-main`, `zsh/git-clone-clean-main`, `zsh/git-dmb-configure`, `zsh/git-is-dirty`, `zsh/git-merged-branches`, `zsh/git-submodules-fetch-latest`

**Acceptance Criteria:**
- [ ] All six scripts are byte-identical to upstream, tracked as mode `100755`.
- [ ] `zsh -n` parses each script cleanly.

**Verify:** `for f in git-checkout-main git-clone-clean-main git-dmb-configure git-is-dirty git-merged-branches git-submodules-fetch-latest; do zsh -n zsh/$f || echo "PARSE FAIL $f"; done && git add zsh/git-* && diff <(cd /tmp/hollow-dotfiles && git ls-files -s zsh/git-checkout-main zsh/git-clone-clean-main zsh/git-dmb-configure zsh/git-is-dirty zsh/git-merged-branches zsh/git-submodules-fetch-latest) <(git ls-files -s zsh/git-checkout-main zsh/git-clone-clean-main zsh/git-dmb-configure zsh/git-is-dirty zsh/git-merged-branches zsh/git-submodules-fetch-latest)` → no PARSE FAIL, empty diff

**Steps:**

- [ ] **Step 1: Copy the six scripts and ensure exec bit**

```bash
cd /Users/bene/src/remerge/dotfiles
for f in git-checkout-main git-clone-clean-main git-dmb-configure git-is-dirty git-merged-branches git-submodules-fetch-latest; do
  cp /tmp/hollow-dotfiles/zsh/$f zsh/$f
  chmod 755 zsh/$f
done
```

- [ ] **Step 2: Parse-check and verify mode + content**

```bash
for f in git-checkout-main git-clone-clean-main git-dmb-configure git-is-dirty git-merged-branches git-submodules-fetch-latest; do
  zsh -n zsh/$f && echo "PARSE OK $f" || echo "PARSE FAIL $f"
done
git add zsh/git-checkout-main zsh/git-clone-clean-main zsh/git-dmb-configure zsh/git-is-dirty zsh/git-merged-branches zsh/git-submodules-fetch-latest
FILES="zsh/git-checkout-main zsh/git-clone-clean-main zsh/git-dmb-configure zsh/git-is-dirty zsh/git-merged-branches zsh/git-submodules-fetch-latest"
diff <(cd /tmp/hollow-dotfiles && git ls-files -s $FILES) <(git ls-files -s $FILES) && echo "GIT SCRIPTS IDENTICAL"
```
Expected: `PARSE OK` for all six, `GIT SCRIPTS IDENTICAL` (empty diff). Each line starts `100755`.

- [ ] **Step 3: Commit**

```bash
git commit -m "Ring 7: vendor missing git-* helper scripts

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 3: Vendor the gh-* helper scripts and pr

**Goal:** Vendor `gh-repo-list`, `gh-clone-all`, `gh-remove-archived`, and `pr` byte-identical, preserving the executable bit.

**Files:**
- Create (mode 755): `zsh/gh-repo-list`, `zsh/gh-clone-all`, `zsh/gh-remove-archived`, `zsh/pr`

**Acceptance Criteria:**
- [ ] All four scripts are byte-identical to upstream, tracked as mode `100755`.
- [ ] `zsh -n` parses each script cleanly.

**Verify:** `for f in gh-repo-list gh-clone-all gh-remove-archived pr; do zsh -n zsh/$f || echo "PARSE FAIL $f"; done && git add zsh/gh-repo-list zsh/gh-clone-all zsh/gh-remove-archived zsh/pr && diff <(cd /tmp/hollow-dotfiles && git ls-files -s zsh/gh-repo-list zsh/gh-clone-all zsh/gh-remove-archived zsh/pr) <(git ls-files -s zsh/gh-repo-list zsh/gh-clone-all zsh/gh-remove-archived zsh/pr)` → no PARSE FAIL, empty diff

**Steps:**

- [ ] **Step 1: Copy the four scripts and ensure exec bit**

```bash
cd /Users/bene/src/remerge/dotfiles
for f in gh-repo-list gh-clone-all gh-remove-archived pr; do
  cp /tmp/hollow-dotfiles/zsh/$f zsh/$f
  chmod 755 zsh/$f
done
```

- [ ] **Step 2: Parse-check and verify mode + content**

```bash
for f in gh-repo-list gh-clone-all gh-remove-archived pr; do
  zsh -n zsh/$f && echo "PARSE OK $f" || echo "PARSE FAIL $f"
done
git add zsh/gh-repo-list zsh/gh-clone-all zsh/gh-remove-archived zsh/pr
FILES="zsh/gh-repo-list zsh/gh-clone-all zsh/gh-remove-archived zsh/pr"
diff <(cd /tmp/hollow-dotfiles && git ls-files -s $FILES) <(git ls-files -s $FILES) && echo "GH SCRIPTS IDENTICAL"
```
Expected: `PARSE OK` for all four, `GH SCRIPTS IDENTICAL` (empty diff). Each line starts `100755`.

- [ ] **Step 3: Commit**

```bash
git commit -m "Ring 7: vendor gh-* helper scripts and pr

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 4: Add parallel (brew + config files + .zshrc section)

**Goal:** Install GNU parallel via Homebrew, vendor its citation-suppress config, and add the parallel `.zshrc` section so the bulk-clone helpers run without a citation notice.

**Files:**
- Create (mode 644): `parallel/.gitignore`, `parallel/will-cite`, `parallel/runs-without-willing-to-cite`
- Modify: `Brewfile` (add `brew "parallel"` between `brew "openssh"` and `brew "ripgrep"`)
- Modify: `zsh/.zshrc` (insert parallel section after the mise block's `zi auto has"mise" for jdx/mise`, before `# rsync`)

**Acceptance Criteria:**
- [ ] The three `parallel/*` files are byte-identical to upstream, tracked as mode `100644`.
- [ ] `Brewfile` contains `brew "parallel"` between `openssh` and `ripgrep`.
- [ ] `zsh/.zshrc` contains the 4-line parallel section byte-identical to upstream, between the mise block and the rsync block; `zsh -n zsh/.zshrc` passes.

**Verify:** `zsh -n zsh/.zshrc && git add parallel Brewfile zsh/.zshrc && diff <(cd /tmp/hollow-dotfiles && git ls-files -s parallel/.gitignore parallel/will-cite parallel/runs-without-willing-to-cite) <(git ls-files -s parallel/.gitignore parallel/will-cite parallel/runs-without-willing-to-cite) && diff <(grep -A3 '^# parallel: run commands' zsh/.zshrc) <(grep -A3 '^# parallel: run commands' /tmp/hollow-dotfiles/zsh/.zshrc)` → all empty

**Steps:**

- [ ] **Step 1: Copy the parallel config files**

```bash
cd /Users/bene/src/remerge/dotfiles
mkdir -p parallel
cp /tmp/hollow-dotfiles/parallel/.gitignore parallel/.gitignore
cp /tmp/hollow-dotfiles/parallel/will-cite parallel/will-cite
cp /tmp/hollow-dotfiles/parallel/runs-without-willing-to-cite parallel/runs-without-willing-to-cite
```

- [ ] **Step 2: Add the Brewfile entry**

Edit `Brewfile`, inserting between `brew "openssh"` and `brew "ripgrep"`:

```ruby
brew "openssh"
brew "parallel"
brew "ripgrep"
```

- [ ] **Step 3: Add the parallel `.zshrc` section**

In `zsh/.zshrc`, find the end of the mise block:

```zsh
zi auto has"mise" for jdx/mise
```

Immediately after it (and the blank line that follows), insert:

```zsh
# parallel: run commands in parallel
# https://www.gnu.org/software/parallel/
export PARALLEL_HOME="${XDG_CONFIG_HOME}/parallel"
mkdir -p ${PARALLEL_HOME}
```

so the result reads `… zi auto has"mise" for jdx/mise → [blank] → # parallel block → [blank] → # rsync …`.

- [ ] **Step 4: Verify**

```bash
zsh -n zsh/.zshrc && echo "PARSE OK"
git add parallel/.gitignore parallel/will-cite parallel/runs-without-willing-to-cite Brewfile zsh/.zshrc
PF="parallel/.gitignore parallel/will-cite parallel/runs-without-willing-to-cite"
diff <(cd /tmp/hollow-dotfiles && git ls-files -s $PF) <(git ls-files -s $PF) && echo "PARALLEL FILES IDENTICAL"
diff <(grep -A3 '^# parallel: run commands' zsh/.zshrc) \
     <(grep -A3 '^# parallel: run commands' /tmp/hollow-dotfiles/zsh/.zshrc) && echo "PARALLEL BLOCK IDENTICAL"
grep -nE '^brew "(openssh|parallel|ripgrep)"' Brewfile
```
Expected: `PARSE OK`, `PARALLEL FILES IDENTICAL`, `PARALLEL BLOCK IDENTICAL`, and `parallel` between `openssh` and `ripgrep`.

- [ ] **Step 5: Commit**

```bash
git commit -m "Ring 7: add parallel (brew, .zshrc section, citation-suppress config)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 5: Sync z-a-auto annex and vendor debug

**Goal:** Re-sync `zsh/z-a-auto/z-a-auto.plugin.zsh` to upstream (adds the `mise` handler case) and vendor `zsh/debug`, which the annex requires.

**Files:**
- Modify: `zsh/z-a-auto/z-a-auto.plugin.zsh` (→ byte-identical to upstream)
- Create (mode 644): `zsh/debug`

**Acceptance Criteria:**
- [ ] `zsh/z-a-auto/z-a-auto.plugin.zsh` is byte-identical to upstream (the `mise` case is present).
- [ ] `zsh/debug` is byte-identical to upstream, tracked as mode `100644`.
- [ ] `zsh -n` parses both files cleanly.

**Verify:** `zsh -n zsh/z-a-auto/z-a-auto.plugin.zsh && zsh -n zsh/debug && diff zsh/z-a-auto/z-a-auto.plugin.zsh /tmp/hollow-dotfiles/zsh/z-a-auto/z-a-auto.plugin.zsh && git add zsh/debug && diff <(cd /tmp/hollow-dotfiles && git ls-files -s zsh/debug) <(git ls-files -s zsh/debug)` → all empty

**Steps:**

- [ ] **Step 1: Re-sync the annex and vendor debug**

Overwrite the annex with upstream's (the only difference is the added `mise` case), and copy `debug`:

```bash
cd /Users/bene/src/remerge/dotfiles
cp /tmp/hollow-dotfiles/zsh/z-a-auto/z-a-auto.plugin.zsh zsh/z-a-auto/z-a-auto.plugin.zsh
cp /tmp/hollow-dotfiles/zsh/debug zsh/debug
```

- [ ] **Step 2: Verify parse, byte-identity, and debug mode**

```bash
zsh -n zsh/z-a-auto/z-a-auto.plugin.zsh && zsh -n zsh/debug && echo "PARSE OK"
diff zsh/z-a-auto/z-a-auto.plugin.zsh /tmp/hollow-dotfiles/zsh/z-a-auto/z-a-auto.plugin.zsh && echo "Z-A-AUTO IDENTICAL"
git add zsh/debug zsh/z-a-auto/z-a-auto.plugin.zsh
diff <(cd /tmp/hollow-dotfiles && git ls-files -s zsh/debug) <(git ls-files -s zsh/debug) && echo "DEBUG IDENTICAL"
# confirm the mise case landed:
grep -A2 '(mise)' zsh/z-a-auto/z-a-auto.plugin.zsh
```
Expected: `PARSE OK`, `Z-A-AUTO IDENTICAL`, `DEBUG IDENTICAL` (empty diffs), and the `mise) → mise use -g ${___ehid}` case present. `debug` line starts `100644`.

- [ ] **Step 3: Commit**

```bash
git commit -m "Ring 7: sync z-a-auto annex (mise case) and vendor debug helper

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 6: Faithfulness + Brewfile audit

**Goal:** Confirm the whole ring is a clean subset — no Brewfile deviations, valid Brewfile, valid zsh, every vendored file mode+content-identical to upstream, and the annex byte-identical.

**Files:**
- None (verification only)

**Acceptance Criteria:**
- [ ] `brew bundle list --file=./Brewfile --all` parses and lists `parallel`.
- [ ] `comm -23` of this repo's `brew`/`cask` lines against upstream's is empty.
- [ ] `zsh -n zsh/.zshrc` exits 0, and `zsh -n` passes for every new `zsh/*` script.
- [ ] Every vendored file (`gh/*`, `parallel/*`, the eleven `zsh/*` scripts) has matching mode+hash vs upstream (`git ls-files -s`); `z-a-auto.plugin.zsh` is byte-identical.

**Verify:** the Step 1 bash block → ends with `AUDIT CLEAN`

**Steps:**

- [ ] **Step 1: Run the faithfulness audit**

```bash
set -e
# 1. Brewfile parses and includes parallel
brew bundle list --file=./Brewfile --all | grep -qx parallel

# 2. No brew/cask deviation vs upstream
dev=$(comm -23 <(grep -E '^(brew|cask) ' Brewfile | sort -u) \
                <(grep -E '^(brew|cask) ' /tmp/hollow-dotfiles/Brewfile | sort -u))
[ -z "$dev" ] || { echo "DEVIATIONS:"; echo "$dev"; exit 1; }

# 3. zsh syntax: .zshrc + every new script
zsh -n zsh/.zshrc
for f in debug pr gh-repo-list gh-clone-all gh-remove-archived \
         git-checkout-main git-clone-clean-main git-dmb-configure \
         git-is-dirty git-merged-branches git-submodules-fetch-latest; do
  zsh -n zsh/$f
done

# 4. mode + content identical to upstream for every vendored file
FILES="gh/config.yml gh/.gitignore \
parallel/.gitignore parallel/will-cite parallel/runs-without-willing-to-cite \
zsh/debug zsh/pr zsh/gh-repo-list zsh/gh-clone-all zsh/gh-remove-archived \
zsh/git-checkout-main zsh/git-clone-clean-main zsh/git-dmb-configure \
zsh/git-is-dirty zsh/git-merged-branches zsh/git-submodules-fetch-latest"
diff <(cd /tmp/hollow-dotfiles && git ls-files -s $FILES) <(git ls-files -s $FILES)

# 5. annex byte-identical
diff zsh/z-a-auto/z-a-auto.plugin.zsh /tmp/hollow-dotfiles/zsh/z-a-auto/z-a-auto.plugin.zsh

echo "AUDIT CLEAN"
```
Expected: prints `AUDIT CLEAN` with no `DEVIATIONS` and no diff output.

- [ ] **Step 2: (Optional) Manual smoke test on a fresh shell**

After `brew bundle install`:
```bash
command -v parallel                       # resolves
gh-repo-list --limit 1 >/dev/null         # gh tooling works (requires gh auth)
git is-dirty; echo "exit=$?"              # git-* subcommand resolves
DOT_DEBUG=1 debug hello                   # emits a [func] hello message
type pr                                   # pr resolves as a command
```

(No commit — verification only.)

---

## Notes for the implementer

- **Order:** Task 0 first (everything copies/diffs against `/tmp/hollow-dotfiles`). Task 4 (Brewfile + `.zshrc`) and Task 5 (annex) touch shared files only within their own task; Tasks 1–3 add new files only. Run sequentially; Task 6 last.
- **Modes matter:** the 10 git-*/gh-*/pr scripts must be `100755`; `debug`, `gh/*`, `parallel/*` must be `100644`. The `git ls-files -s` diffs catch any mode drift — do not skip them.
- **Prefer `cp` over hand-typing** every vendored file (byte-identical is mandatory). For the annex, `cp` the whole upstream file (the only delta is the `mise` case).
- **Do not add** any other upstream `zsh/` helper, the parallel section's unrelated neighbors, or any `.zshrc` change beyond the parallel section.
