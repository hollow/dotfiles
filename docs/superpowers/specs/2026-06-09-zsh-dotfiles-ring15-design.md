# Remerge dotfiles — Ring 15 (atuin + direnv) design

**Date:** 2026-06-09
**Status:** Approved (design); ready for implementation planning
**Repo:** <https://github.com/remerge/dotfiles>
**Builds on:** Rings 0–14 (merged) — see
`docs/superpowers/specs/2026-06-08-zsh-dotfiles-ring14-design.md`
**Upstream pin:** `hollow/dotfiles@main` at commit `981e133` (advanced from
Ring 14's `c8a74a6`)

## Goal

Port two previously-deferred tools from upstream — **atuin** (magical shell
history) and **direnv** (per-directory environment) — into the fork. Both were
dropped when the fork's skeleton was carved from upstream and never carried
since (atuin was explicitly called out as deferred in Ring 2); this ring adopts
them. Each is a small, self-contained additive block
with no cross-dependency on the other and no atomicity constraint, so the whole
ring lands as one config commit.

Every ported line is **byte-identical to `981e133`**. This ring has **no
line-level deviations** inside its slice; the only deviations are the standard
no-README-change and the (non-)change to `starship.toml`, which already carries
direnv (see Deviations).

The atuin/direnv slices are unchanged across the `c8a74a6..981e133` window — the
four upstream commits in that window (`957fc11` gpm/gpv aliases, `e04840b` zup
zi-prune, `8310c1d` remove dog + brew bundle dump, `981e133` vscode settings
alignment) touch neither tool. Pinning to HEAD advances the documented baseline
without pulling in those unrelated changes, which remain for a future sync.

## Scope (decided)

Tight: **atuin + direnv only**, full footprint for each. "Full footprint" was
confirmed during design: for atuin that includes its config directory; for
direnv it includes the trailing `.envrc` startup hook.

### A. `Brewfile`

Two added lines, byte-identical to upstream, each at upstream's relative
position:

- `brew "atuin"` — after `brew "atool"`, before `brew "bash"` (upstream has
  `brew "awscli"` between atuin and bash; the fork omits awscli, so atuin sits
  directly before bash here).
- `brew "direnv"` — after `brew "curl"`, before `brew "docker"`.

Both lines are byte-identical to upstream's, so the fork's `brew`/`cask` lines
remain a strict subset of upstream `981e133`; this ring adds no new fork-only
Brewfile deviation.

### B. `.zshrc` — new `# region atuin` block

Insert between the **1password** region (`# endregion`) and the **bat** region
(`# region bat:`) — upstream's relative position. Upstream places `android`,
`ansible`, `ansible/ara`, `aws`, and `aws/boto` between 1password and bat; the
fork carries none of them, so atuin lands directly before the bat region.
Byte-identical to upstream `981e133`:

```zsh
# region atuin: magical shell history with optional sync
# https://github.com/atuinsh/atuin
:atuin-load() {
	alias a="atuin"
}

:atuin-eval() {
	atuin init zsh --disable-up-arrow
}

zi auto has"atuin" wait1 for atuin
# endregion
```

### C. `.zshrc` — new `# region direnv` block

Insert between the **dircolors** region (`# endregion`) and the **docker**
region (`# region docker:`) — upstream's relative position (`dircolors → direnv
→ docker`). Byte-identical to upstream `981e133`:

```zsh
# region direnv: change environment based on the current directory
# https://github.com/direnv/direnv
:direnv-load() {
	alias da="direnv allow"
}

:direnv-eval() {
	direnv hook zsh
}

zi auto has"direnv" for direnv/direnv
# endregion
```

### D. `.zshrc` — trailing `.envrc` startup hook

Append direnv's startup hook after the final `add path "${HOME}/.local/bin"`
line (the current last line of the fork's `.zshrc`), preceded by one blank line,
matching upstream's file tail. Byte-identical to upstream `981e133`:

```zsh
# Load .envrc after shell initialization if present
if [[ -e .envrc ]]; then
	pushd "${HOME}" &>/dev/null && popd
fi
```

This is direnv's bootstrap for the shell's launch directory: `direnv hook zsh`
(from `:direnv-eval`) installs a `chpwd` hook that evaluates a directory's
`.envrc`, but that hook only fires on a directory *change*; the `pushd $HOME &&
popd` round-trip forces one `chpwd` so an `.envrc` already present in the
startup directory is evaluated. It ships with direnv and is inert without it.
Ring 12's spec already classified it as "the trailing `.envrc` (direnv) hook".

### E. `atuin/` — new config directory

Create the atuin config directory, both files byte-identical to upstream
`981e133`:

- `atuin/config.toml` — the upstream atuin config (mostly the commented-out
  reference template, with a handful of active settings: `enter_accept = true`,
  `[sync] records = true`, `[logs] dir = "~/.local/state/atuin/logs"`, and
  `[theme] name = "catppuccin-mocha-blue"`).
- `atuin/themes/catppuccin-mocha-blue.toml` — the Catppuccin Mocha Blue theme
  referenced by `config.toml`.

The fork's `.zshrc` `init` region already exports `XDG_CONFIG_HOME`, so atuin
reads `${XDG_CONFIG_HOME}/atuin/config.toml` once the `atuin/` dir is in place
at `~/.config/atuin` (see Path mapping). No `:atuin-init` linking helper exists
upstream
or in the fork — atuin resolves its config dir from `XDG_CONFIG_HOME` directly.

## Deviations (documented)

1. **No README change.** Consistent with every prior tool ring — the fork's
   README documents no per-tool sections.
2. **`starship.toml` unchanged (not a port omission).** Upstream renders a
   direnv module in the prompt; the fork's `starship.toml` already carries a
   byte-identical `[direnv]` block (and the `$direnv` slot in the prompt format)
   from the earlier wholesale starship port. There is nothing to add for direnv
   in `starship.toml`, so this ring does not touch it.

There are **no line-level deviations** within the ported atuin/direnv slice;
every ported line is byte-identical to upstream `981e133`.

## Dependency analysis

- **`atuin` (new brew).** `zi auto has"atuin" wait1 for atuin` is guarded by
  `has"atuin"`, so it no-ops until `brew "atuin"` is installed — safe to land in
  one commit with the Brewfile line. `:atuin-load` defines the `a` alias;
  `:atuin-eval` runs `atuin init zsh --disable-up-arrow` (the `z-a-eval` annex
  caches its output), wiring atuin's zsh integration. atuin reads its config
  from `${XDG_CONFIG_HOME}/atuin` once the `atuin/` dir is linked.
- **`direnv` (new brew).** Both `zi auto has"direnv" for direnv/direnv` and the
  trailing `.envrc` hook depend on the `direnv` binary; `direnv hook zsh` (from
  `:direnv-eval`) is what installs the `chpwd` hook the `.envrc` block relies on.
  The `has"direnv"` guard means the load line no-ops until `brew "direnv"` is
  installed. The `.envrc` block itself is unguarded but inert without direnv's
  hook (it just round-trips the directory stack).
- **`z-a-auto` / `z-a-eval` annexes and helpers all predate this ring.** `add`,
  `has`, the `zi auto` convention, and the `:tool-load`/`:tool-eval` hook
  naming are all already established; this ring adds no new helper.
- **`XDG_CONFIG_HOME` / `XDG_DATA_HOME` / `XDG_STATE_HOME`** are exported by the
  existing `init` region; atuin's `[logs] dir = "~/.local/state/atuin/logs"`
  (XDG state) and its default data dir are consistent with the fork's existing
  XDG layout.

## File inventory

### Create
- `docs/superpowers/specs/2026-06-09-zsh-dotfiles-ring15-design.md` (this file).
- `docs/superpowers/plans/2026-06-09-zsh-dotfiles-ring15.md` (+ `.tasks.json`).
- `atuin/config.toml` (byte-identical to upstream `981e133`).
- `atuin/themes/catppuccin-mocha-blue.toml` (byte-identical to upstream
  `981e133`).

### Modify
- `Brewfile` — add `brew "atuin"` and `brew "direnv"` (§A).
- `zsh/.zshrc` — §B (atuin region), §C (direnv region), §D (trailing `.envrc`
  hook).

## Path mapping

- The `.zshrc` edits live in `~/.config/zsh/.zshrc` (already linked).
- `atuin/` lives at the repo root, which is checked out as `~/.config` in
  production (the same place every other tool's config dir lives — `bat/`,
  `git/`, etc.), so `${XDG_CONFIG_HOME}/atuin/config.toml` resolves to the
  committed file.
- `brew "atuin"` and `brew "direnv"` → installed by `brew bundle`.

## Verification

- **`Brewfile`:** `brew "atuin"` present between `atool` and `bash`, and
  `brew "direnv"` present between `curl` and `docker`, each byte-identical to
  upstream's line; the fork's `brew`/`cask` lines remain a strict subset of
  upstream `981e133` (`comm -13 <(git show 981e133:Brewfile | sort) <(sort
  Brewfile)` lists no new fork-only line from this ring); `brew bundle list
  --file=./Brewfile --all` parses.
- **`zsh/.zshrc` byte-identity:** each ported region/block diffs clean against
  `git show 981e133:zsh/.zshrc` —
  - the `# region atuin` block (§B) equals upstream's and sits between the
    1password and bat regions,
  - the `# region direnv` block (§C) equals upstream's and sits between the
    dircolors and docker regions,
  - the trailing `.envrc` hook (§D) equals upstream's file tail and follows the
    final `add path` line.
  Concretely: `comm -13 <(git show 981e133:zsh/.zshrc | sort -u) <(sort -u
  zsh/.zshrc)` lists only fork-only lines from *other* (pre-existing) tools — no
  fork-only line originates in the atuin/direnv slice.
- **`atuin/` byte-identity:** `diff <(git show 981e133:atuin/config.toml)
  atuin/config.toml` and `diff <(git show
  981e133:atuin/themes/catppuccin-mocha-blue.toml)
  atuin/themes/catppuccin-mocha-blue.toml` are both empty.
- **Syntax:** `zsh -n zsh/.zshrc` passes.
- **Region order:** the new regions appear in upstream's relative order
  (`… 1password → atuin → bat …` and `… dircolors → direnv → docker …`).
- **Fresh-shell smoke test (best-effort, after `brew bundle install`):** in a
  new interactive shell, `atuin --version` and `direnv version` work; `a` aliases
  to `atuin`; `da` aliases to `direnv allow`; `cd` into a directory with an
  `.envrc` prompts direnv to load it. Note the live `~/.config` on this machine
  tracks `hollow@main`, not the fork branch, so a full interactive smoke test of
  the branch is not meaningful here — same caveat as recent rings; byte-identity
  to the already-shipped upstream commit is the primary guarantee.

## Acceptance criteria

- `Brewfile` contains `brew "atuin"` (between `atool` and `bash`) and
  `brew "direnv"` (between `curl` and `docker`), each byte-identical to upstream;
  `brew bundle list --all` parses; this ring adds no new fork-only Brewfile line.
- `zsh/.zshrc`: the `# region atuin` block is present between the 1password and
  bat regions; the `# region direnv` block is present between the dircolors and
  docker regions; the trailing `.envrc` hook follows the final `add path` line.
- `atuin/config.toml` and `atuin/themes/catppuccin-mocha-blue.toml` exist and are
  byte-identical to upstream `981e133`.
- Every ported atuin/direnv line is byte-identical to upstream `981e133`; the
  only deviations are no README change (Deviation 1) and the untouched
  already-complete `starship.toml` (Deviation 2).
- `zsh -n zsh/.zshrc` passes.
- `LICENSE` and all prior-ring files are unchanged except the `Brewfile`,
  `zsh/.zshrc`, and new `atuin/` files described here.
