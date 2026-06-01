# Ring 4 (ghostty, tailscale, 1Password) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers-extended-cc:subagent-driven-development (recommended) or superpowers-extended-cc:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Port the `ghostty` terminal, `tailscale` (CLI + app), and `1Password` (app + `op` CLI) from `hollow/dotfiles@5fd2f15` into the remerge dotfiles, as a faithful subset with no deviations.

**Architecture:** Add the matching `brew`/`cask` entries to `Brewfile` (kept alphabetical); vendor config files byte-identical from upstream; insert the upstream `.zshrc` blocks as a strict line-subset at their upstream-relative positions. The repo lives at `~/.config`, so vendored directories map directly (`ghostty/` → `~/.config/ghostty/`, `op/` → `~/.config/op/`).

**Tech Stack:** Homebrew bundle (casks + the `op`/`code`-style CLI gating), zsh + ZI plugin manager (z-a-auto + z-a-eval conventions), Ghostty terminal, Tailscale, 1Password + `op` CLI.

**Spec:** `docs/superpowers/specs/2026-05-31-zsh-dotfiles-ring4-design.md`

**Upstream reference checkout:** `/Users/bene/src/hollow/dotfiles` (currently at the pinned commit `5fd2f15`). All "vendor verbatim" steps copy from there and verify with `diff`.

**Conventions for every task:** This is config vendoring, not application code — there is no unit-test suite. Each task's "test" is its **Verify** command (a `diff`, a `zsh -n` parse, or a `brew bundle list` parse). Make the change, run Verify, then commit. Casks are NOT installed during verification (`brew bundle install` is a manual post-merge step); we only verify the Brewfile parses and entries match upstream.

---

### Task 1: tailscale (CLI + app)

**Goal:** Add the `tailscale` CLI (brew) and the Tailscale macOS app (cask). No config, no `.zshrc` block.

**Files:**
- Modify: `Brewfile`

**Acceptance Criteria:**
- [ ] `Brewfile` contains `brew "tailscale"` (between `brew "starship"` and `brew "tmux"`).
- [ ] `Brewfile` contains `cask "tailscale-app"`.
- [ ] The `brew "..."` lines and the `cask "..."` lines each remain alphabetical.
- [ ] Both entries exist in the upstream `Brewfile`.
- [ ] `brew bundle list --file=./Brewfile --all` parses without error.

**Verify:** `grep -q '^brew "tailscale"$' Brewfile && grep -q '^cask "tailscale-app"$' Brewfile && brew bundle list --file=./Brewfile --all >/dev/null && echo OK` → prints `OK`

**Steps:**

- [ ] **Step 1: Add the brew entry.**

Insert `brew "tailscale"` into the brew block between `brew "starship"` and `brew "tmux"` (keeping the brew block alphabetical).

- [ ] **Step 2: Add the cask entry.**

The cask block currently contains only `cask "font-meslo-lg-nerd-font"`. Add `cask "tailscale-app"` after it (it sorts after `font-...`). Result so far: `font-meslo-lg-nerd-font`, `tailscale-app`.

- [ ] **Step 3: Verify entries, alphabetical order, upstream match, and parse.**

Run:
```bash
grep -q '^brew "tailscale"$' Brewfile \
  && grep -q '^cask "tailscale-app"$' Brewfile \
  && grep -q '^brew "tailscale"$' /Users/bene/src/hollow/dotfiles/Brewfile \
  && grep -q '^cask "tailscale-app"$' /Users/bene/src/hollow/dotfiles/Brewfile \
  && grep '^brew ' Brewfile | sort -c \
  && grep '^cask ' Brewfile | sort -c \
  && brew bundle list --file=./Brewfile --all >/dev/null && echo OK
```
Expected: `OK`

- [ ] **Step 4: Confirm no other files changed.**

Run: `git status --porcelain` — only `Brewfile` should appear as modified.

- [ ] **Step 5: Commit.**

```bash
git add Brewfile
git commit -m "Ring 4: add tailscale (CLI + app)"
```

---

### Task 2: ghostty (terminal)

**Goal:** Install the `ghostty` terminal (cask), vendor its config, and add the upstream `.zshrc` PATH line.

**Files:**
- Create: `ghostty/config`
- Modify: `Brewfile`
- Modify: `zsh/.zshrc`

**Acceptance Criteria:**
- [ ] `ghostty/config` is byte-identical to upstream.
- [ ] `Brewfile` contains `cask "ghostty"`, alphabetically placed (between `font-meslo-lg-nerd-font` and `tailscale-app`).
- [ ] `zsh/.zshrc` contains the ghostty block, inserted between the `eza` block and the `git` block.
- [ ] `zsh -n zsh/.zshrc` passes.

**Verify:** `diff /Users/bene/src/hollow/dotfiles/ghostty/config ghostty/config && zsh -n zsh/.zshrc && echo OK` → prints `OK`

**Steps:**

- [ ] **Step 1: Vendor the config verbatim.**

Run:
```bash
mkdir -p ghostty
cp /Users/bene/src/hollow/dotfiles/ghostty/config ghostty/config
```

- [ ] **Step 2: Verify byte-identical.**

Run: `diff /Users/bene/src/hollow/dotfiles/ghostty/config ghostty/config && echo IDENTICAL`
Expected: `IDENTICAL`

- [ ] **Step 3: Add the cask entry.**

Insert `cask "ghostty"` between `cask "font-meslo-lg-nerd-font"` and `cask "tailscale-app"` (keeping the cask block alphabetical).

- [ ] **Step 4: Add the ghostty `.zshrc` block.**

