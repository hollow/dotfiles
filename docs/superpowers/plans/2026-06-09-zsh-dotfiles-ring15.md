# Ring 15 — atuin + direnv Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers-extended-cc:subagent-driven-development (recommended) or superpowers-extended-cc:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Port atuin and direnv from `hollow/dotfiles@981e133` into the fork, byte-identical, as one config commit plus a plan-complete commit.

**Architecture:** Two additive, self-contained tool blocks. atuin = `Brewfile` line + `.zshrc` `# region atuin` + `atuin/` config dir; direnv = `Brewfile` line + `.zshrc` `# region direnv` + trailing `.envrc` startup hook. `starship.toml` already carries direnv and is untouched. Each `.zshrc` block is inserted at upstream's relative position. This is a byte-identical port, not feature work — so there is no red-green TDD cycle; the "test" for each edit is byte-identity against `git show 981e133:<path>` plus `zsh -n`.

**Tech Stack:** zsh, zi (zinit) plugin manager, Homebrew Brewfile, TOML config.

**Spec:** `docs/superpowers/specs/2026-06-09-zsh-dotfiles-ring15-design.md`
**Branch:** `IT-8323-ring15-atuin-direnv` (already created; spec already committed as `e3b09c7`)
**Upstream pin:** `981e133` (reachable after `git fetch hollow`; it is `hollow/main` HEAD)

---

### Task 1: Port atuin + direnv config (single commit)

**Goal:** Apply all atuin and direnv config edits — `Brewfile`, `zsh/.zshrc`, and the new `atuin/` dir — each byte-identical to `981e133`, verify, and land them as one commit.

**Files:**
- Modify: `Brewfile` (add two lines)
- Modify: `zsh/.zshrc` (two new regions + trailing `.envrc` hook)
- Create: `atuin/config.toml`
- Create: `atuin/themes/catppuccin-mocha-blue.toml`

**Acceptance Criteria:**
- [x] `Brewfile` has `brew "atuin"` between `brew "atool"` and `brew "bash"`, and `brew "direnv"` between `brew "curl"` and `brew "docker"`.
- [x] `zsh/.zshrc` has `# region atuin` between the `1password` and `bat` regions, byte-identical to `981e133`.
- [x] `zsh/.zshrc` has `# region direnv` between the `dircolors` and `docker` regions, byte-identical to `981e133`.
- [x] `zsh/.zshrc` ends with the `.envrc` startup hook after `add path "${HOME}/.local/bin"`, byte-identical to `981e133`'s file tail.
- [x] `atuin/config.toml` and `atuin/themes/catppuccin-mocha-blue.toml` are byte-identical to `981e133`.
- [x] `zsh -n zsh/.zshrc` exits 0.
- [x] Fork's `Brewfile` `brew`/`cask` lines remain a strict subset of upstream (no new fork-only line from this ring).

**Verify:** `zsh -n zsh/.zshrc && echo SYNTAX-OK` plus the byte-identity diffs in Step 7 (each prints `OK`).

**Steps:**

- [x] **Step 0: Ensure the pin is reachable**

```bash
git cat-file -e 981e133^{commit} 2>/dev/null || git fetch hollow
```
Expected: no output (commit present). If it fetches, that's fine too.

- [x] **Step 1: Add the two `Brewfile` lines**

Insert `brew "atuin"` after `brew "atool"`:

Edit `Brewfile` — replace:
```
brew "atool"
brew "bash"
```
with:
```
brew "atool"
brew "atuin"
brew "bash"
```

Insert `brew "direnv"` after `brew "curl"` — replace:
```
brew "curl"
brew "docker"
```
with:
```
brew "curl"
brew "direnv"
brew "docker"
```

- [x] **Step 2: Insert the `# region atuin` block in `zsh/.zshrc`**

Edit `zsh/.zshrc` — replace:
```
zi auto has"op" wait1 for 1password-cli
# endregion

# region bat: cat(1) clone with wings
```
with (note: function bodies are TAB-indented, matching the rest of the file):
```
zi auto has"op" wait1 for 1password-cli
# endregion

# region atuin: magical shell history with optional sync
# https://github.com/atuinsh/atuin
:atuin-load() {
	alias a="atuin"
}

:atuin-eval() {
	atuin init zsh --disable-up-arrow
}

zi auto has"atuin" wait1 for atuin
# endregion

# region bat: cat(1) clone with wings
```

- [x] **Step 3: Insert the `# region direnv` block in `zsh/.zshrc`**

Edit `zsh/.zshrc` — replace:
```
zi auto id-as"dircolors" wait1 for trapd00r/LS_COLORS
# endregion

# region docker: container runtime CLI
```
with (TAB-indented function bodies):
```
zi auto id-as"dircolors" wait1 for trapd00r/LS_COLORS
# endregion

# region direnv: change environment based on the current directory
# https://github.com/direnv/direnv
:direnv-load() {
	alias da="direnv allow"
}

:direnv-eval() {
	direnv hook zsh
}

zi auto has"direnv" for direnv/direnv
# endregion

# region docker: container runtime CLI
```

- [x] **Step 4: Append the trailing `.envrc` startup hook**

Edit `zsh/.zshrc` — replace (this is the current last line of the file plus its comment):
```
# add local bin last so user binaries take precedence over tool/brew paths
add path "${HOME}/.local/bin"
```
with (the `pushd` line is TAB-indented):
```
# add local bin last so user binaries take precedence over tool/brew paths
add path "${HOME}/.local/bin"

# Load .envrc after shell initialization if present
if [[ -e .envrc ]]; then
	pushd "${HOME}" &>/dev/null && popd
fi
```

