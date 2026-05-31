# Remerge dotfiles — Ring 2 (everyday CLI niceties) design

**Date:** 2026-05-31
**Status:** Approved (design); ready for implementation planning
**Repo:** <https://github.com/remerge/dotfiles>
**Builds on:** Ring 0 + Ring 1 (merged) — see
`docs/superpowers/specs/2026-05-28-zsh-dotfiles-skeleton-design.md`

## Goal

Extend the merged zsh skeleton with the "everyday CLI niceties" from the Ring 1
roadmap, staying a faithful **subset** of <https://github.com/hollow/dotfiles>:
a `diff` against upstream should show only deletions, the previously-trimmed
files, and a small set of clearly-flagged intentional deviations.

Ring 2 adds modern CLI tools, a few shell niceties, the full git alias set with
its supporting `git-*` subcommands, impersonal git defaults, and a clean
per-user git-identity mechanism. fzf, atuin, and git signing remain deferred.

## Scope (decided)

In scope:

- **Modern CLI tools:** `eza`, `bat`, `fd`, `ripgrep`, plus `duf`, `rsync`,
  `wget`, and `glow`/`glamour`.
- **Shell niceties:** pager/`less` config, `colored-man-pages`, `you-should-use`,
  `dircolors` (LS_COLORS).
- **git:** impersonal `git/config` (settings **and** the generic alias block),
  the global `git/ignore`, the selected zsh git aliases plus the `git-*`
  subcommands they need, and per-user identity via a git `[include]`.

Out of scope (still deferred): fzf/fzf-tab, atuin, git signing (SSH/GPG
integration — to be handled in a later ring), the `git-each`/`git-parallel`
batch aliases (depend on the dropped `:each`/`:parallel`), and a general zsh
personal-override layer.

## Faithfulness principle (carried over)

Every kept line stays byte-identical to upstream. `zsh/.zshrc` remains a strict
line-subset (only upstream lines, re-inserted at their original relative
positions between the brew bootstrap and the starship block). Deviations are
explicit and enumerated below.

### Intentional deviations (net-new, not in upstream)

1. `brew "glow"` in the `Brewfile` — upstream's `Brewfile` does not list glow.
   The repo owner will add glow upstream, after which this returns to a subset.
2. `git/config` omits upstream's personal sections and ends with an
   `[include] path = local` directive (see below).
3. `git/local.example` — a tracked template for per-user git identity.

`git/local` itself is **not** ignored: the intended model is that a user forks
this repo and commits their own `git/local` to their fork (the `[include]` just
reads whatever is present). The skeleton ships only `git/local.example`; a fresh
install seeds `git/local` from it for the user to edit and commit.

## File inventory

### Modify

- `Brewfile` — add `bat`, `duf`, `eza`, `fd`, `glow`, `ripgrep` (alphabetical;
  `rsync`/`wget` already present from Ring 1).
- `zsh/.zshrc` — add the tool/nicety/git blocks below (strict subset).
- `install.sh` — seed `git/local` from the template (one added step).
- `README.md` — add a short "set your git identity" note.

### Create — vendored verbatim from `hollow/dotfiles@main`

- `bat/config`
- `git/ignore`
- `wgetrc`
- `glow/glow.yml`
- `glow/styles/catppuccin-mocha.json`
- `zsh/git-main-branch`, `zsh/git-latest`, `zsh/git-cleanup`,
  `zsh/git-checkout-latest` — the `git-*` subcommands the aliases need
  (executable; see "git subcommands" below).

### Create — net-new (intentional deviations)

- `git/config` — impersonal settings + alias block + the `[include]` directive.
- `git/local.example` — commented `[user]` identity template (name + email).

`git/local` is intentionally **not** gitignored, so a fork can commit it.

### Not added

- `ripgrep` and `fd` are **Brewfile-only** — upstream removed their no-op
  `zi auto … for` null-plugin lines, so there is no `.zshrc` block for either.

## `zsh/.zshrc` additions

All blocks below are byte-identical to upstream and inserted preserving
upstream's relative order (between `zi auto has"dscl" for brew` and the starship
block).

**bat:**

```zsh
# bat: cat(1) clone with wings
# https://github.com/sharkdp/bat
:bat-load() {
    export BAT_CONFIG_PATH="${XDG_CONFIG_HOME}"/bat/config BAT_PAGER="less"
    export MANPAGER="sh -c 'col -bx | bat -l man'" MANROFFOPT="-c"
}

zi auto has"bat" wait for bat
```

**dircolors:**

