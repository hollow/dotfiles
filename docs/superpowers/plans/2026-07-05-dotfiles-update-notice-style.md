# Dotfiles Update Notice Style Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers-extended-cc:subagent-driven-development (recommended) or superpowers-extended-cc:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the plain dotfiles update notice with a noticeable zsh-formatted line using a cyan Nerd Font icon and green `zup`.

**Architecture:** Keep the existing checker behavior and state machine unchanged. Modify only the `notice` output string and tests that assert the user-facing notice text.

**Tech Stack:** zsh autoload function, zsh `print -P` prompt escapes, existing shell test script.

**User decisions (already made):**
- User asked to make `print -r -- "dotfiles update available; run zup"` nicer with colors/Nerd Fonts.
- User chose text-only design comparison.
- User chose “Noticeable”: colored icon plus highlighted `zup`, visible without looking like an error.
- User approved `docs/superpowers/specs/2026-07-05-dotfiles-update-notice-design.md`.

---

## File structure

- Modify `zsh/dotfiles-update-check`: change only the `behind` notice output to use `print -P` and prompt color escapes.
- Modify `tests/dotfiles_update_check_test.zsh`: update notice expectations to cover the Nerd Font icon, core message text, and `zup` without making the test brittle around terminal color bytes.

---

### Task 1: Style dotfiles update notice

**Goal:** Render the `behind` notice as a noticeable zsh-formatted shell line while preserving all update-check behavior.

**Files:**
- Modify: `zsh/dotfiles-update-check:33-40`
- Modify: `tests/dotfiles_update_check_test.zsh`

**Acceptance Criteria:**
- [ ] `dotfiles-update-check notice` for cached `behind` includes the Nerd Font icon `󰚰`.
- [ ] The notice includes `dotfiles update available — run zup`.
- [ ] The implementation uses `print -P -- "%F{cyan}󰚰%f dotfiles update available — run %F{green}zup%f"`.
- [ ] Non-actionable states still produce no stdout or stderr.
- [ ] Existing update-check behavior tests still pass with `PASS: 19` and `FAIL: 0` or a higher pass count with zero failures.

**Verify:** `zsh -n zsh/.zshrc && zsh -n zsh/dotfiles-update-check && zsh tests/dotfiles_update_check_test.zsh` → expected final line `FAIL: 0`

**Steps:**

- [ ] **Step 1: Tighten the notice test first**

In `tests/dotfiles_update_check_test.zsh`, replace the exact plain-text notice assertion:

```zsh
assert_eq "behind checkout prints notice" "dotfiles update available; run zup" "$(capture_notice "${checkout}" "${state_dir}")"
```

with assertions that capture the output and check the required visible pieces:

```zsh
notice="$(capture_notice "${checkout}" "${state_dir}")"
if [[ "${notice}" == *"󰚰"* && "${notice}" == *"dotfiles update available — run"* && "${notice}" == *"zup"* ]]; then
	ok "behind checkout prints styled notice"
else
	bad "behind checkout prints styled notice: got <${notice}>"
fi
```

Add `local notice` only if this code is moved into a helper function. At top level in this test file, assigning `notice=...` is fine.

- [ ] **Step 2: Run the test to verify it fails before implementation**

Run:

```sh
zsh tests/dotfiles_update_check_test.zsh
```

Expected: non-zero exit with one failed assertion for `behind checkout prints styled notice`, because the current notice has no icon and still uses `;` instead of an em dash.

- [ ] **Step 3: Change the notice output**

In `zsh/dotfiles-update-check`, replace:

```zsh
[[ "${state}" == behind ]] && print -r -- "dotfiles update available; run zup"
```

with:

```zsh
[[ "${state}" == behind ]] && print -P -- "%F{cyan}󰚰%f dotfiles update available — run %F{green}zup%f"
```

Do not change `start`, `run`, `mark-up-to-date`, state files, fetch behavior, or `.zshrc`.

- [ ] **Step 4: Run verification**

Run:

```sh
zsh -n zsh/.zshrc && zsh -n zsh/dotfiles-update-check && zsh tests/dotfiles_update_check_test.zsh
```

Expected: zero exit and final line:

```text
FAIL: 0
```

- [ ] **Step 5: Commit the notice refinement**

Run:

```sh
git add zsh/dotfiles-update-check tests/dotfiles_update_check_test.zsh
git commit -m "Style dotfiles update notice"
```
