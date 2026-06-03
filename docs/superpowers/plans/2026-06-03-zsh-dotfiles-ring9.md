# Remerge dotfiles — Ring 9 (claude + opentofu/.gitignore fix) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers-extended-cc:subagent-driven-development (recommended) or superpowers-extended-cc:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Vendor upstream `hollow/dotfiles@cef10b6`'s claude tool section (`cask "claude"` + the trimmed `.zshrc` exports) as a faithful subset, and create the `opentofu/.gitignore` missed in Ring 8.

**Architecture:** One vendored-verbatim file (`opentofu/.gitignore`, `cp` from the upstream reference clone guarantees byte-fidelity) plus two edits to existing files — a `Brewfile` cask line and a trimmed `.zshrc` claude section inserted at its upstream-relative position. A final audit confirms mode+content fidelity via `git ls-files -s` and a Brewfile/`.zshrc` faithfulness check.

**Tech Stack:** zsh, Homebrew Bundle, git.

**Spec:** `docs/superpowers/specs/2026-06-03-zsh-dotfiles-ring9-design.md`

**Faithfulness invariant:** Every vendored file is byte-identical to upstream at `cef10b6` with matching tracked git mode. `zsh/.zshrc` stays a strict line-subset: the four claude lines are byte-identical upstream lines (333–336); the two `cp` lines (337–338) are intentionally omitted (the only deviation, documented in the spec). `cask "claude"` exists upstream → no Brewfile deviation.

---

### Task 0: Set up upstream reference clone

**Goal:** Have a byte-exact copy of `hollow/dotfiles@cef10b6` on disk for verbatim copying and diffing (including tracked modes).

**Files:**
- Create: `/tmp/hollow-dotfiles` (ephemeral working clone — not part of the repo)

**Acceptance Criteria:**
- [ ] `git -C /tmp/hollow-dotfiles rev-parse --short HEAD` prints `cef10b6`.

**Verify:** `git -C /tmp/hollow-dotfiles rev-parse --short HEAD` → `cef10b6`

**Steps:**

- [ ] **Step 1: Clone and check out the pin**

```bash
rm -rf /tmp/hollow-dotfiles
git clone -q https://github.com/hollow/dotfiles /tmp/hollow-dotfiles
git -C /tmp/hollow-dotfiles checkout -q cef10b6
```

- [ ] **Step 2: Confirm the pin**

Run: `git -C /tmp/hollow-dotfiles rev-parse --short HEAD`
Expected: `cef10b6`

(No commit — scratch clone.)

---

### Task 1: Create opentofu/.gitignore (Ring 8 fix)

**Goal:** Vendor `opentofu/.gitignore` byte-identical to upstream (mode `100644`), completing the opentofu port from Ring 8.

**Files:**
- Create: `opentofu/.gitignore`

**Acceptance Criteria:**
- [ ] `opentofu/.gitignore` is byte-identical to upstream, single line `credentials.tfrc.json`.
- [ ] Tracked mode is `100644` and the blob hash matches upstream.

**Verify:** `git add opentofu/.gitignore && diff <(cd /tmp/hollow-dotfiles && git ls-files -s opentofu/.gitignore) <(git ls-files -s opentofu/.gitignore)` → empty diff (same mode + blob `58ca1b7`)

**Steps:**

- [ ] **Step 1: Copy verbatim from the upstream clone**

```bash
cp /tmp/hollow-dotfiles/opentofu/.gitignore opentofu/.gitignore
```

- [ ] **Step 2: Verify mode + content vs upstream**

```bash
git add opentofu/.gitignore
diff <(cd /tmp/hollow-dotfiles && git ls-files -s opentofu/.gitignore) <(git ls-files -s opentofu/.gitignore) && echo "OPENTOFU GITIGNORE IDENTICAL"
```
Expected: `OPENTOFU GITIGNORE IDENTICAL` (both sides show mode `100644`, blob `58ca1b7955c723aa9e14337e2e3c9e68cd181adc`).

- [ ] **Step 3: Commit**

```bash
git commit -m "Ring 9: add opentofu/.gitignore (missed in Ring 8)"
```

---

### Task 2: Add the claude tool section (cask + .zshrc)

**Goal:** Add `cask "claude"` to the `Brewfile` and the trimmed claude section to `zsh/.zshrc`, both byte-identical to upstream at their upstream-relative positions.

**Files:**
- Modify: `Brewfile` (insert `cask "claude"` after `cask "1password-cli"`)
- Modify: `zsh/.zshrc` (insert claude section between the `bat` block and `# dircolors`)

**Acceptance Criteria:**
- [ ] `Brewfile` has `cask "claude"` directly after `cask "1password-cli"` and before `cask "font-meslo-lg-nerd-font"`.
- [ ] The claude `.zshrc` section's four lines are byte-identical to upstream lines 333–336, between the `bat` block and `# dircolors`.
- [ ] The omitted `cp`/`claude_desktop_config.json` lines are absent from `zsh/.zshrc`.
- [ ] `zsh -n zsh/.zshrc` passes.

**Verify:** `zsh -n zsh/.zshrc && diff <(sed -n '/^# claude: AI assistant by Anthropic/,/^export ENABLE_CLAUDEAI_MCP_SERVERS=true/p' zsh/.zshrc) <(sed -n '/^# claude: AI assistant by Anthropic/,/^export ENABLE_CLAUDEAI_MCP_SERVERS=true/p' /tmp/hollow-dotfiles/zsh/.zshrc) && ! grep -q 'claude_desktop_config.json' zsh/.zshrc && grep -qx 'cask "claude"' Brewfile` → all pass

