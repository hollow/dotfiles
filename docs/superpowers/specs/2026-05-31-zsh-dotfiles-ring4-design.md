# Remerge dotfiles — Ring 4 (ghostty, tailscale, 1Password) design

**Date:** 2026-05-31
**Status:** Approved (design); ready for implementation planning
**Repo:** <https://github.com/remerge/dotfiles>
**Builds on:** Rings 0–3 (merged) — see
`docs/superpowers/specs/2026-05-31-zsh-dotfiles-ring3-design.md`
**Upstream pin:** `hollow/dotfiles@main` at commit `5fd2f15`

## Goal

Add the first GUI applications (Homebrew casks) plus two CLIs to the dotfiles,
staying a faithful **subset** of <https://github.com/hollow/dotfiles>: a `diff`
against upstream should show only deletions and the previously-trimmed files.

Ring 4 adds a terminal (`ghostty`), a VPN (`tailscale`, CLI + app), and a
password manager (`1password`, app + `op` CLI). It introduces **no intentional
deviations** — every cask, brew, and config file is byte-identical to upstream
and present in upstream's `Brewfile`.

## Scope (decided)

In scope:

- **ghostty**: terminal emulator — `cask "ghostty"`, the vendored
  `ghostty/config`, and the upstream `add path "${GHOSTTY_BIN_DIR}"` `.zshrc`
  line.
- **tailscale**: `brew "tailscale"` (CLI) + `cask "tailscale-app"` (GUI). No
  `.zshrc` block.
- **1Password**: `cask "1password"` (app) + `cask "1password-cli"` (`op`), the
  vendored `op/.gitignore`, and the `:1password-cli-eval` completion `.zshrc`
  block.

Out of scope / deferred:

- **VSCode**: deferred to its own dedicated ring (cask + ~90 extensions + the
  `settings`/`keybindings`/`mcp` config files + the `:vscode-load` block warrant
  separate planning).
- **1Password SSH agent**: the `SSH_AUTH_SOCK` → 1Password-agent export is
  tangled inside upstream's `ssh` section (with `link ssh/config` and an
  `OMZP::ssh-agent` fallback). Deferred to a future `ssh` ring; Ring 4 ports only
  the self-contained app + CLI + completion.

## Faithfulness principle (carried over)

Every kept line stays byte-identical to upstream. `zsh/.zshrc` remains a strict
line-subset: only upstream lines, re-inserted at their original relative
positions. **Ring 4 adds no deviations** — `ghostty`, `tailscale`,
`tailscale-app`, `1password`, and `1password-cli` are all present in upstream's
`Brewfile`.

## File inventory

### Modify

- `Brewfile` — add `brew "tailscale"`, and casks `1password`, `1password-cli`,
  `ghostty`, `tailscale-app`.
- `zsh/.zshrc` — add the 1Password and ghostty blocks (strict subset; see below).

### Create — vendored verbatim from `hollow/dotfiles@5fd2f15`

- `ghostty/config` — ghostty's config (typography, Catppuccin Mocha theme,
  macOS keybindings, scrollback, working-directory). Self-contained.
- `op/.gitignore` — the `*` / `!.gitignore` pattern that keeps the `op` config
  directory present in the repo but ignores its (private) contents.

### Not added

- **ghostty** and **tailscale** need no vendored config beyond `ghostty/config`
  (tailscale has none).
- **VSCode** (deferred): no cask, no extensions, no config files, no
  `.zshrc` block.
- The 1Password **SSH-agent** block and the `ssh/` config (deferred).

## Path mapping

The repo lives at `~/.config`, so vendored directories map directly:

- `ghostty/config` → `~/.config/ghostty/config` (ghostty's default config path on
  macOS).
- `op/.gitignore` → `~/.config/op/.gitignore`. The `:1password-cli-eval` block
  runs `chmod 0700 "${XDG_CONFIG_HOME}/op"`, so the directory must exist; the
  tracked `.gitignore` guarantees it does while keeping `op`'s runtime files out
  of git.

## `zsh/.zshrc` additions

Both blocks below are byte-identical to upstream and inserted preserving
upstream's relative order. Upstream's order among the blocks this repo has is
`brew → 1password → bat → … → eza → ghostty → git → …` (VSCode, which upstream
places between `brew` and `1password`, is skipped). So the **1Password** block is
inserted between the existing `brew` block and the existing `bat` block, and the
**ghostty** block is inserted between the existing `eza` block and the existing
`git` block.

**1Password** (between `brew` and `bat`):

```zsh
# 1password: remembers all your passwords for you
# https://1password.com
:1password-cli-eval() {
    chmod 0700 "${XDG_CONFIG_HOME}/op"
    op completion zsh
}

zi auto has"op" wait for 1password-cli
```

`:1password-cli-eval` (a z-a-eval cached hook) secures the `op` config dir and
emits `op`'s zsh completion. The `zi auto has"op" …` line loads it only when the
`op` CLI is present.

**ghostty** (between `eza` and `git`):

```zsh
# ghostty
add path "${GHOSTTY_BIN_DIR}"
```

`GHOSTTY_BIN_DIR` is injected into the environment by the Ghostty terminal when
it launches the shell; the line adds Ghostty's bundled binaries to `PATH`. It is
harmless in other terminals (the variable is simply unset) and is copied
verbatim from upstream.

## `Brewfile` additions

- **Brew:** add `tailscale` (alphabetical: between `starship` and `tmux`).
- **Casks:** add `1password`, `1password-cli`, `ghostty`, `tailscale-app`. Merged
  alphabetically with the existing `font-meslo-lg-nerd-font`, the cask block
  becomes: `1password`, `1password-cli`, `font-meslo-lg-nerd-font`, `ghostty`,
  `tailscale-app`.

All five entries exist in upstream's `Brewfile` at the pinned commit — **no
deviations**.

## Verification

- **Vendored verbatim files** (`ghostty/config`, `op/.gitignore`) → `diff`
  byte-identical against `hollow/dotfiles@5fd2f15`.
- **`zsh/.zshrc`** → strict line-subset: every non-blank added line exists in
  upstream's `.zshrc`. `zsh -n zsh/.zshrc` passes.
- **`Brewfile`** → every `brew`/`cask` entry exists in upstream's `Brewfile`
  (no exceptions); `brew bundle list --file=./Brewfile --all` parses.
- **Faithfulness audit:** `comm -23` of our `brew`/`cask` lines against
  upstream's is empty (no deviations).
- **Manual smoke test:** `brew bundle install` installs the casks; Ghostty opens
  and reads `~/.config/ghostty/config` (Catppuccin theme, MesloLGS font);
  `tailscale` CLI resolves and the app installs; the 1Password app and `op`
  install, `op` tab-completion works, and `~/.config/op` is `0700`.

## Acceptance criteria

- All Ring 4 brew/cask entries install via `brew bundle`, and the 1Password and
  ghostty `.zshrc` blocks load without error on a fresh shell.
- The vendored files are byte-identical to upstream at `5fd2f15`.
- The faithfulness checks above pass with **no** deviations.
- `LICENSE` and all prior-ring files remain unchanged except the `Brewfile` and
  `zsh/.zshrc` edits described here.
