# Ring 12 (completion rework + fzf + fzf-tab) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers-extended-cc:subagent-driven-development (recommended) or superpowers-extended-cc:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Port the zsh completion rework + fzf + fzf-tab slice from `hollow/dotfiles@236cfef` ("Rework zsh completion setup (#3)") into the fork — inline `OMZL::completion.zsh`, move `compinit` to `zsh-completions`' `atload`, add fzf + fzf-tab, case-sensitive matching, and `bashcompinit`.

**Architecture:** One Brewfile line (`brew "fzf"`) plus one atomic `.zshrc` rework. The `.zshrc` change is interdependent — `compinit` moves out of F-Sy-H's `atinit` into `zsh-completions`' `atload`, fzf-tab slots in after `compinit` and before the widget wrappers, and the top completion-zstyle block is replaced by an inlined `# zsh/completion` block at the end — so it lands as a single commit (any partial state breaks completion). Every ported line is byte-identical to upstream `236cfef`; the only deviations are omitting upstream tools the fork has never carried (`zsh-bench`, `direnv`/`.envrc`, `atuin`, `copier`) and no README change.

**Tech Stack:** zsh + `zi` plugin manager (`z-a-auto` annex), Homebrew, fzf, fzf-tab (`Aloxaf/fzf-tab`), `zsh-users/zsh-completions`, `z-shell/F-Sy-H`, eza (fzf-tab cd preview).

**Reference spec:** `docs/superpowers/specs/2026-06-06-zsh-dotfiles-ring12-design.md`

**Upstream pin:** `hollow/dotfiles@main` = `236cfef` (already fetched as `hollow/main`; `git show 236cfef:<path>` works locally).

---

### Task 1: Add `brew "fzf"` to the Brewfile

**Goal:** Add the one new brew this ring needs (`fzf`, the engine behind fzf-tab and `FZF_DEFAULT_OPTS`) in alphabetically-sorted position — byte-identical to upstream's line.

**Files:**
- Modify: `Brewfile`

**Acceptance Criteria:**
- [ ] `brew "fzf"` sits between `brew "findutils"` and `brew "gawk"`.
- [ ] The added line is byte-identical to upstream's (`brew "fzf"`).
- [ ] No new fork-only Brewfile line is introduced: the only fork-only line vs upstream is still the pre-existing Ring-10 `vscode "davidanson.vscode-markdownlint"`.
- [ ] `brew bundle list --file=./Brewfile --all` parses without error.

**Verify:**
```bash
comm -13 <(git show 236cfef:Brewfile | sort) <(sort Brewfile)
```
→ prints only `vscode "davidanson.vscode-markdownlint"` (the pre-existing Ring-10 deviation) and nothing else — `brew "fzf"` does **not** appear, proving it is an upstream line.

**Steps:**

- [ ] **Step 1: Add the brew.**

Insert `brew "fzf"` immediately after the `brew "findutils"` line:
```ruby
brew "findutils"
brew "fzf"
brew "gawk"
```

- [ ] **Step 2: Verify the added line is an upstream line and no new deviation appeared.**

