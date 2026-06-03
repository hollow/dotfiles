# Remerge dotfiles — Ring 8 (gcloud, opentofu, shell helpers, ssh helpers, a100a5a/cef10b6 sync) design

**Date:** 2026-06-02
**Status:** Approved (design); ready for implementation planning
**Repo:** <https://github.com/remerge/dotfiles>
**Builds on:** Rings 0–7 (merged) — see
`docs/superpowers/specs/2026-06-01-zsh-dotfiles-ring7-design.md`
**Upstream pin:** `hollow/dotfiles@main` at commit `cef10b6`

## Goal

Port a batch of upstream CLI tooling and shell helpers as a faithful **subset**,
and sync our existing vendored files up to the new pin: a `diff` against upstream
shows only deletions and the previously-trimmed files.

The batch covers two tool sections (**gcloud**, **opentofu**), the **ssh rescue
helpers** (`ssu`, `sshlive`) deferred in Ring 5, a set of small **shell helper
scripts**, three new **brews** + one **cask**, and an upstream **sync** (the
`git/config` git-lfs filter).

## Scope (decided)

### A. gcloud
- `cask "gcloud-cli"`.
- gcloud `.zshrc` section: `:gcloud-update`, `:gcloud-load`
  (`CLOUDSDK_HOME`, PATH, completion, disable usage reporting),
  `zi auto has"gcloud" wait1 for gcloud`.
- `gcloud/.gitignore` (`*` / `!.gitignore`).
- **`zup()` wiring:** add `:tmux-update` and `:gcloud-update` calls.

### B. opentofu (+ tfa, tfp)
- opentofu `.zshrc` section: `TF_PLUGIN_CACHE_DIR` export + mkdir,
  `alias tf="tofu"`, `alias tf-each`/`tf-parallel`, `:opentofu-load`,
  `zi auto with"mise" wait1 for opentofu`.
- `mise/config.toml`: add `opentofu = "latest"` to `[tools]`.
- `tfa`, `tfp` scripts (mode 755).

### C. Shell helper scripts
- `:each`, `:parallel` (mode 644 — autoloaded functions).
- `cdl`, `cdu`, `grc`, `sl` (mode 755).
- `ghc`, `ghm` (mode 755) + `brew "git-delete-merged-branches"`.

### D. ssh rescue helpers (deferred from Ring 5)
- `ssu`, `sshlive` (mode 755).

### E. Brews / sync
- `brew "dog"` (DNS client; brew-only, no `.zshrc` section).
- `brew "git-lfs"`.
- **`git/config`:** add the upstream `[filter "lfs"]` block (sync).

Out of scope: every other un-ported upstream helper (`ah`, `ara-*`, `assh`,
`aws-each-region`, `find-terraform-providers-modules`, `tfe`, `pw`, `IP`,
`netping`, `autocall`, `mknative`, …) and tool section.

## Faithfulness principle (carried over)

Every vendored file is byte-identical to upstream at `cef10b6`, with matching
tracked git mode. `zsh/.zshrc` remains a strict line-subset; the two added
sections (gcloud, opentofu) and the `zup()` additions are byte-identical upstream
lines inserted at their upstream-relative positions. `git/config` becomes
byte-identical to upstream. `mise/config.toml` stays a subset of upstream's
`[tools]` (now `[tools]` + `opentofu = "latest"`; the other five tools land in
future rings — the only file-level deviation).

All four Brewfile entries — `gcloud-cli`, `git-delete-merged-branches`,
`git-lfs`, `dog` — exist in upstream's `Brewfile` at `cef10b6`, so there are **no
Brewfile deviations**.

## Dependency analysis

- **gcloud:** cask installs `gcloud`; section sets `CLOUDSDK_HOME`/PATH/completion;
  `:gcloud-update` is called from `zup()`.
