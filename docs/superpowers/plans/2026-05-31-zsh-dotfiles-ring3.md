# Ring 3 (bottom, tmux, vim + CLI utilities) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers-extended-cc:subagent-driven-development (recommended) or superpowers-extended-cc:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Port `bottom`, `tmux`, and `neovim` (with their configs), `ncdu` (with its ignore file), and six config-free CLI utilities from `hollow/dotfiles@9de9bf6` into the remerge dotfiles, as a faithful subset with no deviations.

**Architecture:** Vendor config files byte-identical from upstream; add the matching `brew` entries to `Brewfile` (kept alphabetical); insert the upstream `.zshrc` blocks as a strict line-subset at their upstream-relative positions. The repo lives at `~/.config`, so vendored directories map directly (`tmux/` → `~/.config/tmux/`, etc.).

**Tech Stack:** zsh, ZI plugin manager (z-a-auto conventions), Homebrew bundle, tmux + TPM, neovim + vim-plug.

**Spec:** `docs/superpowers/specs/2026-05-31-zsh-dotfiles-ring3-design.md`

**Upstream reference checkout:** `/Users/bene/src/hollow/dotfiles` (currently at the pinned commit `9de9bf6`). All "vendor verbatim" steps copy from there and verify with `diff`.

**Conventions for every task:** This is config vendoring, not application code — there is no unit-test suite. Each task's "test" is its **Verify** command (a `diff`, a `zsh -n` parse, or a `brew bundle list` parse). Make the change, run Verify, then commit.

---

### Task 1: Add config-free CLI utilities to the Brewfile

**Goal:** Add the six standalone brew utilities that need no config or `.zshrc` block.

**Files:**
- Modify: `Brewfile`

**Acceptance Criteria:**
- [ ] `Brewfile` contains `brew "atool"`, `brew "colordiff"`, `brew "jq"`, `brew "less"`, `brew "sponge"`, `brew "watch"`.
- [ ] The `brew "..."` lines remain in alphabetical order.
- [ ] Every added entry exists in the upstream `Brewfile`.
- [ ] `brew bundle list --file=./Brewfile --all` parses without error.

**Verify:** `brew bundle list --file=./Brewfile --all >/dev/null && echo OK` → prints `OK`

**Steps:**

- [ ] **Step 1: Insert the six entries alphabetically into the brew block.**

The current brew block is alphabetical (`bash, bat, coreutils, curl, duf, eza, fd, findutils, gawk, gh, git, glow, gnu-getopt, gnu-sed, gnu-tar, gnu-time, grep, make, ripgrep, rsync, starship, wget`). Insert so the result stays alphabetical:
- `brew "atool"` — before `brew "bash"` (new first brew line).
- `brew "colordiff"` — between `brew "bat"` and `brew "coreutils"`.
- `brew "jq"` — between `brew "grep"` and `brew "make"`.
- `brew "less"` — between `brew "jq"` and `brew "make"`.
- `brew "sponge"` — between `brew "rsync"` and `brew "starship"`.
- `brew "watch"` — between `brew "starship"` and `brew "wget"`.

(`bottom`, `ncdu`, `neovim`, `tmux` are added by later tasks — do not add them here.)

- [ ] **Step 2: Verify each entry matches upstream.**

Run:
```bash
for p in atool colordiff jq less sponge watch; do
  grep -q "^brew \"$p\"$" /Users/bene/src/hollow/dotfiles/Brewfile \
    && grep -q "^brew \"$p\"$" Brewfile \
    && echo "$p OK" || echo "$p MISSING";
done
```
Expected: all six print `OK`.

- [ ] **Step 3: Verify the Brewfile still parses.**

Run: `brew bundle list --file=./Brewfile --all >/dev/null && echo OK`
Expected: `OK`

- [ ] **Step 4: Commit.**

```bash
git add Brewfile
git commit -m "Ring 3: add atool, colordiff, jq, less, sponge, watch to Brewfile"
```

---

### Task 2: bottom (system monitor)

**Goal:** Install `bottom` and vendor its self-contained config.

**Files:**
- Create: `bottom/bottom.toml`
- Modify: `Brewfile`

**Acceptance Criteria:**
- [ ] `bottom/bottom.toml` is byte-identical to upstream.
- [ ] `Brewfile` contains `brew "bottom"`, alphabetically placed.
- [ ] No `.zshrc` change (bottom has no upstream block).
- [ ] `brew bundle list --file=./Brewfile --all` parses.

