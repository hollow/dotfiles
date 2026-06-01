# Ring 6 (mise + age + sops) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers-extended-cc:subagent-driven-development (recommended) or superpowers-extended-cc:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Port upstream `hollow/dotfiles@1c3018c`'s `mise`, `age`, and `sops` sections into this dotfiles repo as a faithful subset (mise with an empty global tool list).

**Architecture:** Three tool sections added at their upstream-relative positions. `mise` adds a `.zshrc` block, a Brewfile brew, and a vendored `mise/config.toml` (with the `[tools]` entries deleted). `age` is brew-only. `sops` adds a `.zshrc` block and a Brewfile brew (no vendored file). A final faithfulness/syntax audit confirms the subset invariant.

**Tech Stack:** zsh, Homebrew (`Brewfile`), zi plugin manager, mise (runtime/tool manager), age (encryption), sops (encrypted-file editor), TOML.

**Spec:** `docs/superpowers/specs/2026-06-01-zsh-dotfiles-ring6-design.md`

---

## File Structure

- `Brewfile` (modify) — add `brew "age"`, `brew "mise"`, `brew "sops"` at their alphabetical slots.
- `zsh/.zshrc` (modify) — add the `mise` block (between ncdu and rsync) and the `sops` block (between rsync and ssh).
- `mise/config.toml` (create) — upstream's, with the `[tools]` entries removed (header-only).

One intentional deletion (per spec): mise's `[tools]` entries are emptied. `sops/.gitignore` is vendored byte-identical to upstream.

---

### Task 0: Set up upstream reference clone

**Goal:** Have a byte-exact copy of `hollow/dotfiles@1c3018c` on disk so vendored content can be derived verbatim and diffed.

**Files:**
- Create: `/tmp/hollow-dotfiles` (ephemeral working clone, not part of the repo)

**Acceptance Criteria:**
- [ ] `/tmp/hollow-dotfiles` exists and `git -C /tmp/hollow-dotfiles rev-parse --short HEAD` prints `1c3018c`.

**Verify:** `git -C /tmp/hollow-dotfiles rev-parse --short HEAD` → `1c3018c`

**Steps:**

- [ ] **Step 1: Clone upstream and check out the pinned commit**

```bash
rm -rf /tmp/hollow-dotfiles
git clone -q https://github.com/hollow/dotfiles /tmp/hollow-dotfiles
git -C /tmp/hollow-dotfiles checkout -q 1c3018c
```

- [ ] **Step 2: Confirm the pinned commit**

Run: `git -C /tmp/hollow-dotfiles rev-parse --short HEAD`
Expected: `1c3018c`

(No commit — this is a scratch clone, not a repo change.)

---

### Task 1: Add the mise section

**Goal:** Install mise via Homebrew, add upstream's mise `.zshrc` block, and vendor `mise/config.toml` with an empty `[tools]` table.