- **opentofu:** `zi auto with"mise" wait1 for opentofu` installs `tofu` via mise
  (the z-a-auto `mise` case → `mise use -g opentofu`; the `[tools]` entry keeps
  that from mutating the tracked config). `tfa`/`tfp` + the `tf*` aliases call
  `tofu`; `tf-each`/`tf-parallel` use `:each`/`:parallel`.
- **`:each`** is pure zsh. **`:parallel`** uses the `parallel` binary (Ring 7) and
  sources `${ZDOTDIR}/.zshrc`.
- **`cdl`** → `colordiff` (Brewfile, present). **`cdu`** → `cdl`.
- **`ghc`** → `git-checkout-latest` (have) + `git dmb` (from
  `git-delete-merged-branches`). **`ghm`** → `gh` (have) + `ghc`.
- **`grc`** → `git-main-branch` (have). **`sl`** → `sort`/`less`.
- **`ssu`** → `sshlive`. **`sshlive`** → `ssh`.
- The `git/config` lfs filter calls `git-lfs` (now installed via `brew "git-lfs"`).

No script in this batch depends on an un-ported helper.

## File inventory

### Modify
- `Brewfile` — add `brew "dog"`, `brew "git-delete-merged-branches"`,
  `brew "git-lfs"`, `cask "gcloud-cli"`.
- `zsh/.zshrc` — add gcloud + opentofu sections; wire `:tmux-update` +
  `:gcloud-update` into `zup()`.
- `mise/config.toml` — add `opentofu = "latest"`.
- `git/config` — add the `[filter "lfs"]` block (→ byte-identical to upstream).

### Create — vendored verbatim from `hollow/dotfiles@cef10b6`
- `gcloud/.gitignore`
- `zsh/:each`, `zsh/:parallel` (mode 644)
- `zsh/cdl`, `zsh/cdu`, `zsh/ghc`, `zsh/ghm`, `zsh/grc`, `zsh/sl`,
  `zsh/tfa`, `zsh/tfp`, `zsh/ssu`, `zsh/sshlive` (mode 755)

## Path mapping

- `gcloud/.gitignore` → `~/.config/gcloud/.gitignore` (keeps the gcloud config
  dir present while ignoring its runtime/credential contents).
- `mise/config.toml` → `~/.config/mise/config.toml` (now declares `opentofu`).
- `zsh/*` scripts → `~/.config/zsh/*`; already on `PATH`/`FPATH` via the existing
  bootstrap, so `ssu`, `cdl`, `ghc`, `tfa`, etc. resolve as commands and `:each`/
  `:parallel` resolve as autoloaded functions.
- `git/config` → the shared git config `[include]`d by the repo.

## `zsh/.zshrc` additions

Inserted byte-identical, preserving upstream's relative order.

**gcloud** — between the existing `eza` block (after `zi auto has"eza" wait for
eza`) and the `# ghostty` block:

```zsh
# gcloud: Google Cloud SDK
# https://cloud.google.com/sdk
:gcloud-update() {
    gcloud components update || :
}

:gcloud-load() {
    if has brew; then
        export CLOUDSDK_HOME="/opt/homebrew/share/google-cloud-sdk"
    else
        export CLOUDSDK_HOME="/usr/lib64/google-cloud-sdk"
    fi

    if has "${CLOUDSDK_HOME}"; then
        add path "${CLOUDSDK_HOME}/bin"
        source "${CLOUDSDK_HOME}/completion.zsh.inc"
        export CLOUDSDK_CORE_DISABLE_USAGE_REPORTING=true
    fi
}

zi auto has"gcloud" wait1 for gcloud
```

**opentofu** — between the existing `ssh` block (after its closing `fi`) and the
`# tmux` block:

```zsh
# opentofu: open-source terraform fork, installed via mise
# https://github.com/opentofu/opentofu
export TF_PLUGIN_CACHE_DIR="${XDG_CACHE_HOME}/opentofu/plugins"
mkdir -p "${TF_PLUGIN_CACHE_DIR}"

alias tf="tofu"
alias tf-each=':each */terraform.mk(:h) do'
alias tf-parallel=':parallel */terraform.mk(:h) do'

:opentofu-load() {
    complete -o nospace -C tofu tofu
}

zi auto with"mise" wait1 for opentofu
```