In `zsh/.zshrc`, immediately after the eza block (the line `zi auto has"eza" wait for eza`) and before the `# git:` block, insert (one blank line separating blocks, matching the file's style):

```zsh
# ghostty
add path "${GHOSTTY_BIN_DIR}"
```

This is byte-identical to upstream — confirm with `grep -n -A1 '^# ghostty$' /Users/bene/src/hollow/dotfiles/zsh/.zshrc`. Do not modify any other part of `.zshrc`.

- [ ] **Step 5: Verify parse, placement, and faithfulness.**

Run:
```bash
diff /Users/bene/src/hollow/dotfiles/ghostty/config ghostty/config \
  && grep -q '^cask "ghostty"$' Brewfile \
  && grep '^cask ' Brewfile | sort -c \
  && grep -q '^add path "${GHOSTTY_BIN_DIR}"$' zsh/.zshrc \
  && zsh -n zsh/.zshrc && echo OK
```
Expected: `OK`. Also eyeball placement: `grep -n -A3 'has"eza" wait for eza' zsh/.zshrc` should show the eza line, a blank line, `# ghostty`, then `add path "${GHOSTTY_BIN_DIR}"`.

- [ ] **Step 6: Commit.**

```bash
git add ghostty/config Brewfile zsh/.zshrc
git commit -m "Ring 4: add ghostty + config"
```

---

### Task 3: 1Password (app + op CLI)

**Goal:** Install the 1Password app and the `op` CLI (both casks), vendor the `op` config-dir `.gitignore`, and add the `op` completion `.zshrc` block.

**Files:**
- Create: `op/.gitignore`
- Modify: `Brewfile`
- Modify: `zsh/.zshrc`

**Acceptance Criteria:**
- [ ] `op/.gitignore` is byte-identical to upstream (the `*` / `!.gitignore` pattern).
- [ ] `Brewfile` contains `cask "1password"` and `cask "1password-cli"`, alphabetically placed at the top of the cask block.
- [ ] `zsh/.zshrc` contains the 1Password block, inserted between the `brew` block and the `bat` block.
- [ ] `zsh -n zsh/.zshrc` passes.
- [ ] Whole-ring audit: every `brew`/`cask` entry in our Brewfile exists in upstream's (no deviations).

**Verify:** `diff /Users/bene/src/hollow/dotfiles/op/.gitignore op/.gitignore && zsh -n zsh/.zshrc && echo OK` → prints `OK`

**Steps:**

- [ ] **Step 1: Vendor the op `.gitignore` verbatim.**

Run:
```bash
mkdir -p op
cp /Users/bene/src/hollow/dotfiles/op/.gitignore op/.gitignore
```
For reference, its content is exactly:
```
*
!.gitignore
```

- [ ] **Step 2: Verify byte-identical.**

Run: `diff /Users/bene/src/hollow/dotfiles/op/.gitignore op/.gitignore && echo IDENTICAL`
Expected: `IDENTICAL`

- [ ] **Step 3: Add the two cask entries.**

Insert `cask "1password"` and `cask "1password-cli"` at the TOP of the cask block (digits sort before letters, so they precede `font-meslo-lg-nerd-font`). The cask block becomes, in order: `1password`, `1password-cli`, `font-meslo-lg-nerd-font`, `ghostty`, `tailscale-app`.

- [ ] **Step 4: Add the 1Password `.zshrc` block.**

In `zsh/.zshrc`, immediately after the brew block (the line `zi auto has"dscl" for brew`) and before the `# bat:` block, insert (one blank line separating blocks):

```zsh
# 1password: remembers all your passwords for you
# https://1password.com
:1password-cli-eval() {
    chmod 0700 "${XDG_CONFIG_HOME}/op"
    op completion zsh
}

zi auto has"op" wait for 1password-cli
```

This is byte-identical to upstream — confirm with `grep -n -A6 '^# 1password: remembers' /Users/bene/src/hollow/dotfiles/zsh/.zshrc`. Do not modify any other part of `.zshrc`.

- [ ] **Step 5: Verify parse, placement, and faithfulness.**

Run:
```bash
diff /Users/bene/src/hollow/dotfiles/op/.gitignore op/.gitignore \
  && grep -q '^cask "1password"$' Brewfile \
  && grep -q '^cask "1password-cli"$' Brewfile \
  && grep '^cask ' Brewfile | sort -c \
  && grep -q '^zi auto has"op" wait for 1password-cli$' zsh/.zshrc \
  && zsh -n zsh/.zshrc && echo OK
```
Expected: `OK`. Eyeball placement: `grep -n -A8 'has"dscl" for brew' zsh/.zshrc` should show the brew line, a blank line, the `# 1password:` block, then a blank line and `# bat:`.

- [ ] **Step 6: Whole-ring deviation audit (expect NO output).**

Run:
```bash
comm -23 <(grep -E '^(brew|cask) ' Brewfile | sort -u) \
         <(grep -E '^(brew|cask) ' /Users/bene/src/hollow/dotfiles/Brewfile | sort -u)
```
Expected: **no output** (empty = no deviations).

- [ ] **Step 7: Commit.**

```bash
git add op/.gitignore Brewfile zsh/.zshrc
git commit -m "Ring 4: add 1Password app + op CLI"
```

---

## Post-implementation manual smoke test (optional, requires `brew bundle`)

After the tasks land and `brew bundle install` has run on a real machine:
- Ghostty opens and reads `~/.config/ghostty/config` (Catppuccin Mocha theme, MesloLGS Nerd Font); `$GHOSTTY_BIN_DIR` is on `PATH` inside Ghostty.
- `tailscale` CLI resolves on `PATH`; the Tailscale app is installed.
- The 1Password app and `op` CLI install; `op` tab-completion works in a fresh shell; `~/.config/op` is mode `0700`.
