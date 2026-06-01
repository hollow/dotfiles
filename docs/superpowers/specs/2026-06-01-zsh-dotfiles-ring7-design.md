# Remerge dotfiles — Ring 7 (gh config, zsh helper scripts, parallel, z-a-auto sync) design

**Date:** 2026-06-01
**Status:** Approved (design); ready for implementation planning
**Repo:** <https://github.com/remerge/dotfiles>
**Builds on:** Rings 0–6 (merged) — see
`docs/superpowers/specs/2026-06-01-zsh-dotfiles-ring6-design.md`
**Upstream pin:** `hollow/dotfiles@main` at commit `c662cda`

## Goal

Fill in upstream's `gh/` config, the missing `gh-*` / `git-*` / `pr` / `debug`
zsh helper scripts, port `parallel` (so the bulk-clone helpers work), and sync
the `z-a-auto` annex to upstream — all as a faithful **subset**: a `diff` against
upstream shows only deletions and the previously-trimmed files.

This batch is mostly **vendored scripts and config** plus a one-line annex sync.
The scripts in `zsh/` are auto-discovered (the `.zshrc` adds `ZDOTDIR` to
`PATH`/`FPATH` and `autoload`s every regular file there), so most additions need
**no `.zshrc` change**; the single `.zshrc` edit is the `parallel` section.

## Scope (decided)

In scope:

- **gh config:** `gh/config.yml` and `gh/.gitignore`. gh reads
  `${XDG_CONFIG_HOME}/gh/` directly, so there is **no `gh` `.zshrc` block**
  upstream and none here.
- **gh-\* scripts:** `gh-repo-list` (`gh` + `jq`), `gh-clone-all`,
  `gh-remove-archived` (both use `parallel` + `git-clone-clean-main`).
