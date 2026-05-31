# Remerge zsh Dotfiles Skeleton — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers-extended-cc:subagent-driven-development (recommended) or superpowers-extended-cc:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a "golden" zsh dotfiles repo at `github.com/remerge/dotfiles` that a non-technical Mac user installs with one command, derived as a faithful stripped subset of `github.com/hollow/dotfiles`.

**Architecture:** The repo is cloned into `~/.config` (so `~/.config` *is* the repo). Only `~/.config/zsh/.zshrc` is symlinked to `~/.zshrc`; that file sets `XDG_*`/`ZDOTDIR` and autoloads helper functions. `install.sh` is thin (Xcode CLT → git → clone → symlink → re-exec zsh). The shell self-bootstraps on first launch: `zzinit` clones `zi`, the local `z-a-auto` annex maps `zi auto … for brew` to `:brew-update` (installs Homebrew + `brew bundle`), then zi installs the prompt and plugins.

**Tech Stack:** zsh, [zi](https://github.com/z-shell/zi) plugin manager, Homebrew, [starship](https://starship.rs), POSIX `sh` (installer). No application runtime; "tests" are syntax/lint checks (`zsh -n`, `shellcheck`, `brew bundle list`) plus a faithfulness `diff` against the reference repo and a documented manual smoke test.

**Reference repo:** `https://github.com/hollow/dotfiles` (branch `main`). Verbatim files are fetched from its raw URLs so they are byte-identical.

**Spec:** `docs/superpowers/specs/2026-05-28-zsh-dotfiles-skeleton-design.md`

**Repo starting state:** contains only `LICENSE` (Apache 2.0 — **must be preserved, never overwritten**), `README.md` (placeholder), and `docs/`.

---

## File Structure

Files produced (relative to repo root = future `~/.config`):

| Path | Origin | Responsibility |
|------|--------|----------------|
| `zsh/zzinit` | verbatim | zi loader/bootstrap |
| `zsh/z-a-auto/z-a-auto.plugin.zsh` | verbatim | `zi auto … for` annex + first-run hooks |
| `zsh/has` | verbatim | command/path existence test (used pervasively) |
| `zsh/add` | verbatim | unique array append helper (`add path …`) |
| `zsh/link` | verbatim | idempotent symlink helper (autoloads `uri-parse`) |
| `zsh/uri-parse` | verbatim | URI parser (dependency of `link`) |
| `zsh/.gitignore` | verbatim | ignores compiled `*.zwc` |
| `starship.toml` | verbatim | prompt config (catppuccin-mocha + nerd-font symbols) |
| `zsh/.zshrc` | authored (trim) | main config: XDG, zi, OMZL libs, plugins, brew bootstrap, starship |
| `Brewfile` | authored | starship + nerd font + core GNU tools + git/gh |
| `install.sh` | authored (new) | bootstrap: Xcode CLT + clone + symlink + re-exec zsh |
| `README.md` | authored (rewrite) | one-command install instructions for novices |
| `LICENSE` | **preserve** | existing Apache 2.0 — do NOT touch |

---

## Task 1: Vendor verbatim files from the reference repo

**Goal:** Bring over every unchanged file from `hollow/dotfiles` (zsh scaffolding, helper functions, and `starship.toml`) byte-identical, by fetching from pinned raw URLs.

**Files:**
- Create: `zsh/zzinit`
- Create: `zsh/z-a-auto/z-a-auto.plugin.zsh`
- Create: `zsh/has`
- Create: `zsh/add`
- Create: `zsh/link`
- Create: `zsh/uri-parse`
- Create: `zsh/.gitignore`
- Create: `starship.toml`

**Acceptance Criteria:**
- [ ] All 8 files exist and are non-empty.
- [ ] Each is byte-identical to the same path in `hollow/dotfiles@main`.
- [ ] The zsh files parse: `zsh -n` succeeds on `zzinit`, `z-a-auto.plugin.zsh`, `has`, `add`, `link`, `uri-parse`.
- [ ] `starship.toml` is valid TOML.

**Verify:** `for f in zsh/zzinit zsh/z-a-auto/z-a-auto.plugin.zsh zsh/has zsh/add zsh/link zsh/uri-parse; do zsh -n "$f" || echo "PARSE FAIL $f"; done; python3 -c "import tomllib,sys; tomllib.load(open('starship.toml','rb'))" && echo TOML-OK` → no PARSE FAIL lines, prints `TOML-OK`.

**Steps:**

- [ ] **Step 1: Fetch the verbatim files from pinned raw URLs**

```bash
set -e
base="https://raw.githubusercontent.com/hollow/dotfiles/main"
mkdir -p zsh/z-a-auto
curl -fsSL "$base/zsh/zzinit"                        -o zsh/zzinit
curl -fsSL "$base/zsh/z-a-auto/z-a-auto.plugin.zsh"  -o zsh/z-a-auto/z-a-auto.plugin.zsh
curl -fsSL "$base/zsh/has"                           -o zsh/has
curl -fsSL "$base/zsh/add"                           -o zsh/add
curl -fsSL "$base/zsh/link"                          -o zsh/link
curl -fsSL "$base/zsh/uri-parse"                     -o zsh/uri-parse
curl -fsSL "$base/zsh/.gitignore"                    -o zsh/.gitignore
curl -fsSL "$base/starship.toml"                     -o starship.toml
```

- [ ] **Step 2: Sanity-check content**

Confirm the small files match what the spec quotes (guards against a moved/renamed upstream file):

```bash
cat zsh/.gitignore                 # expect: **/*.zwc
cat zsh/has                        # expect: type "$1" &>/dev/null || test -e "/$1"
head -1 zsh/z-a-auto/z-a-auto.plugin.zsh   # expect a "Standardized $0 Handling" comment region
```

- [ ] **Step 3: Run the verification command**

Run: `for f in zsh/zzinit zsh/z-a-auto/z-a-auto.plugin.zsh zsh/has zsh/add zsh/link zsh/uri-parse; do zsh -n "$f" || echo "PARSE FAIL $f"; done; python3 -c "import tomllib; tomllib.load(open('starship.toml','rb'))" && echo TOML-OK`
Expected: no `PARSE FAIL` output; ends with `TOML-OK`.

- [ ] **Step 4: Commit**

```bash
git add zsh/zzinit zsh/z-a-auto/z-a-auto.plugin.zsh zsh/has zsh/add zsh/link zsh/uri-parse zsh/.gitignore starship.toml
git commit -m "Vendor verbatim zsh scaffolding and starship.toml from reference dotfiles"
```

---

## Task 2: Write the trimmed `zsh/.zshrc`

**Goal:** Produce the main config as a trimmed subset of the reference `.zshrc` — core scaffold + the four common plugins + the brew self-bootstrap — with no personal/tool-specific blocks.

**Files:**
- Create: `zsh/.zshrc`

**Acceptance Criteria:**
- [ ] `zsh -n zsh/.zshrc` parses with exit 0.
- [ ] Contains the brew bootstrap (`:brew-init`, `:brew-update`, `zi auto has"dscl" for brew`), the starship init block, and the four plugin loads (F-Sy-H, zsh-autosuggestions, zsh-autopair, zsh-completions).
- [ ] Does NOT contain the `USER_NAME`/`USER_EMAIL` block or any dropped tool block (no `terraform`, `gcloud`, `atuin`, `fzf`, `eza`, `git` aliases, etc.).
- [ ] `zup()` references only `:brew-update`, `zi self-update`, `zi update --all`.

**Verify:** `zsh -n zsh/.zshrc && echo SYNTAX-OK` → prints `SYNTAX-OK`; then `grep -c -E 'USER_EMAIL|terraform|fzf|atuin|gcloud' zsh/.zshrc` → prints `0`.

**Steps:**

- [ ] **Step 1: Write `zsh/.zshrc` with exactly this content**

```zsh
# force locale to english
export LANG="en_US.UTF-8"
export LC_CTYPE=${LANG}

# enforce truecolor support
export COLORTERM="truecolor"

# shell options
setopt extendedglob

# set resource limits
ulimit -n $((1024*1024))

# words are complete shell command arguments
autoload -Uz select-word-style
select-word-style shell

# system path
typeset -TUx PATH path=(/{usr/,}{local/,}{s,}bin)

# user paths
# https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
export XDG_CONFIG_HOME="${HOME}/.config"
export XDG_CACHE_HOME="${HOME}/.cache"
export XDG_DATA_HOME="${HOME}/.local/share"
export XDG_STATE_HOME="${HOME}/.local/state"
export XDG_RUNTIME_DIR="${HOME}/.local/run"

mkdir -p "${XDG_CONFIG_HOME}"
mkdir -p "${XDG_CACHE_HOME}"
mkdir -p "${XDG_DATA_HOME}"
mkdir -p "${XDG_STATE_HOME}"
mkdir -p "${XDG_RUNTIME_DIR}"
chmod 0700 "${XDG_RUNTIME_DIR}"

# shell paths
# https://zsh.sourceforge.io/Intro/intro_3.html
ZDOTDIR="${XDG_CONFIG_HOME}/zsh"
ZSH_DATA_DIR="${XDG_DATA_HOME}/zsh"
ZSH_CACHE_DIR="${XDG_CACHE_HOME}/zsh"

mkdir -p "${ZSH_CACHE_DIR}"{,/completions}
mkdir -p "${ZSH_DATA_DIR}"

# shell functions
typeset -TUx FPATH fpath=(
    ${ZDOTDIR}
    ${ZSH_CACHE_DIR}/completions
    ${fpath[@]}
)

# append ZDOTDIR so `git foo` and subprocess lookups can find user scripts,
# but `command foo` still resolves to system binaries first
path+=("${ZDOTDIR}")

# autoload all regular files in ZDOTDIR
autoload -Uz ${ZDOTDIR}/*(.N:t)

# add homebrew path as early as possible
if has /opt/homebrew/bin/brew; then
    eval "$(/opt/homebrew/bin/brew shellenv zsh)"
fi

# add local bin to path
add path "${HOME}/.local/bin"

# compiler flags
typeset -TUx LDFLAGS ldflags ":"
typeset -TUx CPPFLAGS cppflags ":"

# zi: Flexible and fast ZSH plugin manager
# https://github.com/z-shell/zi
typeset -Ag ZI
ZI[HOME_DIR]="${XDG_CACHE_HOME}/zi"
ZI[BIN_DIR]="${ZI[HOME_DIR]}/bin"
source "${ZDOTDIR}/zzinit" && zzinit

alias zre="exec zsh"
alias zx="sudo rm -rf ${XDG_CACHE_HOME} && zre"

zup() {
    local oldpwd="${PWD}"
    :brew-update && \
    zi self-update && \
    zi update --all
    cd "${oldpwd}"
}

# zinit/default: set global default ice
# https://github.com/z-shell/z-a-default-ice
zi id-as for z-shell/z-a-default-ice
zi default-ice -q lucid light-mode

# zinit/eval: creates a cache containing the output of a command
# https://github.com/z-shell/z-a-eval
zi id-as for z-shell/z-a-eval

# zi/auto: load plugins with conventions
zi id-as for "${ZDOTDIR}/z-a-auto"

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

alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."

# history configuration
# https://zsh.sourceforge.io/Doc/Release/Options.html#History
HISTSIZE=2000000000 SAVEHIST=1000000000
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
# https://github.com/Homebrew/brew
:brew-init() {
    export HOMEBREW_BUNDLE_FILE="${XDG_CONFIG_HOME}/Brewfile"
    export HOMEBREW_BUNDLE_NO_LOCK=1
    export HOMEBREW_AUTO_UPDATE_SECS=86400
    export HOMEBREW_CLEANUP_MAX_AGE_DAYS=7
    export HOMEBREW_CLEANUP_PERIODIC_FULL_DAYS=1

    add path "${HOMEBREW_PREFIX}/opt/coreutils/libexec/gnubin"
    add path "${HOMEBREW_PREFIX}/opt/findutils/libexec/gnubin"
    add path "${HOMEBREW_PREFIX}/opt/gawk/libexec/gnubin"
    add path "${HOMEBREW_PREFIX}/opt/gnu-sed/libexec/gnubin"
    add path "${HOMEBREW_PREFIX}/opt/gnu-tar/libexec/gnubin"
    add path "${HOMEBREW_PREFIX}/opt/gnu-time/libexec/gnubin"
    add path "${HOMEBREW_PREFIX}/opt/grep/libexec/gnubin"
    add path "${HOMEBREW_PREFIX}/opt/make/libexec/gnubin"
    add fpath "${HOMEBREW_PREFIX}/share/zsh/site-functions"

    alias bbd="brew bundle dump -f"
    alias bz="brew uninstall --zap"
}

:brew-update() {
    if ! has brew; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        eval "$(/opt/homebrew/bin/brew shellenv)"
        :brew-init
    else
        brew bundle dump -f
    fi

    brew update
    brew upgrade
    brew bundle install
    brew autoremove
    brew cleanup -s --prune=all
    chmod go-w "${HOMEBREW_PREFIX}/share"
}

zi auto has"dscl" for brew

# starship: minimal, blazing-fast, customizable prompt
# https://starship.rs
if has starship; then
    eval "$(starship init zsh)"
    # `starship init zsh` sets both PROMPT and RPROMPT, so the starship binary
    # is spawned twice per prompt redraw (~40ms each). The right prompt is
    # empty by default — drop RPROMPT to halve command_lag.
    unset RPROMPT
fi

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

- [ ] **Step 2: Verify syntax and absence of dropped blocks**

Run: `zsh -n zsh/.zshrc && echo SYNTAX-OK`
Expected: prints `SYNTAX-OK` (no parse errors).

Run: `grep -c -E 'USER_EMAIL|terraform|fzf|atuin|gcloud' zsh/.zshrc`
Expected: prints `0`.

- [ ] **Step 3: Commit**

```bash
git add zsh/.zshrc
git commit -m "Add trimmed .zshrc: core scaffold, brew bootstrap, starship, 4 plugins"
```

---

## Task 3: Write the `Brewfile`

**Goal:** Provide a minimal-but-coherent Brewfile: the prompt, a Nerd Font, and the GNU tools that `:brew-init` adds to `PATH`, plus `git`/`gh`.

**Files:**
- Create: `Brewfile`

**Acceptance Criteria:**
- [ ] Contains exactly: `starship`, `coreutils`, `findutils`, `gawk`, `gnu-sed`, `gnu-tar`, `gnu-time`, `grep`, `make`, `git`, `gh` (brews) and `font-meslo-lg-nerd-font` (cask).
- [ ] `brew bundle list --file=./Brewfile` lists all 12 entries without error.
- [ ] Every GNU tool whose gnubin path appears in `:brew-init` is present in the Brewfile.

**Verify:** `brew bundle list --file=./Brewfile | sort | tr '\n' ' '` → lists the 12 package names; exit 0.

**Steps:**

- [ ] **Step 1: Write `Brewfile` with exactly this content (alphabetical, matching reference style)**

```ruby
brew "coreutils"
brew "findutils"
brew "gawk"
brew "gh"
brew "git"
brew "gnu-sed"
brew "gnu-tar"
brew "gnu-time"
brew "grep"
brew "make"
brew "starship"
cask "font-meslo-lg-nerd-font"
```

- [ ] **Step 2: Verify it parses**

Run: `brew bundle list --file=./Brewfile`
Expected: prints the 11 brews + 1 cask names; exit 0. (Does not install anything; `list` only reads the file.)

- [ ] **Step 3: Commit**

```bash
git add Brewfile
git commit -m "Add Brewfile: starship, nerd font, core GNU tools, git, gh"
```

---

## Task 4: Write `install.sh`

**Goal:** Thin bootstrap installer in POSIX `sh`: ensure git (Xcode CLT on macOS), clone the repo into `~/.config` (handling a pre-existing dir), symlink `~/.zshrc`, then re-exec an interactive zsh to trigger the first-run self-bootstrap.

**Files:**
- Create: `install.sh`

**Acceptance Criteria:**
- [ ] `shellcheck -s sh install.sh` reports no errors or warnings.
- [ ] `sh -n install.sh` parses with exit 0.
- [ ] Clones `https://github.com/remerge/dotfiles` into `${XDG_CONFIG_HOME:-$HOME/.config}` and handles three cases: already a git repo (pull), non-empty non-repo dir (init in place), absent/empty (clone).
- [ ] Symlinks `~/.zshrc` → `~/.config/zsh/.zshrc`.
- [ ] Ends by re-execing zsh with the terminal reattached (`</dev/tty` fallback), so `curl … | sh` does not drop into a dead shell.
- [ ] On non-Darwin, skips Xcode CLT and prints a best-effort Linux note.
- [ ] File mode is executable (`chmod +x`).

**Verify:** `shellcheck -s sh install.sh && sh -n install.sh && echo LINT-OK` → prints `LINT-OK`; then `test -x install.sh && echo EXECUTABLE`.

**Steps:**

- [ ] **Step 1: Write `install.sh` with exactly this content**

```sh
#!/bin/sh
# Remerge dotfiles installer.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/remerge/dotfiles/main/install.sh | sh
#
# Installs Apple Command Line Tools (for git) on macOS, clones this repo into
# ~/.config, links ~/.zshrc, and starts a fresh zsh. The shell finishes the
# bootstrap on first launch (Homebrew, plugins, prompt).
set -eu

REPO_URL="https://github.com/remerge/dotfiles"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"

log() { printf '\033[1;34m==>\033[0m %s\n' "$1"; }
err() { printf '\033[1;31merror:\033[0m %s\n' "$1" >&2; }

os="$(uname -s)"

# 1. Ensure git is available (macOS ships it via the Command Line Tools).
if [ "$os" = "Darwin" ] && ! xcode-select -p >/dev/null 2>&1; then
    log "Installing Xcode Command Line Tools (a dialog will open)..."
    xcode-select --install || true
    log "Waiting for the Command Line Tools to finish installing..."
    while ! { xcode-select -p >/dev/null 2>&1 && command -v git >/dev/null 2>&1; }; do
        sleep 5
    done
fi

if ! command -v git >/dev/null 2>&1; then
    err "git is required but was not found. Install git, then re-run this script."
    exit 1
fi

# 2. Place the dotfiles in ~/.config.
if [ -e "$CONFIG_DIR/.git" ]; then
    log "Dotfiles already present in $CONFIG_DIR; pulling latest..."
    git -C "$CONFIG_DIR" pull --ff-only
elif [ -d "$CONFIG_DIR" ] && [ -n "$(find "$CONFIG_DIR" -mindepth 1 -maxdepth 1 2>/dev/null | head -n 1)" ]; then
    log "$CONFIG_DIR exists and is not empty; initializing dotfiles in place..."
    git -C "$CONFIG_DIR" init -q
    git -C "$CONFIG_DIR" remote add origin "$REPO_URL"
    git -C "$CONFIG_DIR" fetch -q origin main
    git -C "$CONFIG_DIR" checkout -f -B main origin/main
else
    log "Cloning dotfiles into $CONFIG_DIR..."
    git clone -q "$REPO_URL" "$CONFIG_DIR"
fi

# 3. Link the zsh entrypoint.
log "Linking ~/.zshrc -> $CONFIG_DIR/zsh/.zshrc"
ln -nfs "$CONFIG_DIR/zsh/.zshrc" "$HOME/.zshrc"

# 4. Hand off to a fresh interactive zsh to run the first-run bootstrap.
if [ "$os" != "Darwin" ]; then
    log "Linux detected (best-effort): Homebrew and starship will NOT auto-install."
    log "See the README for manual steps: $REPO_URL"
fi

log "Done. Starting zsh — the first launch installs Homebrew, plugins, and the prompt."
if [ -e /dev/tty ]; then
    exec zsh -i </dev/tty
else
    exec zsh -i
fi
```

- [ ] **Step 2: Make it executable**

```bash
chmod +x install.sh
```

- [ ] **Step 3: Lint and syntax-check**

Run: `shellcheck -s sh install.sh && sh -n install.sh && echo LINT-OK`
Expected: no shellcheck findings; prints `LINT-OK`.
(If `shellcheck` is not installed: `brew install shellcheck` first.)

- [ ] **Step 4: Commit**

```bash
git add install.sh
git commit -m "Add install.sh: xcode CLT + clone + symlink + re-exec zsh"
```

---

## Task 5: Rewrite `README.md` for non-technical users

**Goal:** Replace the placeholder README with clear, jargon-light install instructions and a short "what you get" / "updating" / "Linux" section.

**Files:**
- Modify: `README.md`

**Acceptance Criteria:**
- [ ] Contains the exact one-line install command using `curl … | sh`.
- [ ] Has a single top-level `#` heading.
- [ ] Explains the 3 things the installer does and warns the first launch is slow once.
- [ ] No markdownlint errors (fenced blocks surrounded by blank lines, language tags present).

**Verify:** `grep -q 'curl -fsSL https://raw.githubusercontent.com/remerge/dotfiles/main/install.sh | sh' README.md && [ "$(grep -c '^# ' README.md)" -eq 1 ] && echo README-OK` → prints `README-OK`.

**Steps:**

- [ ] **Step 1: Overwrite `README.md` with exactly this content**

````markdown
# Remerge dotfiles

A ready-to-use shell setup for your Mac. One command gives you a modern
terminal — a clean prompt, command autocompletion, syntax highlighting, and
autosuggestions — with nothing to configure.

## Install

Open the **Terminal** app, paste this line, and press Enter:

```sh
curl -fsSL https://raw.githubusercontent.com/remerge/dotfiles/main/install.sh | sh
```

That's it. The installer will:

1. Install Apple's developer tools (for `git`) and Homebrew if they're missing.
2. Set up your shell configuration.
3. Open a fresh shell. **The first launch takes about a minute** while it
   downloads the prompt and plugins — this happens only once.

## What you get

- [**zi**](https://github.com/z-shell/zi) — a fast zsh plugin manager (installs itself)
- [**starship**](https://starship.rs) — a clean, informative prompt
- **Syntax highlighting**, **autosuggestions**, **autopair**, and richer **tab completion**
- Sensible history and completion defaults

## Updating

To update everything later (Homebrew packages and plugins), run:

```sh
zup
```

## Linux

Linux is supported on a best-effort basis. The installer clones the config and
links `~/.zshrc`, but it does **not** auto-install Homebrew or starship (that
step is macOS-only). Install [Homebrew](https://brew.sh) and
[starship](https://starship.rs) yourself, then open a new shell.
````

- [ ] **Step 2: Verify**

Run: `grep -q 'curl -fsSL https://raw.githubusercontent.com/remerge/dotfiles/main/install.sh | sh' README.md && [ "$(grep -c '^# ' README.md)" -eq 1 ] && echo README-OK`
Expected: prints `README-OK`.

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "Rewrite README for one-command install"
```

---

## Task 6: Verify faithful subset and document the smoke test

> **USER-ORDERED GATE — NON-SKIPPABLE.** This task was requested by the user in the current conversation. It MUST NOT be closed by walking around it, by declaring it "verified inline", or by substituting a cheaper check. Close only after every item in `acceptanceCriteria` has been re-validated independently, with output captured.

**Goal:** Prove the repo is a faithful stripped subset of `hollow/dotfiles` (every vendored file byte-identical) and record a manual fresh-Mac smoke test that an installer can run end-to-end.

**Files:**
- Create: `docs/superpowers/plans/2026-05-28-zsh-dotfiles-skeleton-smoketest.md` (the manual checklist)

**Acceptance Criteria:**
- [ ] For every verbatim-vendored file (`zsh/zzinit`, `zsh/z-a-auto/z-a-auto.plugin.zsh`, `zsh/has`, `zsh/add`, `zsh/link`, `zsh/uri-parse`, `zsh/.gitignore`, `starship.toml`), `diff` against a fresh clone of `hollow/dotfiles@main` reports **no differences**.
- [ ] The existing `LICENSE` is unchanged from the repo's initial commit (Apache 2.0) — not overwritten by the reference repo's license.
- [ ] A manual smoke-test checklist file exists describing the fresh-Mac end-to-end run and its expected observable result (starship prompt rendered with nerd-font glyphs; syntax highlighting, autosuggestions, autopair, completion all active).

**Verify:** Run the diff script in Step 1 → prints `FAITHFUL-OK` with no `DIFFERS` lines; `git log --oneline -1 -- LICENSE` still shows only the initial commit.

**Steps:**

- [ ] **Step 1: Diff vendored files against a fresh reference clone**

```bash
tmp="$(mktemp -d)"
git clone -q https://github.com/hollow/dotfiles "$tmp"
status=0
for f in zsh/zzinit zsh/z-a-auto/z-a-auto.plugin.zsh zsh/has zsh/add zsh/link zsh/uri-parse zsh/.gitignore starship.toml; do
    if ! diff -q "$f" "$tmp/$f" >/dev/null; then
        echo "DIFFERS (unexpected): $f"
        status=1
    fi
done
rm -rf "$tmp"
[ "$status" -eq 0 ] && echo "FAITHFUL-OK"
```

Expected: no `DIFFERS` lines; prints `FAITHFUL-OK`.

- [ ] **Step 2: Confirm LICENSE untouched**

Run: `git log --oneline -- LICENSE`
Expected: a single line (the initial commit); the design pass did not modify it.

- [ ] **Step 3: Write the manual smoke-test checklist**

Create `docs/superpowers/plans/2026-05-28-zsh-dotfiles-skeleton-smoketest.md`:

```markdown
# Fresh-Mac smoke test (manual)

Run on a clean macOS account (or a VM) after the repo is pushed to `main`.

1. Open Terminal and run:
   `curl -fsSL https://raw.githubusercontent.com/remerge/dotfiles/main/install.sh | sh`
2. Approve the Xcode Command Line Tools dialog when it appears; wait for install.
3. Expect: the installer clones into `~/.config`, links `~/.zshrc`, and drops
   you into a new zsh. The first prompt takes ~1 minute (Homebrew + bundle +
   zi + plugins).
4. Verify, in the new shell:
   - [ ] The starship prompt renders with icons (no "tofu" boxes) — confirms the
         Nerd Font installed.
   - [ ] Typing a known command (e.g. `gi`) shows a greyed autosuggestion.
   - [ ] Valid commands turn green / invalid turn red as you type (F-Sy-H).
   - [ ] Typing `(` auto-inserts `)` (autopair).
   - [ ] `<Tab>` after `git ` offers completions.
   - [ ] `command -v starship` resolves; `echo $ZDOTDIR` is `~/.config/zsh`.
5. Run `zup` and confirm it updates brew + zi without errors.
```

- [ ] **Step 4: Commit**

```bash
git add docs/superpowers/plans/2026-05-28-zsh-dotfiles-skeleton-smoketest.md
git commit -m "Add faithfulness check results and manual smoke-test checklist"
```

---

## Notes & Known Considerations

- **`brew bundle dump -f` in `:brew-update` (kept verbatim per spec):** on `zup` (when brew already exists) this dumps the user's *currently installed* packages over the tracked `Brewfile`, producing local git changes in the user's clone. This is intended behavior in the personal reference repo and is harmless (the user can `git checkout -- Brewfile`). First-run bootstrap is unaffected (it takes the `! has brew` branch → `brew bundle install` from the committed file). A future Ring-2 task may replace the dump with a no-op for the shared skeleton.
- **Verbatim files are pinned to `hollow/dotfiles@main`.** If upstream changes, re-running Task 1's fetch picks up the new content; the Task 6 diff guards faithfulness.
- **Linux best-effort:** the `zi auto has"dscl" for brew` gate (dscl is macOS-only) means the brew bootstrap does not auto-fire on Linux; the README documents the manual path.

## Self-Review

- **Spec coverage:** deployment model → Task 4 + README (Task 5); first-run bootstrap → Task 2 (`:brew-*` + `zi auto … for brew`) relies on Task 1 (`z-a-auto`, `zzinit`, `has`/`add`); verbatim keep-list → Task 1; trimmed `.zshrc` keep/drop list → Task 2; Brewfile (option b) → Task 3; starship verbatim → Task 1; install.sh spec (incl. `</dev/tty` re-exec) → Task 4; README spec → Task 5; LICENSE preserved → Task 6 AC; faithfulness diff + acceptance criteria → Task 6. No gaps.
- **Placeholder scan:** none — every file's full content is inline; every Verify is a runnable command with expected output.
- **Type/name consistency:** function names (`:brew-init`, `:brew-update`, `zup`, `has`, `add`, `link`), env vars (`ZDOTDIR`, `XDG_*`, `HOMEBREW_BUNDLE_FILE`), paths (`~/.config`, `zsh/.zshrc`), and the install URL are identical across the spec, `.zshrc`, `install.sh`, and README.