Run:
```bash
comm -13 <(git show 236cfef:Brewfile | sort) <(sort Brewfile)
```
Expected: exactly one line — `vscode "davidanson.vscode-markdownlint"`. `brew "fzf"` must NOT be listed (it is byte-identical to upstream's line).

- [ ] **Step 3: Verify the Brewfile parses.**

Run:
```bash
brew bundle list --file=./Brewfile --all >/dev/null && echo "OK: parses"
```
Expected: `OK: parses`.

- [ ] **Step 4: Commit.**

```bash
git add Brewfile
git commit -m "$(printf 'IT-8323: add fzf brew\n\nfzf is the engine behind fzf-tab and FZF_DEFAULT_OPTS (Ring 12).\nByte-identical to hollow/dotfiles@236cfef.\n\nCo-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>')"
```

---

### Task 2: Rework the `.zshrc` completion setup and add fzf + fzf-tab

**Goal:** Apply the five interdependent `.zshrc` edits from upstream `236cfef` as one atomic change: trim the OMZ block, remove the top completion-zstyle block, broaden the dircolors `list-colors`, add the `# fzf` block, and rework the end block (zsh-completions runs compinit via `atload` → fzf-tab → inlined `# zsh/completion` config + `bashcompinit` → F-Sy-H without `atinit` → autosuggestions → autopair).

**Files:**
- Modify: `zsh/.zshrc`

**Acceptance Criteria:**
- [ ] OMZ block no longer has `COMPLETION_WAITING_DOTS`, `OMZL::completion.zsh`, or `OMZL::grep.zsh`; it is byte-identical to upstream's OMZ block.
- [ ] The top completion-zstyle block (`# use approximate completion …` through `… git-checkout sort false`) is removed; the `history configuration` block is immediately followed by the `# brew:` block.
- [ ] `:dircolors-load()` body is upstream's broadened `:completion:*` `list-colors` version (4-line comment + `zstyle ':completion:*' list-colors …`).
- [ ] The `# fzf` block (FZF_DEFAULT_OPTS + `zi auto has"fzf" wait for fzf`) sits between the eza block and the gcloud block, byte-identical to upstream.
- [ ] The end block from `# zsh-completions:` through `# zsh/autopair` is byte-identical to upstream (zsh-completions with `atload"zicompinit; zicdreplay"` → fzf-tab + cd preview → `# zsh/completion` config + `bashcompinit` → F-Sy-H with plain `zi auto wait` → autosuggestions → autopair). It stops at autopair — no `zsh-bench`/`.envrc`.
- [ ] No remnants: `COMPLETION_WAITING_DOTS`, `OMZL::completion.zsh`, `OMZL::grep.zsh`, the old `:completion:*:default` list-colors line, and F-Sy-H's `atinit"zicompinit; zicdreplay"` are all absent; `compinit`/`zicompinit` is invoked exactly once.
- [ ] `zsh -n zsh/.zshrc` passes.

**Verify:**
```bash
# every ported region byte-identical to upstream 236cfef
diff <(git show 236cfef:zsh/.zshrc | sed -n '/^# ohmyzsh:/,/OMZL::termsupport.zsh/p') <(sed -n '/^# ohmyzsh:/,/OMZL::termsupport.zsh/p' zsh/.zshrc) \
&& diff <(git show 236cfef:zsh/.zshrc | sed -n '/^:dircolors-load() {/,/^}/p') <(sed -n '/^:dircolors-load() {/,/^}/p' zsh/.zshrc) \
&& diff <(git show 236cfef:zsh/.zshrc | sed -n '/^# fzf$/,/^zi auto has"fzf" wait for fzf$/p') <(sed -n '/^# fzf$/,/^zi auto has"fzf" wait for fzf$/p' zsh/.zshrc) \
&& diff <(git show 236cfef:zsh/.zshrc | sed -n '/^# zsh-completions:/,/^zi auto wait for hlissner\/zsh-autopair$/p') <(sed -n '/^# zsh-completions:/,/^zi auto wait for hlissner\/zsh-autopair$/p' zsh/.zshrc) \
&& zsh -n zsh/.zshrc \
&& echo OK
```
→ prints `OK` (all four ported regions match upstream byte-for-byte and the file parses).

**Steps:**

- [ ] **Step 1: Trim the OMZ block (§B).** Replace:

```zsh
# ohmyzsh: community driven zsh framework
# https://github.com/ohmyzsh/ohmyzsh
COMPLETION_WAITING_DOTS="true"
zi for \
    OMZL::completion.zsh \
    OMZL::directories.zsh \
    OMZL::functions.zsh \
    OMZL::grep.zsh \
    OMZL::history.zsh \
    OMZL::key-bindings.zsh \
    OMZL::spectrum.zsh \
    OMZL::termsupport.zsh
```

with:

```zsh
# ohmyzsh: community driven zsh framework
# https://github.com/ohmyzsh/ohmyzsh
zi for \
    OMZL::directories.zsh \
    OMZL::functions.zsh \
    OMZL::history.zsh \
    OMZL::key-bindings.zsh \
    OMZL::spectrum.zsh \
    OMZL::termsupport.zsh
```

- [ ] **Step 2: Remove the top completion-zstyle block (§C).** Replace:

```zsh
HISTFILE="${ZSH_DATA_DIR}/history"
link "${HISTFILE}" .zsh_history

# use approximate completion with error correction
# https://zsh.sourceforge.io/Doc/Release/Completion-System.html#Control-Functions
zstyle ':completion:*' completer _complete _correct _approximate
zstyle ':completion:*:match:*' original only
zstyle -e ':completion:*:approximate:*' max-errors 'reply=($((($#PREFIX+$#SUFFIX)/3>7?7:($#PREFIX+$#SUFFIX)/3))numeric)'

# set descriptions format to enable group support
zstyle ':completion:*:descriptions' format '%d'
zstyle ':completion:*:messages' format '%d'
zstyle ':completion:*:warnings' format 'No matches for: %d'
zstyle ':completion:*:corrections' format '%d (errors: %e)'

# improve make autocompletion
# https://unix.stackexchange.com/questions/657256/autocompletion-of-makefile-with-makro-in-zsh-not-correct-works-in-bash
zstyle ':completion::complete:make:*:targets' call-command true

# ignore completion functions for commands we don’t have
zstyle ':completion:*:functions' ignored-patterns '_*'

# ignore completion for git ORIG_HEAD
# https://stackoverflow.com/questions/12508595/ignore-orig-head-in-zsh-git-autocomplete#comment99936479_14325591
zstyle ':completion:*:*:git*:*' ignored-patterns '*ORIG_HEAD'

# disable sort when completing `git checkout`
zstyle ':completion:*:git-checkout:*' sort false

# brew: the missing package manager
```

with:

```zsh
HISTFILE="${ZSH_DATA_DIR}/history"
link "${HISTFILE}" .zsh_history

# brew: the missing package manager
```

(The deleted styles return, expanded and re-commented, in the end block at Step 5. Note `zstyle ':completion:*:match:*' original only` is dropped entirely — upstream does not re-add it.)

- [ ] **Step 3: Broaden the dircolors load body (§D).** Replace:

```zsh
:dircolors-load() {
    zstyle ":completion:*:default" list-colors "${(s.:.)LS_COLORS}"
}
```

with:

```zsh
:dircolors-load() {
    # colorize completion candidates (filenames, dirs, …) in every context, not
    # just the `default` tag — fzf-tab reads list-colors to color its menu. Set
    # here rather than in the completion block because LS_COLORS is populated by
    # :dircolors-eval, which runs when this plugin loads.
    zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
}
```

- [ ] **Step 4: Add the `# fzf` block (§E).** Replace:

```zsh
zi auto has"eza" wait for eza

# gcloud: Google Cloud SDK
```

with:

```zsh
zi auto has"eza" wait for eza

# fzf
# https://github.com/catppuccin/fzf/blob/main/themes/catppuccin-fzf-mocha.sh
export FZF_DEFAULT_OPTS=" \
    --color=bg+:#313244,bg:#1E1E2E,spinner:#F5E0DC,hl:#F38BA8 \
    --color=fg:#CDD6F4,header:#F38BA8,info:#CBA6F7,pointer:#F5E0DC \
    --color=marker:#B4BEFE,fg+:#CDD6F4,prompt:#CBA6F7,hl+:#F38BA8 \
    --color=selected-bg:#45475A \
    --color=border:#6C7086,label:#CDD6F4"

zi auto has"fzf" wait for fzf

# gcloud: Google Cloud SDK
```

- [ ] **Step 5: Rework the end block (§F).** Replace the current tail (the final block of the file):

```zsh
# zsh/f-sy-h: feature-rich syntax highlighting for ZSH
# https://github.com/z-shell/F-Sy-H
zi auto atinit"zicompinit; zicdreplay" \
    wait for z-shell/F-Sy-H

# zsh/autosuggestions: fish-like autosuggestions for zsh
# https://github.com/zsh-users/zsh-autosuggestions
zi auto atload"_zsh_autosuggest_start" \
    wait for zsh-users/zsh-autosuggestions

# zsh/autopair: automatically close quotes, brackets and other delimiters
# https://github.com/hlissner/zsh-autopair
zi auto wait for hlissner/zsh-autopair

# zsh/completions: initialize completion system
# https://github.com/zsh-users/zsh-completions
zi auto blockf atpull'zinit creinstall -q zsh-users/zsh-completions' \
    wait for zsh-users/zsh-completions
```

with:

```zsh
# zsh-completions: extra completion functions. Loads before compinit so they
# land in fpath, then its atload runs compinit once — replaying the compdefs
# queued by every completion plugin above — before fzf-tab and the widget
# wrappers below.
# https://github.com/zsh-users/zsh-completions
zi auto blockf atpull'zinit creinstall -q zsh-users/zsh-completions' \
    atload"zicompinit; zicdreplay" wait for zsh-users/zsh-completions

# fzf-tab: replace the completion menu with fzf. Must load after compinit (above)
# and before the widget-wrapping plugins (autosuggestions, F-Sy-H) below.
# https://github.com/Aloxaf/fzf-tab
zi auto has"fzf" wait for Aloxaf/fzf-tab

# preview directory content with eza when completing cd. =always forces color and
# icons even though the preview is piped (eza auto-disables both off a TTY); icons
# need a Nerd Font, which the terminal already uses.
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --all --long --group --color=always --icons=always $realpath'

# zsh/completion
zmodload -i zsh/complist            # list-colors support + native menu
unsetopt flowcontrol                # reclaim ^S/^Q from terminal flow control
setopt complete_in_word             # allow completing with the cursor mid-word
setopt always_to_end                # ...and jump the cursor to the word end afterwards

# fzf-tab's recommended `menu no`, and intentionally NO menu_complete: zsh inserts
# the longest common prefix on the first TAB (the auto-insert we want) and fzf-tab's
# menu opens once there's nothing more to insert. With case-sensitive matching
# (below) a prefix like `CL` resolves to one match and just completes, so the old
# `CL`→`CLaude` two-tab annoyance is gone. (`setopt menu_complete` would force the
# menu onto the first TAB everywhere but never auto-insert a common prefix.)
zstyle ':completion:*' menu no

# case-sensitive matching, keeping partial-word (r:) and substring (l:/r:) matchers.
# Dropping the leading `m:{...}={...}` case-fold makes e.g. `CL` match only
# CLAUDE.md (not claude_desktop_config.json), so it completes directly — the
# ambiguity behind the old `CL`→`CLaude` two-tab problem can't arise.
zstyle ':completion:*' matcher-list 'r:|=*' 'l:|=* r:|=*'

# completer chain: exact, then spelling correction, then fuzzy/approximate with an
# error budget that scales with word length. fzf filters the candidate list itself,
# but _correct/_approximate also repair typos in the typed prefix, which fzf can't.
# https://zsh.sourceforge.io/Doc/Release/Completion-System.html#Control-Functions
zstyle ':completion:*' completer _complete _correct _approximate
zstyle -e ':completion:*:approximate:*' max-errors 'reply=($((($#PREFIX+$#SUFFIX)/3>7?7:($#PREFIX+$#SUFFIX)/3))numeric)'

# candidates
zstyle ':completion:*' special-dirs true        # offer the `.` and `..` directories
zstyle ':completion:*' use-cache yes            # cache results for completers that support it
zstyle ':completion:*' cache-path "${ZSH_CACHE_DIR}"

# `cd`: real subdirs, then the dir stack, then $cdpath — and never guess named dirs
zstyle ':completion:*:cd:*' tag-order local-directories directory-stack path-directories

# process lists (kill, etc.) via macOS ps, with the PID/owner colorized
zstyle ':completion:*:*:*:*:processes' command 'ps -u $USERNAME -o pid,user,comm -w -w'
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'

# hide macOS service accounts (_spotlight, _mdnsresponder, …) from `users`
# completion, but still show one if it is the only match
zstyle ':completion:*:*:*:*:users' ignored-patterns '_*'
zstyle '*' single-ignored show

# don't complete zsh's own completion/widget functions as function names
zstyle ':completion:*:functions' ignored-patterns '_*'

# git: never offer ORIG_HEAD as a ref, and keep checkout's native branch order
# https://stackoverflow.com/questions/12508595/ignore-orig-head-in-zsh-git-autocomplete#comment99936479_14325591
zstyle ':completion:*:*:git*:*' ignored-patterns '*ORIG_HEAD'
zstyle ':completion:*:git-checkout:*' sort false

# make: invoke the makefile so macro-defined targets are completed too
# https://unix.stackexchange.com/questions/657256/autocompletion-of-makefile-with-makro-in-zsh-not-correct-works-in-bash
zstyle ':completion::complete:make:*:targets' call-command true

# group matches by type; fzf-tab reads this format for its group headers (no color
# escapes here — fzf-tab strips them). The rest style zsh's status lines.
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*:messages' format '%d'
zstyle ':completion:*:warnings' format 'No matches for: %d'
zstyle ':completion:*:corrections' format '%d (errors: %e)'

# bash-style `complete -C` programmable completion (consul, nomad, tofu use it)
autoload -U +X bashcompinit && bashcompinit

# zsh/f-sy-h: feature-rich syntax highlighting for ZSH (loads last, after fzf-tab)
# https://github.com/z-shell/F-Sy-H
zi auto wait for z-shell/F-Sy-H

# zsh/autosuggestions: fish-like autosuggestions for zsh
# https://github.com/zsh-users/zsh-autosuggestions
zi auto atload"_zsh_autosuggest_start" \
    wait for zsh-users/zsh-autosuggestions

# zsh/autopair: automatically close quotes, brackets and other delimiters
# https://github.com/hlissner/zsh-autopair
zi auto wait for hlissner/zsh-autopair
```

- [ ] **Step 6: Verify byte-identity of every ported region and syntax.**

Run:
```bash
diff <(git show 236cfef:zsh/.zshrc | sed -n '/^# ohmyzsh:/,/OMZL::termsupport.zsh/p') <(sed -n '/^# ohmyzsh:/,/OMZL::termsupport.zsh/p' zsh/.zshrc) \
&& diff <(git show 236cfef:zsh/.zshrc | sed -n '/^:dircolors-load() {/,/^}/p') <(sed -n '/^:dircolors-load() {/,/^}/p' zsh/.zshrc) \
&& diff <(git show 236cfef:zsh/.zshrc | sed -n '/^# fzf$/,/^zi auto has"fzf" wait for fzf$/p') <(sed -n '/^# fzf$/,/^zi auto has"fzf" wait for fzf$/p' zsh/.zshrc) \
&& diff <(git show 236cfef:zsh/.zshrc | sed -n '/^# zsh-completions:/,/^zi auto wait for hlissner\/zsh-autopair$/p') <(sed -n '/^# zsh-completions:/,/^zi auto wait for hlissner\/zsh-autopair$/p' zsh/.zshrc) \
&& zsh -n zsh/.zshrc \
&& echo OK
```
Expected: `OK` (no diff output from any region; `zsh -n` clean).

- [ ] **Step 7: Verify no remnants and a single compinit.**

Run:
```bash
grep -nE 'COMPLETION_WAITING_DOTS|OMZL::completion\.zsh|OMZL::grep\.zsh|:completion:\*:default|atinit"zicompinit' zsh/.zshrc && echo "FAIL: remnant present" || echo "OK: no remnants"
grep -c 'zicompinit' zsh/.zshrc
```
Expected: `OK: no remnants`, then `1` (zicompinit appears exactly once — in the `zsh-completions` `atload`).

- [ ] **Step 8: Commit.**

```bash
git add zsh/.zshrc
git commit -m "$(printf 'IT-8323: rework zsh completion + add fzf and fzf-tab\n\nInline OMZL::completion.zsh into an owned end-of-file block, run\ncompinit from zsh-completions atload (not F-Sy-H atinit), add fzf +\nfzf-tab, case-sensitive matching, and bashcompinit. Byte-identical to\nhollow/dotfiles@236cfef; omits upstream zsh-bench/.envrc/atuin/copier.\n\nCo-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>')"
```

---

### Task 3: Install fzf and run the end-to-end byte-identity + smoke check

**Goal:** Install `fzf` and confirm the reworked slice is correct — every ported line byte-identical to upstream `236cfef`, the file parses, the `fzf` binary is on PATH, and (best-effort) fzf-tab behaves in an interactive shell.

**Files:** _(none — verification only)_

**Acceptance Criteria:**
- [ ] `brew bundle install --file=./Brewfile` installs `fzf` without error.
- [ ] Full-slice byte-identity holds: the four region diffs in Task 2's Verify all print no output and `zsh -n zsh/.zshrc` passes.
- [ ] No fork-only line vs upstream originates from the completion/fzf/fzf-tab slice (the only fork-only `.zshrc` lines belong to other, pre-existing fork tools).
- [ ] `command -v fzf` resolves after install.
- [ ] Best-effort interactive check recorded (see note on the live-config caveat).

**Verify:**
```bash
diff <(git show 236cfef:zsh/.zshrc | sed -n '/^# zsh-completions:/,/^zi auto wait for hlissner\/zsh-autopair$/p') <(sed -n '/^# zsh-completions:/,/^zi auto wait for hlissner\/zsh-autopair$/p' zsh/.zshrc) && zsh -n zsh/.zshrc && command -v fzf >/dev/null && echo OK
```
→ prints `OK` (end block matches upstream, file parses, fzf installed).

**Steps:**

- [ ] **Step 1: Install fzf.**

Run:
```bash
brew bundle install --file=./Brewfile
```
Expected: completes without error; `fzf` is installed. (The `Aloxaf/fzf-tab` and `zsh-users/zsh-completions` plugins are fetched by `zi` on next shell start, not by brew.)

- [ ] **Step 2: Full-slice byte-identity + syntax.**

Run the four-region diff + `zsh -n` from Task 2 Step 6:
```bash
diff <(git show 236cfef:zsh/.zshrc | sed -n '/^# ohmyzsh:/,/OMZL::termsupport.zsh/p') <(sed -n '/^# ohmyzsh:/,/OMZL::termsupport.zsh/p' zsh/.zshrc) \
&& diff <(git show 236cfef:zsh/.zshrc | sed -n '/^:dircolors-load() {/,/^}/p') <(sed -n '/^:dircolors-load() {/,/^}/p' zsh/.zshrc) \
&& diff <(git show 236cfef:zsh/.zshrc | sed -n '/^# fzf$/,/^zi auto has"fzf" wait for fzf$/p') <(sed -n '/^# fzf$/,/^zi auto has"fzf" wait for fzf$/p' zsh/.zshrc) \
&& diff <(git show 236cfef:zsh/.zshrc | sed -n '/^# zsh-completions:/,/^zi auto wait for hlissner\/zsh-autopair$/p') <(sed -n '/^# zsh-completions:/,/^zi auto wait for hlissner\/zsh-autopair$/p' zsh/.zshrc) \
&& zsh -n zsh/.zshrc && echo OK
```
Expected: `OK`.

- [ ] **Step 3: Confirm fzf on PATH and a best-effort interactive smoke test.**

Run:
```bash
command -v fzf && fzf --version
```
Expected: an fzf path and a version string.

Note (live-config caveat): the live `~/.config` on this machine tracks `hollow@main`, which is `236cfef` — the same commit being ported — so `zsh -ic` exercises an equivalent reworked completion setup, not the fork branch's working copy. Interactive behavior to spot-check in a fresh terminal: TAB-completing a `cd` argument opens the fzf-tab menu with a colorized eza directory preview; `tofu <TAB>` completes (bashcompinit active). Record the observed result; byte-identity to the already-shipped upstream commit (Step 2) is the primary guarantee.

- [ ] **Step 4: No commit.**

This task changes no tracked files. The repo sets `HOMEBREW_BUNDLE_NO_LOCK=1`, so `brew bundle install` writes no lock file; if any untracked lock file appears, discard it.

---

## Self-Review

**Spec coverage:** Spec §A (Brewfile `fzf`)→Task 1; §B (OMZ block)→Task 2 Step 1; §C (remove top zstyle block)→Task 2 Step 2; §D (dircolors)→Task 2 Step 3; §E (fzf block)→Task 2 Step 4; §F (end-block rework)→Task 2 Step 5; Verification/smoke section→Task 2 Steps 6–7 + Task 3. Deviations: omit `zsh-bench`/`.envrc`/`atuin`/`copier` (the end-block replacement stops at autopair — Task 2 Step 5 + AC "stops at autopair"); no README change (no task — intentional). All covered.

**Placeholder scan:** No TBD/TODO; every edit step shows the exact old and new text, and every verify step shows the command and expected output.

**Type/name consistency:** `236cfef`, `zicompinit; zicdreplay`, `atload`/`atinit`, `zi auto has"fzf" wait for fzf` vs `… wait for Aloxaf/fzf-tab`, `bashcompinit`, `${ZSH_CACHE_DIR}`, and the sorted Brewfile position (`findutils` → `fzf` → `gawk`) are used consistently across tasks and match the spec. The four sed ranges in the verify commands match the exact comment/anchor lines inserted in Task 2.