**`zup()`** — insert `:tmux-update && \` and `:gcloud-update && \` between the
existing `:brew-update && \` and `zi self-update && \` lines (a faithful subset of
upstream's, minus the un-ported `:uv-update`):

```zsh
zup() {
    local oldpwd="${PWD}"
    :brew-update && \
    :tmux-update && \
    :gcloud-update && \
    zi self-update && \
    zi update --all
    cd "${oldpwd}"
}
```

## `mise/config.toml`

```toml
[tools]
opentofu = "latest"
```

(Upstream's, with the other five `[tools]` entries removed — still the same
documented subset deviation, now carrying the one tool this ring installs.)

## `git/config` sync

Add the upstream `[filter "lfs"]` block after `[rerere]` and before `[include]`,
making `git/config` byte-identical to upstream at `cef10b6`:

```gitconfig
[filter "lfs"]
	clean = git-lfs clean -- %f
	smudge = git-lfs smudge -- %f
	process = git-lfs filter-process
	required = true
```

## `Brewfile` additions

- **Brews:** `dog` (between `curl` and `duf`), `git-delete-merged-branches`
  (between `git` and `glow`), `git-lfs` (between `git-delete-merged-branches` and
  `glow`).
- **Cask:** `gcloud-cli` (between `font-meslo-lg-nerd-font` and `ghostty`).

All exist in upstream's `Brewfile` at `cef10b6` — **no deviations**.

## Verification

- **Vendored files** (`gcloud/.gitignore` and the twelve `zsh/*` scripts) →
  mode+content identical to upstream via `git ls-files -s` (the two `:`-prefixed
  scripts `100644`, the rest `100755`).
- **`zsh/.zshrc`** → the gcloud and opentofu sections and the two new `zup()`
  lines are byte-identical to upstream; every non-blank line in our `.zshrc`
  exists in upstream's; `zsh -n zsh/.zshrc` passes; each new script passes
  `zsh -n`.
- **`git/config`** → `diff` byte-identical to upstream at `cef10b6`.
- **`mise/config.toml`** → equals upstream's with the non-`opentofu` `[tools]`
  entries removed.
- **`Brewfile`** → `dog`, `git-delete-merged-branches`, `git-lfs`, `gcloud-cli`
  all exist upstream; `brew bundle list --file=./Brewfile --all` parses;
  `comm -23` of our `brew`/`cask` lines against upstream's is empty.
- **Manual smoke test:** `brew bundle install` installs the brews/cask; on a fresh
  shell the gcloud and opentofu sections load without error; `gcloud`, `tofu`,
  `dog`, `git-lfs` resolve; `git is-dirty`/`ghc`/`ghm`/`grc`/`sl`/`cdl`/`cdu`/
  `ssu`/`tfa`/`tfp` resolve as commands; `tf-each`/`tf-parallel` expand;
  `zup` calls the gcloud/tmux updaters without error.

## Acceptance criteria

- All twelve `zsh/*` scripts and `gcloud/.gitignore` are vendored byte-identical
  to upstream with correct modes; each script passes `zsh -n`.
- The gcloud + opentofu `.zshrc` sections and the `zup()` additions are
  byte-identical to upstream; `zsh -n zsh/.zshrc` passes.
- `git/config` is byte-identical to upstream; `mise/config.toml` equals upstream
  minus the non-`opentofu` tools.
- `dog`, `git-delete-merged-branches`, `git-lfs`, `gcloud-cli` install via
  `brew bundle`; the faithfulness checks pass with **no Brewfile deviations**.
- `LICENSE` and all prior-ring files remain unchanged except the `Brewfile`,
  `zsh/.zshrc`, `mise/config.toml`, and `git/config` edits described here.