**Verify:** `diff /Users/bene/src/hollow/dotfiles/bottom/bottom.toml bottom/bottom.toml && echo IDENTICAL` → prints `IDENTICAL`

**Steps:**

- [ ] **Step 1: Vendor the config verbatim.**

Run:
```bash
mkdir -p bottom
cp /Users/bene/src/hollow/dotfiles/bottom/bottom.toml bottom/bottom.toml
```

- [ ] **Step 2: Verify byte-identical.**

Run: `diff /Users/bene/src/hollow/dotfiles/bottom/bottom.toml bottom/bottom.toml && echo IDENTICAL`
Expected: `IDENTICAL`

- [ ] **Step 3: Add the brew entry.**

Insert `brew "bottom"` between `brew "bat"` and `brew "colordiff"` (keeping the brew block alphabetical).

- [ ] **Step 4: Verify the entry and Brewfile parse.**

Run: `grep -q '^brew "bottom"$' Brewfile && brew bundle list --file=./Brewfile --all >/dev/null && echo OK`
Expected: `OK`

- [ ] **Step 5: Commit.**

```bash
git add bottom/bottom.toml Brewfile
git commit -m "Ring 3: add bottom (btm) + config"
```

---

### Task 3: ncdu (disk-usage analyzer)

**Goal:** Install `ncdu`, vendor its ignore file, and add the `.zshrc` block that links it.

**Files:**
- Create: `ncduignore`
- Modify: `Brewfile`
- Modify: `zsh/.zshrc`

**Acceptance Criteria:**
- [ ] `ncduignore` is byte-identical to upstream (single line `Library/CloudStorage/*`).
- [ ] `Brewfile` contains `brew "ncdu"`, alphabetically placed.
- [ ] `zsh/.zshrc` contains the ncdu block, inserted between the `colored-man-pages` block and the `rsync` block.
- [ ] `zsh -n zsh/.zshrc` passes.

**Verify:** `diff /Users/bene/src/hollow/dotfiles/ncduignore ncduignore && zsh -n zsh/.zshrc && echo OK` → prints `OK`

**Steps:**

- [ ] **Step 1: Vendor the ignore file verbatim.**

Run: `cp /Users/bene/src/hollow/dotfiles/ncduignore ncduignore`

- [ ] **Step 2: Verify byte-identical.**

Run: `diff /Users/bene/src/hollow/dotfiles/ncduignore ncduignore && echo IDENTICAL`
Expected: `IDENTICAL` (file content is exactly `Library/CloudStorage/*`)

- [ ] **Step 3: Add the brew entry.**

Insert `brew "ncdu"` between `brew "make"` and `brew "ripgrep"` (keeping the brew block alphabetical).

- [ ] **Step 4: Add the ncdu `.zshrc` block.**