**Files:**
- Modify: `Brewfile` (add `brew "mise"` between `brew "make"` and `brew "ncdu"`)
- Modify: `zsh/.zshrc` (insert mise block immediately after the ncdu block's `link ncduignore .ncduignore`, before `# rsync`)
- Create: `mise/config.toml` (upstream's, with `[tools]` entries removed → header only)

**Acceptance Criteria:**
- [ ] `Brewfile` contains `brew "mise"` alphabetically between `make` and `ncdu`.
- [ ] `zsh/.zshrc` contains the 10-line mise block exactly as upstream, between the ncdu block and the rsync block.
- [ ] `mise/config.toml` equals upstream's with exactly the six `[tools]` entry lines removed (only `[tools]` remains).
- [ ] Every added `.zshrc` line is byte-identical to a line in `/tmp/hollow-dotfiles/zsh/.zshrc`.
- [ ] `zsh -n zsh/.zshrc` exits 0.

**Verify:** `zsh -n zsh/.zshrc && diff <(grep -A9 '^# mise: dev tools' zsh/.zshrc) <(grep -A9 '^# mise: dev tools' /tmp/hollow-dotfiles/zsh/.zshrc) && diff <(grep -v ' = ' /tmp/hollow-dotfiles/mise/config.toml) mise/config.toml` → all empty (exit 0)

**Steps:**

- [ ] **Step 1: Create `mise/config.toml` (header-only `[tools]`)**

Derive it from upstream by stripping the tool-entry lines (every entry contains ` = `):

```bash
cd /Users/bene/src/remerge/dotfiles
mkdir -p mise
grep -v ' = ' /tmp/hollow-dotfiles/mise/config.toml > mise/config.toml
```

The resulting `mise/config.toml` must be exactly:

```toml
[tools]
```

- [ ] **Step 2: Add the Brewfile entry**

Edit `Brewfile`, inserting a new line between `brew "make"` and `brew "ncdu"`:

```ruby
brew "make"
brew "mise"
brew "ncdu"
```

- [ ] **Step 3: Add the mise `.zshrc` block**

In `zsh/.zshrc`, find the end of the ncdu section:

```zsh
# ncdu: disk usage analyzer
# https://dev.yorhel.nl/ncdu
link ncduignore .ncduignore
```

Immediately after `link ncduignore .ncduignore` (and the blank line that follows it), insert:

```zsh
# mise: dev tools, env vars, task runner
# https://github.com/jdx/mise
export MISE_SOPS_AGE_KEY_FILE="${XDG_CONFIG_HOME}/sops/age/keys.txt"

:mise-load() {
    local _mise_cmd_not_found
    eval "$(mise activate zsh)"
}

zi auto has"mise" for jdx/mise
```

so the result reads `… link ncduignore .ncduignore → [blank] → # mise block → [blank] → # rsync …`.

- [ ] **Step 4: Verify zsh parses, block matches upstream, config is upstream-minus-tools**

Run:
```bash
zsh -n zsh/.zshrc && echo "PARSE OK"
diff <(grep -A9 '^# mise: dev tools' zsh/.zshrc) \
     <(grep -A9 '^# mise: dev tools' /tmp/hollow-dotfiles/zsh/.zshrc) \
  && echo "BLOCK IDENTICAL"
diff <(grep -v ' = ' /tmp/hollow-dotfiles/mise/config.toml) mise/config.toml \
  && echo "CONFIG = UPSTREAM MINUS TOOLS"
```
Expected: `PARSE OK`, `BLOCK IDENTICAL`, `CONFIG = UPSTREAM MINUS TOOLS` (empty diffs).

- [ ] **Step 5: Commit**

```bash
git add Brewfile zsh/.zshrc mise/config.toml
git commit -m "Ring 6: add mise (brew, .zshrc block, empty-tools config)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: Add the age + sops sections

**Goal:** Install `age` and `sops` via Homebrew, add upstream's sops `.zshrc` block (the `SOPS_AGE_KEY_FILE` export), and vendor `sops/.gitignore` byte-identical. `age` is brew-only.

**Files:**
- Create: `sops/.gitignore` (byte-identical copy from upstream — `age/keys.txt`)
- Modify: `Brewfile` (add `brew "age"` as the first brew, before `brew "atool"`; add `brew "sops"` between `brew "rsync"` and `brew "sponge"`)
- Modify: `zsh/.zshrc` (insert sops block immediately after the rsync block's `zi auto wait for OMZP::rsync`, before `# ssh: secure shell`)

**Acceptance Criteria:**
- [ ] `Brewfile` contains `brew "age"` as the first `brew` line (before `atool`) and `brew "sops"` between `rsync` and `sponge`.
- [ ] `zsh/.zshrc` contains the 3-line sops block exactly as upstream, between the rsync block and the ssh block.
- [ ] Every added `.zshrc` line is byte-identical to a line in `/tmp/hollow-dotfiles/zsh/.zshrc`.
- [ ] `sops/.gitignore` is byte-identical to upstream (`age/keys.txt`).
- [ ] `zsh -n zsh/.zshrc` exits 0.

**Verify:** `zsh -n zsh/.zshrc && diff <(grep -A2 '^# sops: editor of encrypted' zsh/.zshrc) <(grep -A2 '^# sops: editor of encrypted' /tmp/hollow-dotfiles/zsh/.zshrc) && diff sops/.gitignore /tmp/hollow-dotfiles/sops/.gitignore` → all pass (exit 0)

**Steps:**

- [ ] **Step 1: Vendor `sops/.gitignore` and add the Brewfile entries**

Copy the gitignore verbatim from upstream:

```bash
cd /Users/bene/src/remerge/dotfiles
mkdir -p sops
cp /tmp/hollow-dotfiles/sops/.gitignore sops/.gitignore
```

Then edit `Brewfile`. Add `brew "age"` as the very first brew line (it sorts before `atool`):

```ruby
brew "age"
brew "atool"
```

And insert `brew "sops"` between `brew "rsync"` and `brew "sponge"`:

```ruby
brew "rsync"
brew "sops"
brew "sponge"
```

- [ ] **Step 2: Add the sops `.zshrc` block**

In `zsh/.zshrc`, find the end of the rsync block:

```zsh
# rsync: fast incremental file transfer
# https://rsync.samba.org
zi auto wait for OMZP::rsync
```

Immediately after `zi auto wait for OMZP::rsync` (and the blank line that follows it), insert:

```zsh
# sops: editor of encrypted files (age, gpg, cloud KMS)
# https://github.com/getsops/sops
export SOPS_AGE_KEY_FILE="${XDG_CONFIG_HOME}/sops/age/keys.txt"
```

so the result reads `… zi auto wait for OMZP::rsync → [blank] → # sops block → [blank] → # ssh …`. (The mise block from Task 1 is earlier, between ncdu and rsync — do not confuse the two insertion points.)

- [ ] **Step 3: Verify parse, block match, and vendored gitignore**

Run:
```bash
zsh -n zsh/.zshrc && echo "PARSE OK"
diff <(grep -A2 '^# sops: editor of encrypted' zsh/.zshrc) \
     <(grep -A2 '^# sops: editor of encrypted' /tmp/hollow-dotfiles/zsh/.zshrc) \
  && echo "BLOCK IDENTICAL"
diff sops/.gitignore /tmp/hollow-dotfiles/sops/.gitignore && echo "GITIGNORE IDENTICAL"
# age + sops exist in upstream Brewfile (no deviation):
grep -qx 'brew "age"'  /tmp/hollow-dotfiles/Brewfile && echo "AGE IN UPSTREAM"
grep -qx 'brew "sops"' /tmp/hollow-dotfiles/Brewfile && echo "SOPS IN UPSTREAM"
```
Expected: `PARSE OK`, `BLOCK IDENTICAL`, `GITIGNORE IDENTICAL`, `AGE IN UPSTREAM`, `SOPS IN UPSTREAM`.

- [ ] **Step 4: Commit**

```bash
git add Brewfile zsh/.zshrc sops/.gitignore
git commit -m "Ring 6: add age + sops (brews + sops .zshrc block)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 3: Faithfulness + Brewfile audit

**Goal:** Confirm the whole ring is a clean subset — no Brewfile deviations, valid Brewfile, valid zsh, and the only file-level deviation is the one intended deletion (emptied `mise/config.toml` `[tools]`); `sops/.gitignore` is vendored byte-identical.

**Files:**
- None (verification only)

**Acceptance Criteria:**
- [ ] `brew bundle list --file=./Brewfile --all` parses without error and lists `age`, `mise`, `sops`.
- [ ] `comm -23` of this repo's `brew`/`cask` lines against upstream's is empty (no entry exists here that isn't upstream).
- [ ] `zsh -n zsh/.zshrc` exits 0.
- [ ] `mise/config.toml` equals upstream's minus the `[tools]` entries; `sops/.gitignore` is byte-identical to upstream.

**Verify:** `bash` block in Step 1 below → ends with `AUDIT CLEAN`

**Steps:**

- [ ] **Step 1: Run the faithfulness audit**

```bash
set -e
# 1. Brewfile parses and includes the new entries
for f in age mise sops; do brew bundle list --file=./Brewfile --all | grep -qx "$f"; done

# 2. No brew/cask deviation vs upstream (our lines ⊆ upstream lines)
ours=$(grep -E '^(brew|cask) ' Brewfile | sort -u)
theirs=$(grep -E '^(brew|cask) ' /tmp/hollow-dotfiles/Brewfile | sort -u)
dev=$(comm -23 <(printf '%s\n' "$ours") <(printf '%s\n' "$theirs"))
[ -z "$dev" ] || { echo "DEVIATIONS:"; echo "$dev"; exit 1; }

# 3. zsh syntax
zsh -n zsh/.zshrc

# 4. mise/config.toml = upstream minus the tool entries
diff <(grep -v ' = ' /tmp/hollow-dotfiles/mise/config.toml) mise/config.toml

# 5. sops/.gitignore vendored byte-identical to upstream
diff sops/.gitignore /tmp/hollow-dotfiles/sops/.gitignore

echo "AUDIT CLEAN"
```
Expected: prints `AUDIT CLEAN` with no `DEVIATIONS` and no diff output.

- [ ] **Step 2: (Optional) Manual smoke test on a fresh shell**

After `brew bundle install`, open a new shell and confirm:
```bash
command -v age && command -v mise && command -v sops    # all resolve
echo "$SOPS_AGE_KEY_FILE"                                # ~/.config/sops/age/keys.txt
echo "$MISE_SOPS_AGE_KEY_FILE"                           # ~/.config/sops/age/keys.txt
mise ls                                                  # no global tools listed
```

(No commit — verification only.)

---

## Notes for the implementer

- **Order matters:** Task 0 first (later tasks derive/diff against `/tmp/hollow-dotfiles`). Tasks 1 and 2 both edit `Brewfile` and `zsh/.zshrc` — run them sequentially to avoid edit conflicts. Task 3 last.
- **Two insertion points in `.zshrc`:** mise goes between ncdu and rsync; sops goes between rsync and ssh. Don't merge them.
- **Do not add** any mise `[tools]` entries or any tool not named here.
- **mise/config.toml** must be exactly `[tools]\n` (one line). Deriving it via `grep -v ' = '` from upstream guarantees byte-fidelity of the header.