```zsh
# dircolors: setup colors for ls and friends
# https://github.com/trapd00r/LS_COLORS
:dircolors-load() {
    zstyle ":completion:*:default" list-colors "${(s.:.)LS_COLORS}"
}

:dircolors-eval() {
    dircolors -b LS_COLORS
}

zi auto id-as"dircolors" wait for trapd00r/LS_COLORS
```

**duf:**

```zsh
# duf: better `df` alternative
# https://github.com/muesli/duf
:duf-load() {
    alias df=duf
}

zi auto has"duf" wait for duf
```

**eza:**

```zsh
# eza: a modern replacement for ‘ls’.
# https://github.com/ogham/eza
:eza-load() {
    alias l="eza --all --long --group"
    alias lR="l -R"
}

zi auto has"eza" wait for eza
```

**git (completion + the selected zsh aliases):**

```zsh
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
```

These are the 14 selected zsh aliases (the 8 self-contained ones plus the
requested `gcl`, `gcm`, `gdm`, `gdc`, `gl`, `s`). Note: `gdc` is now
`git diff --cached` (self-contained) per the upstream update; the old `dc`
git-config alias is gone. **Excluded** (not requested): the `gcu`/`gdu`
"upstream"-remote aliases and the `git-each`/`git-parallel` batch aliases
(which also need the dropped `:each`/`:parallel`).

**glamour/glow:**

```zsh
# glamour/glow
export GLAMOUR_STYLE="${HOME}/.config/glow/styles/catppuccin-mocha.json"
export GLOW_STYLE="${GLAMOUR_STYLE}"
```

**less / pager:**

```zsh
# less: pager configuration
# https://man7.org/linux/man-pages/man1/less.1.html#OPTIONS
export PAGER="${commands[less]}" LESS="--ignore-case --LONG-PROMPT --RAW-CONTROL-CHARS --HILITE-UNREAD --chop-long-lines --tabs=4"
export LESSHISTFILE="${XDG_DATA_HOME}/less/history"
mkdir -p "$(dirname "${LESSHISTFILE}")"
```

**colored-man-pages:**

```zsh
# man: unix documentation system
# https://www.nongnu.org/man-db/
zi auto wait for OMZP::colored-man-pages
```

**rsync:**

```zsh
# rsync: fast incremental file transfer
# https://rsync.samba.org
zi auto wait for OMZP::rsync
```

**wget:**

```zsh
# wget: retrieve files using HTTP, HTTPS, FTP and FTPS
# https://www.gnu.org/software/wget/
export WGETRC="${XDG_CONFIG_HOME}/wgetrc"
alias wget="wget --hsts-file=\"${XDG_CACHE_HOME}/wget-hsts\""
```

**you-should-use:**

```zsh
# reminds you to use existing aliases for commands you just typed
# https://github.com/MichaelAquilina/zsh-you-should-use
if has tput; then
    zi auto wait for MichaelAquilina/zsh-you-should-use
    YSU_MESSAGE_POSITION="after"
fi
```

## git subcommands (`git-*` scripts)

Several aliases invoke custom git subcommands. git finds `git-<name>` on `PATH`;
`zsh/` is already on `PATH` (`path+=("${ZDOTDIR}")`), so these scripts live in
`zsh/`. They are **vendored verbatim** from upstream and must keep the
**executable bit** (git executes them as subprocesses).

Dependency closure of the aliases:

- `gcl` → `git checkout-latest main` → `git-checkout-latest`, which calls
  `git-main-branch`, `git-latest`, and `git-cleanup`.
- `gcm`, `gdm` → `git-main-branch`.
- `git-latest` → `git-main-branch`.

So four scripts are vendored: `git-main-branch`, `git-latest`, `git-cleanup`,
`git-checkout-latest`. They are also picked up by the existing
`autoload -Uz ${ZDOTDIR}/*(.N:t)` glob (harmless; git invokes the PATH
executable). The remaining aliases use the git-config aliases below
(`co`, `lg`, `st`) or are plain git commands.

## `Brewfile` additions

Final brew list (alphabetical) gains `bat`, `duf`, `eza`, `fd`, `glow`,
`ripgrep`. All exist in upstream's `Brewfile` **except `glow`** (the single
flagged deviation, pending the upstream add).

## `git/config`

Tracked and impersonal. Built from upstream's `git/config` by **keeping these
sections verbatim** (tab-indented, byte-identical):

- `[alias]` — the full upstream block: `aliases`, `amend`, `b`, `ci`, `co`,
  `lg`, `ls`, `st`, `stat`, `tags`, `w`. (Upstream no longer defines `dc`.)