In `zsh/.zshrc`, immediately after the colored-man-pages block (the line `zi auto wait for OMZP::colored-man-pages`) and before the `# rsync:` block, insert (with one blank line separating blocks, matching the file's style):

```zsh
# ncdu: disk usage analyzer
# https://dev.yorhel.nl/ncdu
link ncduignore .ncduignore
```

- [ ] **Step 5: Verify parse + faithfulness.**

Run:
```bash
diff /Users/bene/src/hollow/dotfiles/ncduignore ncduignore \
  && grep -q '^brew "ncdu"$' Brewfile \
  && grep -q '^link ncduignore .ncduignore$' zsh/.zshrc \
  && zsh -n zsh/.zshrc && echo OK
```
Expected: `OK`

- [ ] **Step 6: Commit.**

```bash
git add ncduignore Brewfile zsh/.zshrc
git commit -m "Ring 3: add ncdu + ncduignore link block"
```

---

### Task 4: tmux (terminal multiplexer)

**Goal:** Install `tmux`, vendor its config and the `clone` helper, and add the `.zshrc` block with TPM auto-bootstrap.

**Files:**
- Create: `tmux/tmux.conf`
- Create: `zsh/clone`
- Modify: `Brewfile`
- Modify: `zsh/.zshrc`

**Acceptance Criteria:**
- [ ] `tmux/tmux.conf` and `zsh/clone` are byte-identical to upstream.
- [ ] `zsh/clone` is **non-executable** (`-rw-r-----`), matching `zsh/add`/`zsh/has`/`zsh/link`/`zsh/uri-parse`.
- [ ] `Brewfile` contains `brew "tmux"` (but NOT `tmux-xpanes`), alphabetically placed.
- [ ] `zsh/.zshrc` contains the tmux block, inserted between the `rsync` block and the `wget` block.
- [ ] `zsh -n zsh/.zshrc` and `zsh -n zsh/clone` pass.

**Verify:** `diff /Users/bene/src/hollow/dotfiles/tmux/tmux.conf tmux/tmux.conf && diff /Users/bene/src/hollow/dotfiles/zsh/clone zsh/clone && zsh -n zsh/.zshrc && echo OK` → prints `OK`

**Steps:**

- [ ] **Step 1: Vendor the config and the helper verbatim.**

Run:
```bash
mkdir -p tmux
cp /Users/bene/src/hollow/dotfiles/tmux/tmux.conf tmux/tmux.conf
cp /Users/bene/src/hollow/dotfiles/zsh/clone zsh/clone
chmod 0640 zsh/clone
```

- [ ] **Step 2: Verify byte-identical + correct perms.**

Run:
```bash
diff /Users/bene/src/hollow/dotfiles/tmux/tmux.conf tmux/tmux.conf \
  && diff /Users/bene/src/hollow/dotfiles/zsh/clone zsh/clone \
  && [ ! -x zsh/clone ] && echo "OK non-exec"
```
Expected: `OK non-exec` (no diff output; `clone` is not executable). For reference, `zsh/clone` reads:
```zsh
#!zsh

autoload -Uz uri-parse

local repo_url="$1"
local repo_path="$2"

if [[ -z "${repo_url}" ]]; then
    print -P "usage: %N <url> [<path>]"
    return 1
fi

if [[ "${repo_url}" != *':'* ]]; then
    repo_url="https://github.com/${repo_url}"
fi

if [[ "${repo_path}" == "" ]]; then
    uri-parse rpath ${repo_url} || return
    repo_path="${HOME}/src/${REPLY}"
fi

if [[ ! -e "${repo_path}" ]]; then
    mkdir -p "$(dirname ${repo_path})"
    git clone "${repo_url}" "${repo_path}" || return
fi

if ! (( zsh_eval_context[(I)file] )); then
    cd "${repo_path}"
fi
```

- [ ] **Step 3: Confirm the `clone` dependency is present.**

`clone` autoloads `uri-parse`, which must already exist in this repo. Run: `test -f zsh/uri-parse && echo "dep OK"`
Expected: `dep OK`

- [ ] **Step 4: Add the brew entry.**

Insert `brew "tmux"` between `brew "starship"` and `brew "watch"` (keeping the brew block alphabetical). Do NOT add `tmux-xpanes` (deferred).

- [ ] **Step 5: Add the tmux `.zshrc` block.**

In `zsh/.zshrc`, immediately after the rsync block (the line `zi auto wait for OMZP::rsync`) and before the `# wget:` block, insert (one blank line separating blocks):

```zsh
# tmux: a terminal multiplexer
# https://github.com/tmux/tmux
:tmux-load() {
    export TMUX_PLUGIN_MANAGER_PATH="${XDG_CACHE_HOME}/tmux/plugins"
    export ZSH_TMUX_CONFIG="${XDG_CONFIG_HOME}/tmux/tmux.conf"
    export ZSH_TMUX_DEFAULT_SESSION_NAME="default"
    export ZSH_TMUX_FIXTERM="false"
    alias T=tmux
}

:tmux-update() {
    :tmux-load
    clone tmux-plugins/tpm "${TMUX_PLUGIN_MANAGER_PATH}/tpm"
    ${TMUX_PLUGIN_MANAGER_PATH}/tpm/bin/install_plugins
}

zi auto has"tmux" silent for OMZP::tmux
```

- [ ] **Step 6: Verify parse + faithfulness.**

Run:
```bash
diff /Users/bene/src/hollow/dotfiles/tmux/tmux.conf tmux/tmux.conf \
  && diff /Users/bene/src/hollow/dotfiles/zsh/clone zsh/clone \
  && grep -q '^brew "tmux"$' Brewfile \
  && ! grep -q 'tmux-xpanes' Brewfile \
  && zsh -n zsh/clone && zsh -n zsh/.zshrc && echo OK
```
Expected: `OK`

- [ ] **Step 7: Commit.**

```bash
git add tmux/tmux.conf zsh/clone Brewfile zsh/.zshrc
git commit -m "Ring 3: add tmux + tmux.conf + clone helper (TPM bootstrap)"
```

---

### Task 5: neovim (editor, invoked as vim)

**Goal:** Install `neovim`, vendor the vimrc and the vim-plug autoloader, and add the `.zshrc` block.

**Files:**
- Create: `vim/vimrc`
- Create: `vim/autoload/plug.vim`
- Modify: `Brewfile`
- Modify: `zsh/.zshrc`

**Acceptance Criteria:**
- [ ] `vim/vimrc` and `vim/autoload/plug.vim` are byte-identical to upstream.
- [ ] `Brewfile` contains `brew "neovim"`, alphabetically placed.
- [ ] `zsh/.zshrc` contains the vim block, inserted between the `tmux` block and the `wget` block.
- [ ] `zsh -n zsh/.zshrc` passes.

**Verify:** `diff /Users/bene/src/hollow/dotfiles/vim/vimrc vim/vimrc && diff /Users/bene/src/hollow/dotfiles/vim/autoload/plug.vim vim/autoload/plug.vim && zsh -n zsh/.zshrc && echo OK` → prints `OK`

**Steps:**

- [ ] **Step 1: Vendor the vimrc and plug.vim verbatim.**

Run:
```bash
mkdir -p vim/autoload
cp /Users/bene/src/hollow/dotfiles/vim/vimrc vim/vimrc
cp /Users/bene/src/hollow/dotfiles/vim/autoload/plug.vim vim/autoload/plug.vim
```

- [ ] **Step 2: Verify byte-identical.**

Run:
```bash
diff /Users/bene/src/hollow/dotfiles/vim/vimrc vim/vimrc \
  && diff /Users/bene/src/hollow/dotfiles/vim/autoload/plug.vim vim/autoload/plug.vim \
  && echo IDENTICAL
```
Expected: `IDENTICAL`

- [ ] **Step 3: Add the brew entry.**

Insert `brew "neovim"` between `brew "ncdu"` and `brew "ripgrep"` (keeping the brew block alphabetical).

- [ ] **Step 4: Add the vim `.zshrc` block.**

In `zsh/.zshrc`, immediately after the tmux block (the line `zi auto has"tmux" silent for OMZP::tmux`) and before the `# wget:` block, insert (one blank line separating blocks):

```zsh
# vi improved
# https://github.com/vim/vim
zi auto has"nvim" for neovim
alias vim=nvim
export VIMINIT="set nocp | source ${XDG_CONFIG_HOME}/vim/vimrc"
export EDITOR="${commands[nvim]}"
```

- [ ] **Step 5: Verify parse + faithfulness.**

Run:
```bash
diff /Users/bene/src/hollow/dotfiles/vim/vimrc vim/vimrc \
  && diff /Users/bene/src/hollow/dotfiles/vim/autoload/plug.vim vim/autoload/plug.vim \
  && grep -q '^brew "neovim"$' Brewfile \
  && grep -q '^alias vim=nvim$' zsh/.zshrc \
  && zsh -n zsh/.zshrc && echo OK
```
Expected: `OK`

- [ ] **Step 6: Final faithfulness audit (whole ring).**

Confirm every added brew entry exists upstream and the `.zshrc` is a strict subset. Run:
```bash
# every brew entry in our Brewfile exists in upstream's
comm -23 <(grep '^brew ' Brewfile | sort -u) \
         <(grep '^brew ' /Users/bene/src/hollow/dotfiles/Brewfile | sort -u)
```
Expected: **no output** (empty = no deviations).

- [ ] **Step 7: Commit.**

```bash
git add vim/vimrc vim/autoload/plug.vim Brewfile zsh/.zshrc
git commit -m "Ring 3: add neovim + vimrc + vim-plug"
```

---

## Post-implementation manual smoke test (optional, requires `brew bundle`)

After the tasks land and `brew bundle install` has run on a real machine:
- `btm` launches with the Catppuccin Mocha theme.
- `T` / `tmux` starts and loads the vendored `tmux.conf`; on first plugin update TPM is cloned to `~/.cache/tmux/plugins/tpm` and plugins install.
- `vim` launches `nvim`, sources `~/.config/vim/vimrc`; `:PlugInstall` installs `vim-code-dark`.
- `echo $EDITOR` points at the `nvim` binary.
- `~/.ncduignore` is a symlink to `~/.config/ncduignore`.
- `atool`, `colordiff`, `jq`, `less`, `sponge`, `watch` resolve on `PATH`.
