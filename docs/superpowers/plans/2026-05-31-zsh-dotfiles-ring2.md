# Remerge zsh Dotfiles — Ring 2 (Everyday CLI Niceties) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers-extended-cc:subagent-driven-development (recommended) or superpowers-extended-cc:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extend the merged zsh dotfiles skeleton with everyday CLI niceties (eza/bat/fd/ripgrep/duf/rsync/wget/glow, pager/man/dircolors/you-should-use) plus the full git alias set, its `git-*` subcommands, impersonal git defaults, and per-user git identity via a git `[include]`.

**Architecture:** Same faithful-subset model as Ring 1. New config files and `git-*` scripts are vendored byte-identical from `hollow/dotfiles@main`; `zsh/.zshrc` gains upstream blocks inserted at their original relative positions (strict line-subset); `Brewfile` gains tool entries; `git/config` is an impersonal subset of upstream + a `[include]` directive; per-user identity lives in untracked `git/local`, seeded by `install.sh`.

**Tech Stack:** zsh, [zi](https://github.com/z-shell/zi), Homebrew, git config `[include]`, POSIX sh (installer). "Tests" are syntax/lint/faithfulness checks (`zsh -n`, `shellcheck`, `brew bundle list`, byte-identity `diff`, line-subset checks) plus an extended manual smoke test.

**Reference repo:** `https://github.com/hollow/dotfiles` (branch `main`). `base="https://raw.githubusercontent.com/hollow/dotfiles/main"` in commands below.

**Spec:** `docs/superpowers/specs/2026-05-31-zsh-dotfiles-ring2-design.md`

**Branch:** `ring2-everyday-niceties` (already checked out; Ring 0/1 merged to `main`).

**Shell note:** the working shell is zsh, where `status` is a read-only variable — use a different name (e.g. `st`) in verification loops.

---

## File Structure

| Path | Origin | Responsibility |
|------|--------|----------------|
| `bat/config` | verbatim | bat theme/style |
| `git/ignore` | verbatim | global gitignore (`**/.claude/settings.local.json`) |
| `wgetrc` | verbatim | wget defaults |
| `glow/glow.yml` | verbatim | glow config |
| `glow/styles/catppuccin-mocha.json` | verbatim | glow theme |
| `zsh/git-main-branch` | verbatim (exec) | print main/master branch name |
| `zsh/git-latest` | verbatim (exec) | latest tag or main branch |
| `zsh/git-cleanup` | verbatim (exec) | fetch/gc/submodule cleanup |
| `zsh/git-checkout-latest` | verbatim (exec) | checkout latest/main + cleanup |
| `git/config` | derived (impersonal subset + include) | shared git defaults + aliases |
| `git/local.example` | net-new | per-user identity template |
| `git/.gitignore` | net-new | ignore `local` |
| `zsh/.zshrc` | modify (subset additions) | add tool/nicety/git blocks |
| `Brewfile` | modify | add bat/duf/eza/fd/glow/ripgrep |
| `install.sh` | modify | seed `git/local` |
| `README.md` | modify | "set your git identity" note |

---

## Task 1: Vendor Ring 2 verbatim files (configs + git-* scripts)

**Goal:** Bring over, byte-identical, the new config files and the four `git-*` subcommands the aliases need, from `hollow/dotfiles@main`.

**Files:**
- Create: `bat/config`, `git/ignore`, `wgetrc`, `glow/glow.yml`, `glow/styles/catppuccin-mocha.json`
- Create (executable): `zsh/git-main-branch`, `zsh/git-latest`, `zsh/git-cleanup`, `zsh/git-checkout-latest`

**Acceptance Criteria:**
- [ ] All 9 files exist and are byte-identical to the same path in `hollow/dotfiles@main`.
- [ ] The four `zsh/git-*` scripts are executable (mode `100755`) and pass `zsh -n`.
- [ ] `glow/styles/catppuccin-mocha.json` is valid JSON.

**Verify:** `for f in zsh/git-main-branch zsh/git-latest zsh/git-cleanup zsh/git-checkout-latest; do zsh -n "$f" && test -x "$f" || echo "BAD $f"; done; python3 -c "import json; json.load(open('glow/styles/catppuccin-mocha.json'))" && echo OK` → no `BAD` lines, prints `OK`.

**Steps:**

- [ ] **Step 1: Fetch the files**

```bash
set -e
base="https://raw.githubusercontent.com/hollow/dotfiles/main"
mkdir -p bat git glow/styles zsh
curl -fsSL "$base/bat/config"                          -o bat/config
curl -fsSL "$base/git/ignore"                          -o git/ignore
curl -fsSL "$base/wgetrc"                              -o wgetrc
curl -fsSL "$base/glow/glow.yml"                       -o glow/glow.yml
curl -fsSL "$base/glow/styles/catppuccin-mocha.json"   -o glow/styles/catppuccin-mocha.json
for f in git-main-branch git-latest git-cleanup git-checkout-latest; do
    curl -fsSL "$base/zsh/$f" -o "zsh/$f"
    chmod +x "zsh/$f"
done
```

- [ ] **Step 2: Verify byte-identity against upstream**

```bash
tmp="$(mktemp -d)"; git clone -q https://github.com/hollow/dotfiles "$tmp"
st=0
for f in bat/config git/ignore wgetrc glow/glow.yml glow/styles/catppuccin-mocha.json \
         zsh/git-main-branch zsh/git-latest zsh/git-cleanup zsh/git-checkout-latest; do
    diff -q "$f" "$tmp/$f" >/dev/null || { echo "DIFFERS $f"; st=1; }
done
rm -rf "$tmp"
[ "$st" -eq 0 ] && echo IDENTICAL
```
Expected: prints `IDENTICAL`, no `DIFFERS`.

- [ ] **Step 3: Verify scripts executable + parse, JSON valid**

Run: `for f in zsh/git-main-branch zsh/git-latest zsh/git-cleanup zsh/git-checkout-latest; do zsh -n "$f" && test -x "$f" || echo "BAD $f"; done; python3 -c "import json; json.load(open('glow/styles/catppuccin-mocha.json'))" && echo OK`
Expected: no `BAD` lines; prints `OK`.

- [ ] **Step 4: Commit**

```bash
git add bat/config git/ignore wgetrc glow/glow.yml glow/styles/catppuccin-mocha.json \
        zsh/git-main-branch zsh/git-latest zsh/git-cleanup zsh/git-checkout-latest
git commit -m "Vendor Ring 2 config files and git-* subcommands from reference dotfiles"
```

---

## Task 2: Extend the `Brewfile`

**Goal:** Add the Ring 2 tools to the Brewfile, keeping it alphabetical and (except `glow`) a subset of upstream.

**Files:**
- Modify: `Brewfile`

**Acceptance Criteria:**
- [ ] `Brewfile` adds exactly `bat`, `duf`, `eza`, `fd`, `glow`, `ripgrep` (in alphabetical position); `rsync`/`wget` already present from Ring 1.
- [ ] `brew bundle list --file=./Brewfile --all` parses and lists all entries.
- [ ] Every brew/cask entry exists in upstream's `Brewfile` except `glow` (the one expected exception).

**Verify:** `brew bundle list --file=./Brewfile --all >/dev/null && echo PARSE-OK` then the subset check in Step 3 → prints `SUBSET-OK (glow is the only exception)`.

**Steps:**

- [ ] **Step 1: Edit `Brewfile` to this exact content**

```ruby
brew "bash"
brew "bat"
brew "coreutils"
brew "curl"
brew "duf"
brew "eza"
brew "fd"
brew "findutils"
brew "gawk"
brew "gh"
brew "git"
brew "glow"
brew "gnu-getopt"
brew "gnu-sed"
brew "gnu-tar"
brew "gnu-time"
brew "grep"
brew "make"
brew "ripgrep"
brew "rsync"
brew "starship"
brew "wget"
cask "font-meslo-lg-nerd-font"
```

- [ ] **Step 2: Verify it parses**

Run: `brew bundle list --file=./Brewfile --all >/dev/null && echo PARSE-OK`
Expected: prints `PARSE-OK`.

- [ ] **Step 3: Verify subset of upstream (glow excepted)**

```bash
tmp="$(mktemp -d)"; curl -fsSL https://raw.githubusercontent.com/hollow/dotfiles/main/Brewfile -o "$tmp/up.Brewfile"
st=0
while IFS= read -r line; do
    [ -z "$line" ] && continue
    case "$line" in 'brew "glow"') continue;; esac
    grep -Fxq -- "$line" "$tmp/up.Brewfile" || { echo "NOT-IN-UPSTREAM: $line"; st=1; }
done < Brewfile
rm -rf "$tmp"
[ "$st" -eq 0 ] && echo "SUBSET-OK (glow is the only exception)"
```
Expected: prints `SUBSET-OK (glow is the only exception)`.

- [ ] **Step 4: Commit**

```bash
git add Brewfile
git commit -m "Brewfile: add bat, duf, eza, fd, glow, ripgrep (Ring 2 tools)"
```

---

## Task 3: Add Ring 2 blocks to `zsh/.zshrc`

**Goal:** Insert the tool/nicety/git blocks into `.zshrc` at their original upstream relative position, keeping the file a strict line-subset of upstream.

**Files:**
- Modify: `zsh/.zshrc`

**Acceptance Criteria:**
- [ ] All 11 blocks below are present, inserted between the `zi auto has"dscl" for brew` line and the `# starship:` block, in the given order.
- [ ] `zsh -n zsh/.zshrc` parses with exit 0.
- [ ] Every non-blank line of `zsh/.zshrc` exists in upstream's `.zshrc` (strict subset).
- [ ] The git block contains exactly the 14 selected aliases (no `gcu`, no `gdu`, no `git-each`/`git-parallel`).

**Verify:** `zsh -n zsh/.zshrc && echo SYNTAX-OK`; then the subset check in Step 3 → prints `STRICT-SUBSET-OK`.

**Steps:**

- [ ] **Step 1: Insert the following block immediately after the line `zi auto has"dscl" for brew` and before the `# starship:` comment**

(Exact content — preserve the `’` characters in the eza/duf comments and the escaped `\$` in the git aliases.)

```zsh

# bat: cat(1) clone with wings
# https://github.com/sharkdp/bat
:bat-load() {
    export BAT_CONFIG_PATH="${XDG_CONFIG_HOME}"/bat/config BAT_PAGER="less"
    export MANPAGER="sh -c 'col -bx | bat -l man'" MANROFFOPT="-c"
}

zi auto has"bat" wait for bat

# dircolors: setup colors for ls and friends
# https://github.com/trapd00r/LS_COLORS
:dircolors-load() {
    zstyle ":completion:*:default" list-colors "${(s.:.)LS_COLORS}"
}

:dircolors-eval() {
    dircolors -b LS_COLORS
}

zi auto id-as"dircolors" wait for trapd00r/LS_COLORS

# duf: better `df` alternative
# https://github.com/muesli/duf
:duf-load() {
    alias df=duf
}

zi auto has"duf" wait for duf

# eza: a modern replacement for ‘ls’.
# https://github.com/ogham/eza
:eza-load() {
    alias l="eza --all --long --group"
    alias lR="l -R"
}

zi auto has"eza" wait for eza

# git: distributed version control system
# https://github.com/git/git
zi auto id-as"git" as"completion" blockf mv"git->_git" wait for \
    https://github.com/git/git/blob/master/contrib/completion/git-completion.zsh

alias ga="git add --all"
alias gap="git add --patch"
alias gcl="git checkout-latest main"
alias gcm="git co \$(git main-branch)"
alias gd="git diff"
alias gdc="git diff --cached"
alias gdm="git diff origin/\$(git main-branch)"
alias gf="git fetch --prune"
alias gl="git lg"
alias gp="git pull"
alias gpr="git pull --rebase --autostash"
alias grh="git reset HEAD"
alias gsp="git show -p"
alias s="git st ."

# glamour/glow
export GLAMOUR_STYLE="${HOME}/.config/glow/styles/catppuccin-mocha.json"
export GLOW_STYLE="${GLAMOUR_STYLE}"

# less: pager configuration
# https://man7.org/linux/man-pages/man1/less.1.html#OPTIONS
export PAGER="${commands[less]}" LESS="--ignore-case --LONG-PROMPT --RAW-CONTROL-CHARS --HILITE-UNREAD --chop-long-lines --tabs=4"
export LESSHISTFILE="${XDG_DATA_HOME}/less/history"
mkdir -p "$(dirname "${LESSHISTFILE}")"

# man: unix documentation system
# https://www.nongnu.org/man-db/
zi auto wait for OMZP::colored-man-pages

# rsync: fast incremental file transfer
# https://rsync.samba.org
zi auto wait for OMZP::rsync

# wget: retrieve files using HTTP, HTTPS, FTP and FTPS
# https://www.gnu.org/software/wget/
export WGETRC="${XDG_CONFIG_HOME}/wgetrc"
alias wget="wget --hsts-file=\"${XDG_CACHE_HOME}/wget-hsts\""

# reminds you to use existing aliases for commands you just typed
# https://github.com/MichaelAquilina/zsh-you-should-use
if has tput; then
    zi auto wait for MichaelAquilina/zsh-you-should-use
    YSU_MESSAGE_POSITION="after"
fi
```

- [ ] **Step 2: Verify syntax**

Run: `zsh -n zsh/.zshrc && echo SYNTAX-OK`
Expected: prints `SYNTAX-OK`.

- [ ] **Step 3: Verify strict line-subset of upstream**

```bash
tmp="$(mktemp -d)"; curl -fsSL https://raw.githubusercontent.com/hollow/dotfiles/main/zsh/.zshrc -o "$tmp/up.zshrc"
miss=0
while IFS= read -r line; do
    [ -z "$line" ] && continue
    grep -Fxq -- "$line" "$tmp/up.zshrc" || { echo "NOT-IN-UPSTREAM: $line"; miss=1; }
done < zsh/.zshrc
rm -rf "$tmp"
[ "$miss" -eq 0 ] && echo "STRICT-SUBSET-OK"
```
Expected: prints `STRICT-SUBSET-OK`, no `NOT-IN-UPSTREAM` lines.

- [ ] **Step 4: Commit**

```bash
git add zsh/.zshrc
git commit -m "Add Ring 2 .zshrc blocks: CLI tools, niceties, git aliases"
```

---

## Task 4: Add `git/config`, `git/local.example`, and `git/.gitignore`

**Goal:** Provide impersonal shared git defaults + alias block with a `[include]` for per-user identity, a tracked identity template, and a per-directory gitignore for the untracked `local`.

**Files:**
- Create: `git/config`, `git/local.example`, `git/.gitignore`

**Acceptance Criteria:**
- [ ] `git/config` contains upstream's `[alias]`, `[advice]`, `[branch]`, `[color]`, `[diff]`, `[init]`, `[pull]`, `[push]`, `[rerere]` sections byte-identical, omits `[user]`/`[gpg]`/`[commit]`/`[filter "lfs"]`, and ends with a tab-indented `[include] path = local`.
- [ ] Every non-blank line of `git/config` exists in upstream's `git/config` except the two `[include]` lines.
- [ ] `git config -f git/config --list` parses without error and shows `include.path=local`.
- [ ] `git/local.example` contains a commented `[user]` template with `name` and `email` only (no signing).
- [ ] `git/.gitignore` contains `/local`.

**Verify:** `git config -f git/config --get include.path` → prints `local`; then the subset check in Step 4 → prints `GITCONFIG-SUBSET-OK`.

**Steps:**

- [ ] **Step 1: Build `git/config` from upstream (keeps kept lines byte-identical, incl. tabs)**

```bash
base="https://raw.githubusercontent.com/hollow/dotfiles/main"
curl -fsSL "$base/git/config" -o git/config.upstream
awk '
  /^\[/ { skip = ($0=="[user]" || $0=="[gpg]" || $0=="[commit]" || $0=="[filter \"lfs\"]") ? 1 : 0 }
  !skip { print }
' git/config.upstream > git/config
printf '\n[include]\n\tpath = local\n' >> git/config
rm git/config.upstream
```

- [ ] **Step 2: Write `git/local.example` with exactly this content**

```ini
# Personal git identity. Copied to ~/.config/git/local by the installer.
# Edit THIS file's copy (git/local) — it is not tracked in git.
# Until you set these, git will prompt you on your first commit.
[user]
	name = Your Name
	email = you@remerge.io
```

(Indent the `name`/`email` lines with a TAB, matching git config style.)

- [ ] **Step 3: Write `git/.gitignore` with exactly this content**

```gitignore
/local
```

- [ ] **Step 4: Verify**

```bash
git config -f git/config --get include.path   # expect: local
git config -f git/config --list >/dev/null && echo PARSE-OK
tmp="$(mktemp -d)"; curl -fsSL https://raw.githubusercontent.com/hollow/dotfiles/main/git/config -o "$tmp/up.config"
st=0
while IFS= read -r line; do
    [ -z "$line" ] && continue
    case "$line" in '[include]'|*'path = local') continue;; esac
    grep -Fxq -- "$line" "$tmp/up.config" || { echo "NOT-IN-UPSTREAM: $line"; st=1; }
done < git/config
rm -rf "$tmp"
[ "$st" -eq 0 ] && echo "GITCONFIG-SUBSET-OK"
```
Expected: prints `local`, `PARSE-OK`, then `GITCONFIG-SUBSET-OK` (no `NOT-IN-UPSTREAM`).

- [ ] **Step 5: Commit**

```bash
git add git/config git/local.example git/.gitignore
git commit -m "Add impersonal git/config with [include], identity template, gitignore"
```

---

## Task 5: Seed `git/local` from `install.sh`

**Goal:** On first install, copy `git/local.example` → `git/local` if absent, so a fresh user has a ready-to-edit identity file.

**Files:**
- Modify: `install.sh`

**Acceptance Criteria:**
- [ ] A seed step is inserted after the `~/.zshrc` symlink step and before the zsh hand-off (`# 4. Hand off …`).
- [ ] `shellcheck -s sh install.sh` is clean; `sh -n install.sh` parses.
- [ ] The step is idempotent (only copies when `git/local` is absent).

**Verify:** `shellcheck -s sh install.sh && sh -n install.sh && echo LINT-OK`; `grep -q 'git/local.example' install.sh && echo SEED-PRESENT`.

**Steps:**

- [ ] **Step 1: Insert this block in `install.sh`, immediately after the `ln -nfs "$CONFIG_DIR/zsh/.zshrc" "$HOME/.zshrc"` line and its `log` line, before the `# 4. Hand off …` comment**

```sh
# Seed a per-user git identity file (edit it with your name/email).
if [ -f "$CONFIG_DIR/git/local.example" ] && [ ! -f "$CONFIG_DIR/git/local" ]; then
    log "Creating git identity file $CONFIG_DIR/git/local (edit it with your name/email)"
    cp "$CONFIG_DIR/git/local.example" "$CONFIG_DIR/git/local"
fi
```

- [ ] **Step 2: Lint and parse**

Run: `shellcheck -s sh install.sh && sh -n install.sh && echo LINT-OK && grep -q 'git/local.example' install.sh && echo SEED-PRESENT`
Expected: no shellcheck findings; prints `LINT-OK` then `SEED-PRESENT`.

- [ ] **Step 3: Commit**

```bash
git add install.sh
git commit -m "install.sh: seed git/local from template on first install"
```

---

## Task 6: Add "Set your git identity" to `README.md`

**Goal:** Document how a user sets their git identity in `git/local`, including the `--global` caveat.

**Files:**
- Modify: `README.md`

**Acceptance Criteria:**
- [ ] A `### Set your git identity` subsection exists under `## Getting started`.
- [ ] It tells the user to edit `~/.config/git/local` (created by the installer) with name/email, mentions `git config --file ~/.config/git/local …`, and notes git prompts until set.
- [ ] Single top-level `#` heading preserved; no new markdownlint errors beyond the pre-existing `MD013` install-command line.

**Verify:** `grep -q 'git/local' README.md && grep -q 'Set your git identity' README.md && echo README-OK`.

**Steps:**

- [ ] **Step 1: Insert this subsection at the end of the `## Getting started` section (immediately before `## What you get`)**

```markdown
### Set your git identity

The installer creates `~/.config/git/local` for your personal git identity.
Open it and set your name and email:

```ini
[user]
	name = Your Name
	email = you@remerge.io
```

You can also set it from the command line without editing the file:

```sh
git config --file ~/.config/git/local user.name "Your Name"
git config --file ~/.config/git/local user.email "you@remerge.io"
```

Until you set it, git will ask you to configure your name and email on your
first commit. (Avoid `git config --global` here — because this repo lives at
`~/.config`, that may write into the shared `git/config` instead of `local`.)
```

- [ ] **Step 2: Verify**

Run: `grep -q 'git/local' README.md && grep -q 'Set your git identity' README.md && echo README-OK`
Expected: prints `README-OK`.

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "README: document setting git identity via git/local"
```

---

## Task 7: Faithfulness verification + extended smoke test

> **USER-ORDERED GATE — NON-SKIPPABLE.** This task was requested by the user in the current conversation. It MUST NOT be closed by walking around it, by declaring it "verified inline", or by substituting a cheaper check. Close only after every item in `acceptanceCriteria` has been re-validated independently, with output captured.

**Goal:** Prove Ring 2 stays a faithful subset of `hollow/dotfiles@main` (only the enumerated deviations differ) and record the extended manual smoke test.

**Files:**
- Create: `docs/superpowers/plans/2026-05-31-zsh-dotfiles-ring2-smoketest.md`

**Acceptance Criteria:**
- [ ] All vendored files (Task 1's 9 files) are byte-identical to upstream (`diff` clean).
- [ ] `zsh/.zshrc` is a strict line-subset of upstream.
- [ ] Every `Brewfile` entry exists upstream except `glow`.
- [ ] Every `git/config` line exists upstream except the two `[include]` lines.
- [ ] `zsh -n zsh/.zshrc` and `shellcheck -s sh install.sh` pass; glow JSON/YAML parse.
- [ ] Manual smoke-test checklist file exists with the Ring 2 observables.

**Verify:** Run the aggregate script in Step 1 → prints `RING2-FAITHFUL-OK` with no `FAIL`/`DIFFERS`/`NOT-IN-UPSTREAM` lines.

**Steps:**

- [ ] **Step 1: Run the aggregate faithfulness suite**

```bash
tmp="$(mktemp -d)"; git clone -q https://github.com/hollow/dotfiles "$tmp"
st=0
# vendored byte-identity
for f in bat/config git/ignore wgetrc glow/glow.yml glow/styles/catppuccin-mocha.json \
         zsh/git-main-branch zsh/git-latest zsh/git-cleanup zsh/git-checkout-latest; do
    diff -q "$f" "$tmp/$f" >/dev/null || { echo "DIFFERS $f"; st=1; }
done
# .zshrc strict subset
while IFS= read -r l; do [ -z "$l" ] && continue; grep -Fxq -- "$l" "$tmp/zsh/.zshrc" || { echo "ZSHRC NOT-IN-UPSTREAM: $l"; st=1; }; done < zsh/.zshrc
# Brewfile subset (glow excepted)
while IFS= read -r l; do [ -z "$l" ] && continue; case "$l" in 'brew "glow"') continue;; esac; grep -Fxq -- "$l" "$tmp/Brewfile" || { echo "BREW NOT-IN-UPSTREAM: $l"; st=1; }; done < Brewfile
# git/config subset (include excepted)
while IFS= read -r l; do [ -z "$l" ] && continue; case "$l" in '[include]'|*'path = local') continue;; esac; grep -Fxq -- "$l" "$tmp/git/config" || { echo "GITCFG NOT-IN-UPSTREAM: $l"; st=1; }; done < git/config
rm -rf "$tmp"
# syntax/lint/validity
zsh -n zsh/.zshrc || { echo "FAIL zsh -n"; st=1; }
shellcheck -s sh install.sh || { echo "FAIL shellcheck"; st=1; }
python3 -c "import json; json.load(open('glow/styles/catppuccin-mocha.json'))" || { echo "FAIL json"; st=1; }
python3 -c "import yaml,sys; yaml.safe_load(open('glow/glow.yml'))" 2>/dev/null || echo "WARN: yaml check skipped (no pyyaml)"
[ "$st" -eq 0 ] && echo "RING2-FAITHFUL-OK"
```
Expected: prints `RING2-FAITHFUL-OK`; no `DIFFERS`/`NOT-IN-UPSTREAM`/`FAIL` lines. (A `WARN: yaml check skipped` is acceptable if PyYAML is absent.)

- [ ] **Step 2: Write the smoke-test checklist**

Create `docs/superpowers/plans/2026-05-31-zsh-dotfiles-ring2-smoketest.md`:

```markdown
# Ring 2 smoke test (manual)