- **git-\* scripts (the six we're missing):** `git-checkout-main`,
  `git-clone-clean-main`, `git-dmb-configure`, `git-is-dirty`,
  `git-merged-branches`, `git-submodules-fetch-latest`. All self-contained —
  they use `git` plus helpers already in the repo (`git-checkout-latest`,
  `git-cleanup`, `git-main-branch`).
- **`pr`:** `git push && gh pr create -f && gh pr view --web`.
- **`debug`:** a `+zi-message` helper gated on `DOT_DEBUG`. **Required by the
  `z-a-auto` annex** (four call sites); without it the annex errors.
- **parallel:** `brew "parallel"`, the `parallel` `.zshrc` section
  (`PARALLEL_HOME`), and the vendored `parallel/` config files
  (`.gitignore`, `will-cite`, `runs-without-willing-to-cite`) that suppress GNU
  parallel's citation notice.
- **z-a-auto sync:** add the upstream `mise` case to
  `zsh/z-a-auto/z-a-auto.plugin.zsh`, making it byte-identical to upstream.

Out of scope:

- All other un-ported upstream `zsh/` helpers (`ah`, `ghc`, `ghm`, `assh`,
  `sshlive`, `tfa`/`tfe`/`tfp`, `:each`, `:parallel`, `aws-each-region`, etc.).
- Every other upstream tool section.

## Faithfulness principle (carried over)

Every vendored file is byte-identical to upstream at `c662cda`.
`zsh/z-a-auto/z-a-auto.plugin.zsh` becomes byte-identical to upstream (the `mise`
case was its only diff). The single `.zshrc` addition (the `parallel` section) is
a strict line-subset, inserted at its upstream-relative position. `brew
"parallel"` exists in upstream's `Brewfile`, so there are **no deviations** in
this ring.

## Dependency analysis (why this set is self-consistent)

- **git-\*:** `git-checkout-main` → `git-checkout-latest` (have);
  `git-clone-clean-main` → `git clone`, `git cleanup` (have), `git
  checkout-latest` (have); `git-dmb-configure` → `git config set`, `git
  main-branch` (have); `git-is-dirty` → git plumbing only; `git-merged-branches`
  → `git-main-branch` (have); `git-submodules-fetch-latest` → `git
  checkout-latest` (have).
- **gh-\*:** `gh-repo-list` → `gh` (Brewfile ✓) + `jq` (✓);
  `gh-clone-all` → `gh-repo-list` (this ring) + `parallel` (this ring) +
  `git-clone-clean-main` (this ring); `gh-remove-archived` → `gh-repo-list` +
  `parallel`.
- **`pr`** → `git` + `gh`.
- **`debug`** → `+zi-message` (zi builtin). The synced `mise` case →
  `mise` (Ring 6 ✓).

No script in this set depends on an un-ported helper.

## File inventory

### Modify

- `Brewfile` — add `brew "parallel"` (between `openssh` and `ripgrep`).
- `zsh/.zshrc` — add the `parallel` section (see below).
- `zsh/z-a-auto/z-a-auto.plugin.zsh` — add the `mise` case (see below).

### Create — vendored verbatim from `hollow/dotfiles@c662cda`

- `gh/config.yml`, `gh/.gitignore`
- `parallel/.gitignore`, `parallel/will-cite`, `parallel/runs-without-willing-to-cite`
- `zsh/debug`, `zsh/pr`
- `zsh/gh-repo-list`, `zsh/gh-clone-all`, `zsh/gh-remove-archived`
- `zsh/git-checkout-main`, `zsh/git-clone-clean-main`, `zsh/git-dmb-configure`,
  `zsh/git-is-dirty`, `zsh/git-merged-branches`, `zsh/git-submodules-fetch-latest`

## Path mapping

The repo lives at `~/.config`, so vendored directories map directly:

- `gh/config.yml` → `~/.config/gh/config.yml` (gh's default XDG config path).
  `gh/.gitignore` ignores `hosts.yml` (the file gh writes auth state into).
- `parallel/*` → `~/.config/parallel/*`. `PARALLEL_HOME` points there; the
  `will-cite` / `runs-without-willing-to-cite` files silence the citation
  notice. `parallel/.gitignore` ignores `tmp/`.
- `zsh/*` scripts → `~/.config/zsh/*`; already on `PATH`/`FPATH` via the existing
  `.zshrc` bootstrap, so `git foo` resolves `git-foo`, and bare `gh-repo-list`,
  `pr`, etc. resolve as commands.

## `zsh/.zshrc` addition — parallel

Inserted between the existing `mise` block (after
`zi auto has"mise" for jdx/mise`) and the existing `# rsync` block, matching
upstream's order (`mise → … → parallel → … → rsync`):

```zsh
# parallel: run commands in parallel
# https://www.gnu.org/software/parallel/
export PARALLEL_HOME="${XDG_CONFIG_HOME}/parallel"
mkdir -p ${PARALLEL_HOME}
```

## `zsh/z-a-auto` sync

Add the `mise` case to the extension-handler `case` statement, making the file
byte-identical to upstream:

```zsh
        (mise)
            mise use -g ${___ehid}
            ;;
```

This is the handler that lets `zi auto` install a tool through `mise` (it pairs
with Ring 6's mise section). It was the only line by which our vendored annex
lagged upstream.

## `Brewfile` addition

- **Brew:** add `parallel` (alphabetical: between `openssh` and `ripgrep`).
- No cask changes.

`parallel` exists in upstream's `Brewfile` at `c662cda` — **no deviation**.

## Verification

- **Vendored files** (all `gh/*`, `parallel/*`, and the eleven `zsh/*` scripts)
  → `diff` byte-identical against `hollow/dotfiles@c662cda`.
- **`zsh/z-a-auto/z-a-auto.plugin.zsh`** → `diff` byte-identical against upstream
  after the `mise`-case addition.
- **`zsh/.zshrc`** → the added `parallel` lines are byte-identical to upstream and
  inserted between the mise and rsync blocks; `zsh -n zsh/.zshrc` passes.
- **Every new `zsh/*` script** → `zsh -n` parses cleanly.
- **`Brewfile`** → `parallel` exists upstream; `brew bundle list
  --file=./Brewfile --all` parses; `comm -23` of our `brew`/`cask` lines against
  upstream's is empty (no deviations).
- **Manual smoke test:** `brew bundle install` installs `parallel`; on a fresh
  shell `gh-repo-list`, `pr`, `git is-dirty`, `git merged-branches`,
  `git checkout-main` resolve as commands; `DOT_DEBUG=1 debug hi` emits a
  message; `parallel` runs without a citation notice; `zi auto has"mise" …`
  loads without error.

## Acceptance criteria

- All eleven `zsh/*` scripts, both `gh/*` files, and all three `parallel/*` files
  are vendored byte-identical to upstream; each new script passes `zsh -n`.
- `zsh/z-a-auto/z-a-auto.plugin.zsh` is byte-identical to upstream.
- `brew "parallel"` is added and the `parallel` `.zshrc` section loads without
  error; `zsh -n zsh/.zshrc` passes.
- The faithfulness checks pass with **no Brewfile deviations**.
- `LICENSE` and all prior-ring files remain unchanged except the `Brewfile`,
  `zsh/.zshrc`, and `zsh/z-a-auto/z-a-auto.plugin.zsh` edits described here.