- `[advice] detachedHead = false`
- `[branch] sort = -committerdate`
- `[color] ui = true`
- `[diff] renames = copies`
- `[init] defaultBranch = main`
- `[pull] ff = only`
- `[push] followTags = true`, `autoSetupRemote = true`
- `[rerere] enabled = true`

**Omitted** (personal / deferred): `[user]`, `[gpg]`, `[commit] gpgsign`, and
`[filter "lfs"]`.

**Appended** (net-new): the include directive. In the actual file it is
tab-indented like every git-config value:

```ini
[include]
    path = local
```

## git identity via `[include]`

A relative include `path` resolves against the including file's directory, so
`path = local` reads `~/.config/git/local`. That file is per-user and untracked,
holding only personal identity:

```ini
# ~/.config/git/local  (yours; never committed)
[user]
    name = Your Name
    email = you@remerge.io
```

`git/local.example` is the tracked template with exactly the two `[user]` lines
above (commented). **No signing example** — SSH/GPG signing is deferred to a
later ring.

- A **missing** include is silently ignored by git, so before identity is set,
  git shows its normal "tell me who you are" prompt on first commit.
- `git config user.email` reflects the real value once set.
- `install.sh` copies `git/local.example` → `git/local` on first install if
  absent. `zsh/.zshrc` is untouched.
- `git/local` is **not** gitignored: a user forks this repo and commits their
  own `git/local` to their fork. The skeleton tracks only `git/local.example`.

**Caveat (documented in README):** because the repo lives at `~/.config`, the
tracked `git/config` *is* git's XDG global file. `git config --global …` may
write into it rather than `local`. The README steers users to edit `git/local`
(or use `git config --file ~/.config/git/local …`).

## `install.sh` change

After the symlink step and before the zsh hand-off, add:

```sh
# Seed a per-user git identity file (edit it with your name/email).
if [ -f "$CONFIG_DIR/git/local.example" ] && [ ! -f "$CONFIG_DIR/git/local" ]; then
    cp "$CONFIG_DIR/git/local.example" "$CONFIG_DIR/git/local"
fi
```

## README change

Add a short "Set your git identity" subsection under **Getting started**:
edit `~/.config/git/local` with your name and email (the installer creates it
from a template). Mention the `git config --file` form and that git will prompt
until it's set.

## Verification

- **Vendored verbatim files** (`bat/config`, `git/ignore`, `wgetrc`,
  `glow/glow.yml`, `glow/styles/catppuccin-mocha.json`, and the four `git-*`
  scripts) → `diff` byte-identical against `hollow/dotfiles@main`.
- **`git-*` scripts** are executable (`test -x`) and `zsh -n`-clean.
- **`zsh/.zshrc`** → strict line-subset: every non-blank line exists in
  upstream's `.zshrc`. `zsh -n zsh/.zshrc` passes.
- **`Brewfile`** → every entry exists in upstream's `Brewfile` except `glow`
  (the sole expected exception); `brew bundle list --file=./Brewfile --all`
  parses.
- **`git/config`** → every line exists in upstream's `git/config` except the
  net-new `[include]` / `path = local` lines; `git config -f git/config --list`
  parses.
- **Validity:** `glow/styles/catppuccin-mocha.json` parses as JSON;
  `glow/glow.yml` parses as YAML.
- **Net-new, not checked against upstream:** `git/local.example`, the
  `[include]` directive, `brew "glow"`, and the `install.sh` seed step.
- **Manual smoke test (extended):** `l` (eza, colored), `bat` paging + colored
  man pages, a `you-should-use` reminder, `df` → duf, `glow` renders a markdown
  file with the theme, `gl`/`gd`/`s` work, `gcl`/`gcm` resolve the main branch
  via `git-main-branch`, and `git config user.email` reflects `git/local` once
  set.

## Acceptance criteria

- All Ring 2 tools install via `brew bundle` and their `.zshrc` blocks load
  without error on a fresh shell.
- The 14 selected zsh git aliases work, including `gcl`/`gcm`/`gdm` via the
  vendored `git-*` subcommands and `gl`/`s` via the git-config aliases.
- The faithfulness checks above pass (only the enumerated deviations differ).
- A fresh install seeds `git/local`; editing it sets the user's git identity;
  an unedited or missing `git/local` leaves git prompting normally.
- `LICENSE` and the Ring 1 files remain unchanged except the `Brewfile`,
  `zsh/.zshrc`, `install.sh`, and `README.md` edits described here.