On a Mac after merging and opening a fresh shell:

- [ ] `l` lists files via eza, colorized (LS_COLORS active).
- [ ] `bat README.md` paginates with the Catppuccin theme; `man ls` is colorized.
- [ ] `df` invokes duf (table output).
- [ ] `glow README.md` renders markdown with the Catppuccin Mocha theme.
- [ ] Typing a command that has an alias triggers a `you-should-use` reminder.
- [ ] `gd`, `gdc`, `gl`, `s` work; `gcm`/`gcl`/`gdm` resolve the main branch
      (via the `git-main-branch` subcommand).
- [ ] `git config user.email` is empty until you edit `~/.config/git/local`;
      after editing, it reflects your address and commits use it.
- [ ] `rg`, `fd` run (installed via Brewfile; no shell config needed).
```

- [ ] **Step 3: Commit**

```bash
git add docs/superpowers/plans/2026-05-31-zsh-dotfiles-ring2-smoketest.md
git commit -m "Add Ring 2 faithfulness results and smoke-test checklist"
```

---

## Notes & Known Considerations

- **`glow` Brewfile deviation:** the only non-subset Brewfile line until the repo owner adds glow upstream. The faithfulness checks explicitly except it.
- **`git config --global` writes:** because the repo is `~/.config`, `git config --global` may write into the tracked `git/config`. Mitigated by README guidance to use `git/local` (or `git config --file`). Not engineered around.
- **`git-*` autoload:** the four scripts are also registered as autoloaded zsh functions by `autoload -Uz ${ZDOTDIR}/*(.N:t)`; git invokes the PATH executable. Harmless, matches upstream.
- **Signing deferred:** `git/local.example` has no signing keys; SSH/GPG integration is a later ring.

## Self-Review

- **Spec coverage:** vendored configs + git-* scripts → Task 1; Brewfile → Task 2; `.zshrc` blocks (tools/niceties/git aliases) → Task 3; `git/config`+`local.example`+`.gitignore`+`[include]` → Task 4; install.sh seed → Task 5; README identity note → Task 6; faithfulness + smoke test → Task 7. All covered.
- **Placeholder scan:** none — every block is inline; every Verify is a runnable command with expected output.
- **Consistency:** the 14 git aliases (no `gcu`/`gdu`), the `git-*` script names, the `[include] path = local` directive, `GLAMOUR_STYLE`/`GLOW_STYLE`, and `BAT_CONFIG_PATH`/`WGETRC` env names match the spec and across tasks.