**Steps:**

- [ ] **Step 1: Insert `cask "claude"` in the Brewfile**

Find this block:

```ruby
cask "1password-cli"
cask "font-meslo-lg-nerd-font"
```

Replace with (upstream cask order is `1password`, `1password-cli`, `adguard`, `claude`, `font-meslo…`; `adguard` is un-ported, so `claude` lands right after `1password-cli`):

```ruby
cask "1password-cli"
cask "claude"
cask "font-meslo-lg-nerd-font"
```

- [ ] **Step 2: Insert the claude section in zsh/.zshrc**

Find this block (end of the `bat` section, start of `dircolors`):

```zsh
zi auto has"bat" wait for bat

# dircolors: setup colors for ls and friends
```

Replace with:

```zsh
zi auto has"bat" wait for bat

# claude: AI assistant by Anthropic
# https://claude.ai
export CLAUDE_CODE_NEW_INIT=1
export ENABLE_CLAUDEAI_MCP_SERVERS=true

# dircolors: setup colors for ls and friends
```

- [ ] **Step 3: Parse-check + verify claude block vs upstream + Brewfile entry + cp absence**

```bash
zsh -n zsh/.zshrc && echo "ZSHRC PARSES"
diff <(sed -n '/^# claude: AI assistant by Anthropic/,/^export ENABLE_CLAUDEAI_MCP_SERVERS=true/p' zsh/.zshrc) \
     <(sed -n '/^# claude: AI assistant by Anthropic/,/^export ENABLE_CLAUDEAI_MCP_SERVERS=true/p' /tmp/hollow-dotfiles/zsh/.zshrc) && echo "CLAUDE BLOCK IDENTICAL"
! grep -q 'claude_desktop_config.json' zsh/.zshrc && echo "CP LINES OMITTED"
grep -qx 'cask "claude"' Brewfile && echo "CASK PRESENT"
```
Expected: `ZSHRC PARSES`, `CLAUDE BLOCK IDENTICAL`, `CP LINES OMITTED`, `CASK PRESENT`.

- [ ] **Step 4: Commit**

```bash
git add Brewfile zsh/.zshrc
git commit -m "Ring 9: add claude (cask + trimmed .zshrc section)"
```

---

### Task 3: Faithfulness audit

**Goal:** Confirm the whole ring is a faithful subset of upstream at `cef10b6`: vendored file mode+content matches, the `.zshrc` is a strict line-subset, and the Brewfile has no deviations.

**Files:**
- (No file changes — verification only.)

**Acceptance Criteria:**
- [ ] `opentofu/.gitignore` mode+blob match upstream via `git ls-files -s`.
- [ ] Every non-blank line of our `zsh/.zshrc` exists in upstream's `zsh/.zshrc`.
- [ ] `zsh -n zsh/.zshrc` passes.
- [ ] Every `brew`/`cask` line in our `Brewfile` exists in upstream's `Brewfile` (empty `comm -23`).
- [ ] `git status` is clean (no uncommitted changes from prior tasks).

**Verify:** the audit script below prints all four OK markers and no `EXTRA` lines.

**Steps:**

- [ ] **Step 1: Vendored file fidelity**

```bash
diff <(cd /tmp/hollow-dotfiles && git ls-files -s opentofu/.gitignore) <(git ls-files -s opentofu/.gitignore) && echo "VENDORED OK"
```
Expected: `VENDORED OK`.

- [ ] **Step 2: `.zshrc` strict line-subset + parse**

```bash
zsh -n zsh/.zshrc && echo "ZSHRC PARSES"
# Every non-blank line of ours must exist in upstream's .zshrc:
comm -23 \
  <(grep -vE '^[[:space:]]*$' zsh/.zshrc | sort -u) \
  <(grep -vE '^[[:space:]]*$' /tmp/hollow-dotfiles/zsh/.zshrc | sort -u) \
  | sed 's/^/EXTRA: /'
echo "ZSHRC SUBSET CHECK DONE"
```
Expected: `ZSHRC PARSES`, no `EXTRA:` lines, `ZSHRC SUBSET CHECK DONE`.

- [ ] **Step 3: Brewfile has no deviations**

```bash
brew bundle list --file=./Brewfile --all >/dev/null && echo "BREWFILE PARSES"
comm -23 \
  <(grep -E '^(brew|cask) ' Brewfile | sort -u) \
  <(grep -E '^(brew|cask) ' /tmp/hollow-dotfiles/Brewfile | sort -u) \
  | sed 's/^/EXTRA: /'
echo "BREWFILE SUBSET CHECK DONE"
```
Expected: `BREWFILE PARSES`, no `EXTRA:` lines, `BREWFILE SUBSET CHECK DONE`.
(If `brew` is unavailable in the execution environment, skip the parse line and note it; the `comm` check is the authoritative faithfulness gate.)

- [ ] **Step 4: Working tree clean**

```bash
git status --short && echo "STATUS DONE"
```
Expected: no output before `STATUS DONE` (all changes committed in Tasks 1–2).

(No commit — verification only.)

---

## Notes

- The README is intentionally **not** updated — it is a curated subset and prior rings did not document every tool section (Ring 8 added no README change).
- `git/ignore` is already byte-identical to upstream (`**/.claude/settings.local.json`); no sync needed.
- The `vscode "anthropic.claude-code"` entry and `.claude/skills/macos-defaults/SKILL.md` are out of scope (see spec).
