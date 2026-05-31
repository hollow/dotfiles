# Remerge dotfiles skeleton — design

**Date:** 2026-05-28
**Status:** Approved (design); ready for implementation planning
**Repo:** <https://github.com/remerge/dotfiles>

## Goal

Provide a "golden" dotfiles skeleton — primarily a zsh configuration — that any
Remerge employee (and the public) can install on a fresh Mac with a single
command, with **no prior knowledge of terminals, shells, or package managers**.

The skeleton is derived from the author's personal dotfiles
(<https://github.com/hollow/dotfiles>) and must remain a faithful **subset** of
that repo: a `diff -r` against `hollow/dotfiles` should show only (a) deletions
of personal/advanced content, (b) two trimmed files (`zsh/.zshrc`, `Brewfile`),
and (c) additive new files (`install.sh`, rewritten `README.md`). Nothing is
reinvented or restructured.

This first spec covers **Ring 0 (bootstrap) + Ring 1 (core shell)** only. Later
rings (everyday CLI niceties, Remerge tooling, personal override layer) are
explicitly out of scope and listed under "Roadmap / out of scope".

## What the user gets

A modern zsh on a fresh Mac, set up automatically:

- **zi** plugin manager (self-installs on first shell launch)
- **Homebrew** + a small `Brewfile` (self-installs/bundles on first shell launch)
- **starship** prompt (catppuccin-mocha, nerd-font symbols)
- Common zsh/zi plugins: **F-Sy-H** (syntax highlighting), **zsh-autosuggestions**,
  **zsh-autopair**, **zsh-completions**
- Oh-My-Zsh library modules (completion, directories, functions, grep, history,
  key-bindings, spectrum, termsupport)
- Sensible history + completion configuration

Installation is one command; first terminal launch finishes the bootstrap.

## Architecture

### Deployment model (faithful to the reference)

- The repo is **cloned into `~/.config`** — `~/.config` *is* the repo root.
  This makes `~/.config/Brewfile`, `~/.config/starship.toml`, and
  `~/.config/zsh/` resolve at the paths the config and tools expect
  (`HOMEBREW_BUNDLE_FILE`, starship's default config path, `ZDOTDIR`).
- Only `~/.config/zsh/.zshrc` is symlinked to `~/.zshrc`. There is **no
  `.zshenv`**; `.zshrc` itself sets `XDG_*`, `ZDOTDIR`, etc. at the top, then
  `autoload -Uz ${ZDOTDIR}/*(.N:t)` autoloads the helper functions in `zsh/`.
- macOS already defaults to zsh (Catalina+), so **no `chsh`** is needed.

### First-run self-bootstrap (preserved verbatim)

The shell config bootstraps everything on first launch — `install.sh` does
**not** install Homebrew or run `brew bundle`. Mechanism:

1. `.zshrc` sets up XDG/zi and sources `zzinit`, which clones `z-shell/zi` if
   absent and loads it.
2. The local **`z-a-auto`** annex (`zsh/z-a-auto/z-a-auto.plugin.zsh`) provides
   the `zi auto has"…" for <target>` convention, mapping zi lifecycle hooks to
   `:<target>-init` / `:<target>-load` / `:<target>-eval` / `:<target>-update`
   functions.
3. `zi auto has"dscl" for brew` registers `brew` as a null-plugin (gated to
   macOS via the macOS-only `dscl` binary). On first install zi fires the
   `atclone` hook → `:brew-update`, which installs Homebrew (if missing) and runs
   `brew bundle` against `~/.config/Brewfile`. The `atinit` hook → `:brew-init`
   wires up `HOMEBREW_*` env vars, gnubin `PATH` entries, and brew aliases.
4. zi then installs the configured plugins; starship loads `if has starship`.

Subsequent launches are fast (everything cached).

### Linux (best-effort)

`install.sh` skips Xcode Command Line Tools, assumes `git` is present, and
clones + symlinks the same way. The `dscl` gate means the brew bootstrap does
**not** auto-fire on Linux; zi + plugins still work, and starship loads only if
already installed. This is documented in the README, not engineered around.

## File inventory

### Keep verbatim (byte-identical to `hollow/dotfiles`)

- `zsh/zzinit` — zi loader
- `zsh/z-a-auto/z-a-auto.plugin.zsh` — powers `zi auto … for` + first-run bootstrap
- `zsh/.gitignore` — `**/*.zwc`
- `zsh/has` — `type "$1" &>/dev/null || test -e "/$1"` (used pervasively)
- `zsh/add` — unique array append/prepend helper (`add path …`, `add fpath …`)
- `zsh/link` — idempotent symlink helper (autoloads `uri-parse`)
- `zsh/uri-parse` — dependency of `link`
- `starship.toml` — prompt config (catppuccin-mocha palette, nerd-font symbols)

### Preserve existing (do NOT overwrite)

- `LICENSE` — the repo already ships its own Apache 2.0 `LICENSE` (from the
  initial commit). Keep it untouched; do **not** copy `hollow/dotfiles`'s
  license over it.

### Keep trimmed

- `zsh/.zshrc` — core scaffold + Ring 1 only (see below)
- `Brewfile` — essentials only (see below)

### Add (new, additive only)

- `install.sh` — Xcode CLT + clone + symlink + re-exec zsh
- `README.md` — rewritten for non-technical users

### Drop (everything else in `hollow/dotfiles`)

- The entire personal function zoo: `git-*`, `gh-*`, `ghc`, `ghm`, `pr`,
  `aws-each-region`, `ara-client`, `ara-server`, `assh`, `sshlive`, `tfa`,
  `tfe`, `tfp`, `find-terraform-providers-modules`, `mknative`, `:each`,
  `:parallel`, `grc`, `cdl`, `cdu`, `IP`, `pw`, `sl`, `debug`, `autocall`,
  `ah`, `netping`, `clone`.
  - `clone` is dropped because its only caller (`:tmux-update`) is dropped.
  - `uri-parse` is kept *only* because `link` autoloads it.
- All non-Ring-1 tool config directories: `atuin/`, `bat/`, `bottom/`, `btop/`,
  `colima/`, `gcloud/`, `gh/`, `ghostty/`, `git/`, `glow/`, `gws/`, `hcloud/`,
  `helm/`, `macos/`, `mc/`, `mise/`, `npm/`, `op/`, `parallel/`, `pip/`,
  `python/`, `raycast/`, `ripgrep/`, `ssh/`, `terraform/`, `tmux/`, `vim/`,
  `vscode/`, `yarn/`, `auth0/`, `.vscode/`, `.claude/`, and loose files
  (`.actrc`, `ncduignore`, `wgetrc`).

## `zsh/.zshrc` — trim specification

Keep the exact ordering and idioms of the source file; remove blocks only.

### Kept (core scaffold)

- locale (`LANG`/`LC_CTYPE`), `COLORTERM`, `setopt extendedglob`, `ulimit`,
  `select-word-style shell`
- system `path`; all `XDG_*` vars + `mkdir`/`chmod`; `ZDOTDIR`/`ZSH_DATA_DIR`/
  `ZSH_CACHE_DIR` + `mkdir`; `fpath`; `path+=("${ZDOTDIR}")`;
  `autoload -Uz ${ZDOTDIR}/*(.N:t)`
- early Homebrew `shellenv` block (`if has /opt/homebrew/bin/brew`)
- `add path "${HOME}/.local/bin"`; compiler-flags `typeset` block
- zi setup (`typeset -Ag ZI`, `ZI[HOME_DIR]`, `ZI[BIN_DIR]`) +
  `source "${ZDOTDIR}/zzinit" && zzinit`
- `zre` / `zx` aliases
- z-a-default-ice, z-a-eval, z-a-auto loads + `zi default-ice -q lucid light-mode`
- OMZL libs + `COMPLETION_WAITING_DOTS="true"`:
  `completion.zsh directories.zsh functions.zsh grep.zsh history.zsh
  key-bindings.zsh spectrum.zsh termsupport.zsh`
- `..` / `...` / `....` / `.....` cd aliases
- history config (`HISTSIZE`/`SAVEHIST`/`HISTFILE` + `link "${HISTFILE}" .zsh_history`)
- the full completion `zstyle` block
- `:brew-init` + `:brew-update` + `zi auto has"dscl" for brew` (**the bootstrap**)
- starship init block (`if has starship` → `eval "$(starship init zsh)"` →
  `unset RPROMPT`)

### Kept (common plugins)

- F-Sy-H — `zi auto atinit"zicompinit; zicdreplay" wait for z-shell/F-Sy-H`
- zsh-autosuggestions — `zi auto atload"_zsh_autosuggest_start" wait for zsh-users/zsh-autosuggestions`
- zsh-autopair — `zi auto wait for hlissner/zsh-autopair`
- zsh-completions — `zi auto blockf atpull'…creinstall…' wait for zsh-users/zsh-completions`

### Trimmed in place

- `zup()` → keep only `:brew-update && zi self-update && zi update --all`
  (drop `:uv-update`, `:tmux-update`, `:gcloud-update`)

### Dropped from `.zshrc`

- The `USER_NAME` / `USER_EMAIL` block (personal; git/gpg identity belongs in the
  user's own git config).
- Every tool block: python/uv, argcomplete, vscode, 1password-cli, android,
  ansible, ara, atuin, aws, bat, boto, checkov, claude-desktop copy, consul,
  copier, dircolors, direnv, docker, duf, eza, fd, fzf + fzf-tab, gcloud,
  ghostty, git completion + git aliases, gnupg, go, glow, less/pager,
  colored-man-pages, mc, ncdu, mise, nomad, node, npm, parallel, postgresql,
  ripgrep, rsync, ruby, sqlite, ssh + ssh config linking, sshp, terraform,
  tmux/xpanes, neovim/vim, wget, yt-dlp, the `X` alias, you-should-use,
  zsh-bench, and the trailing `.envrc` block.

## `Brewfile` — specification

Option (b), "coherent": include the prompt, a nerd font, the core GNU tools that
`:brew-init` adds to `PATH` (so those gnubin entries are meaningful), `git`/`gh`,
and a handful of common base CLI tools that ship in the reference Brewfile
(`bash`, `curl`, `gnu-getopt`, `rsync`, `wget`).

```ruby
brew "bash"
brew "coreutils"
brew "curl"
brew "findutils"
brew "gawk"
brew "gh"
brew "git"
brew "gnu-getopt"
brew "gnu-sed"
brew "gnu-tar"
brew "gnu-time"
brew "grep"
brew "make"
brew "rsync"
brew "starship"
brew "wget"
cask "font-meslo-lg-nerd-font"
```

(Alphabetical, matching the reference Brewfile's style. All entries also appear
in `hollow/dotfiles`, keeping this a strict subset.)

## `starship.toml` — specification

Kept verbatim from `hollow/dotfiles`. No changes.

## `install.sh` — specification

POSIX `sh`, idempotent. Runnable via `curl … | sh` or after a manual clone.

1. Detect OS (`uname`).
2. **macOS:** if `xcode-select -p` fails, run `xcode-select --install` and poll
   until `git` is available (the CLT installer is a GUI prompt — the script must
   wait for completion before continuing).
3. Clone `https://github.com/remerge/dotfiles` → `~/.config`. Handle the case
   where `~/.config` already exists (e.g. `git init` + add remote + fetch +
   checkout, rather than failing on a non-empty target), since the XDG config
   dir frequently pre-exists.
4. `ln -nfs ~/.config/zsh/.zshrc ~/.zshrc`.
5. **Re-exec into a fresh interactive zsh** to load the new config and trigger
   the self-bootstrap immediately.
   - Implementation note: under `curl … | sh`, stdin is the (now-spent) pipe, not
     a TTY. The hand-off must reattach the terminal, e.g.
     `exec zsh -i </dev/tty`, or the new zsh reads EOF from the pipe and exits.
6. **Linux (best-effort):** skip step 2; assume `git` present; clone + symlink as
   above; re-exec zsh. Print a note that Homebrew/starship will not auto-install
   (the `dscl` gate is macOS-only) and point to the README.

## `README.md` — specification

Written for someone who has never used a terminal:

- One sentence: what this gives you (a fully set-up modern zsh: prompt,
  autosuggestions, syntax highlighting, autocompletion).
- **Install** — the single command:

  ```sh
  curl -fsSL https://raw.githubusercontent.com/remerge/dotfiles/main/install.sh | sh
  ```

- "What happens" (3 bullets: installs developer tools + Homebrew, sets up your
  shell, done — the first launch takes a minute).
- "What you get" — short bullet list (zi, starship, the four plugins, OMZL libs).
- "Updating later" — one line: run `zup`.
- Short macOS-vs-Linux note (Linux = best-effort, see above).

## Roadmap / out of scope (not built in this spec)

- **Ring 2 — everyday CLI niceties:** pager/`less` config,
  `colored-man-pages`, `you-should-use`, eza/bat/fd/ripgrep + configs, fzf,
  atuin, git aliases, `zup` extensions.
- **Ring 3 — Remerge tooling (opt-in):** gcloud, terraform, 1Password CLI,
  mise/asdf, kubectl, helm.
- **Ring 4 — personal override layer:** a git-ignored
  `~/.config/zsh/local.zsh` for per-employee customization. Deliberately **not**
  added now, as it would be a deviation from the reference repo.

## Acceptance criteria

- A fresh Mac runs the one-line installer and, after the installer re-execs zsh,
  ends up with a working zsh: starship prompt rendered with nerd-font glyphs,
  syntax highlighting, autosuggestions, autopair, and completion all active.
- `git diff`/`diff -r` against `hollow/dotfiles` shows only: dropped files, the
  two trimmed files, and the additive `install.sh` + `README.md`.
- Re-running `install.sh` on an already-installed machine is safe (idempotent).
- `zup` updates Homebrew bundle + zi + plugins.