- [x] **Step 5: Create the atuin config dir from the pin (guarantees byte-identity)**

```bash
mkdir -p atuin/themes
git show 981e133:atuin/config.toml > atuin/config.toml
git show 981e133:atuin/themes/catppuccin-mocha-blue.toml > atuin/themes/catppuccin-mocha-blue.toml
```

- [x] **Step 6: Syntax check**

```bash
zsh -n zsh/.zshrc && echo SYNTAX-OK
```
Expected: `SYNTAX-OK`

- [x] **Step 7: Verify byte-identity against the pin**

```bash
# --- zsh/.zshrc regions ---
awkprog='$0 ~ "^# region "s": "{f=1} f{print} f && $0=="# endregion"{exit}'
diff <(git show 981e133:zsh/.zshrc | awk -v s=atuin "$awkprog") \
     <(awk -v s=atuin "$awkprog" zsh/.zshrc) && echo "atuin region OK"
diff <(git show 981e133:zsh/.zshrc | awk -v s=direnv "$awkprog") \
     <(awk -v s=direnv "$awkprog" zsh/.zshrc) && echo "direnv region OK"

# --- trailing .envrc hook (last 6 lines of the file tail) ---
diff <(git show 981e133:zsh/.zshrc | tail -6) <(tail -6 zsh/.zshrc) && echo "envrc tail OK"

# --- atuin config files ---
diff <(git show 981e133:atuin/config.toml) atuin/config.toml && echo "config.toml OK"
diff <(git show 981e133:atuin/themes/catppuccin-mocha-blue.toml) \
     atuin/themes/catppuccin-mocha-blue.toml && echo "theme OK"

# --- region order ---
grep -nE '^# region (1password|atuin|bat):' zsh/.zshrc
grep -nE '^# region (dircolors|direnv|docker):' zsh/.zshrc

# --- Brewfile placement + subset contract ---
grep -nE '^brew "(atool|atuin|bash|curl|direnv|docker)"$' Brewfile
echo "--- fork-only Brewfile lines (must contain NO atuin/direnv) ---"
comm -13 <(git show 981e133:Brewfile | sort) <(sort Brewfile)
```
Expected: every `diff` empty with its `OK` echo; `1password < atuin < bat` and `dircolors < direnv < docker` line ordering; the `grep` shows `atool, atuin, bash` and `curl, direnv, docker` adjacent; the `comm -13` output does **not** contain `brew "atuin"` or `brew "direnv"` (they are subset lines now present upstream too).

- [x] **Step 8: Commit (single config commit)**

```bash
git add Brewfile zsh/.zshrc atuin/
git commit -m "$(cat <<'EOF'
IT-8323: Ring 15 — add atuin + direnv

Port two previously-deferred tools from hollow/dotfiles@981e133,
byte-identical:
- atuin: brew, zshrc region, config dir (config.toml + catppuccin theme)
- direnv: brew, zshrc region, trailing .envrc startup hook

starship.toml already carries direnv (unchanged). No README change.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 2: Mark plan tasks complete

**Goal:** Tick the checkboxes in this plan and the spec status, and commit — the standard ring closing artifact.

**Files:**
- Modify: `docs/superpowers/plans/2026-06-09-zsh-dotfiles-ring15.md` (check all `- [x]` → `- [x]`)

**Acceptance Criteria:**
- [x] All step/criterion checkboxes in Task 1 are `- [x]`.
- [x] A commit records the completed plan.

**Verify:** `grep -c '\- \[ \]' docs/superpowers/plans/2026-06-09-zsh-dotfiles-ring15.md` → `0` (no unchecked boxes remain).

**Steps:**

- [x] **Step 1: Check every box in Task 1 and Task 2**

Replace each `- [x]` with `- [x]` throughout this plan file (Task 1 Steps 0–8, Task 1 acceptance criteria, and Task 2's own boxes).

- [x] **Step 2: Verify no unchecked boxes remain**

```bash
grep -c '\- \[ \]' docs/superpowers/plans/2026-06-09-zsh-dotfiles-ring15.md
```
Expected: `0`

- [x] **Step 3: Commit**

```bash
git add docs/superpowers/plans/2026-06-09-zsh-dotfiles-ring15.md
git commit -m "$(cat <<'EOF'
IT-8323: Ring 15 — mark plan tasks complete

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Self-Review

**Spec coverage:**
- Spec §A (Brewfile atuin+direnv) → Task 1 Step 1. ✓
- Spec §B (atuin region) → Task 1 Step 2. ✓
- Spec §C (direnv region) → Task 1 Step 3. ✓
- Spec §D (trailing `.envrc` hook) → Task 1 Step 4. ✓
- Spec §E (atuin/ config dir) → Task 1 Step 5. ✓
- Spec Deviation 1 (no README) → no task (intentional). ✓
- Spec Deviation 2 (starship.toml untouched) → no task (intentional — file not in any `git add`). ✓
- Spec Verification (byte-identity, syntax, region order, Brewfile subset) → Task 1 Steps 6–7. ✓
- Ring closing artifact (mark plan complete) → Task 2. ✓

**Placeholders:** none — every edit shows exact old/new text; config files are extracted from the pin.

**Type/order consistency:** insertion anchors match the verified current `.zshrc` (1password→bat at lines 336–338, dircolors→docker at 403–405, file tail at 825–826) and `Brewfile` (atool/bash at 5/6, curl/docker at 16/17).
