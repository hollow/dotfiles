# Remerge dotfiles — Ring 13 (go + node + ruby) design

**Date:** 2026-06-08
**Status:** Approved (design); ready for implementation planning
**Repo:** <https://github.com/remerge/dotfiles>
**Builds on:** Rings 0–12 (merged) plus the interim upstream syncs (hollow #4
reorder/header-normalization, XDG, git, init/load consistency) — see
`docs/superpowers/specs/2026-06-06-zsh-dotfiles-ring12-design.md`
**Upstream pin:** `hollow/dotfiles@main` at commit `93b9788` (the merge of
hollow PR #8 "Group language blocks in zshrc top section"; advanced from Ring
12's `236cfef`)

## Goal

Port the **programming-language tooling slice** — `go`, `node`, `ruby` — from
upstream, bringing the fork's language configuration to upstream's
**post-PR-#8** state.

Upstream PR #8 (<https://github.com/hollow/dotfiles/pull/8>) is, in the upstream
tree, a pure relocation: it groups the already-present `go`, `node`, and `ruby`
blocks into the foundational top section of `zsh/.zshrc` (right after
`python`/`uv`/`argcomplete`, ahead of the `1password` alphabetical app list) and
rewrites `ruby`'s Homebrew detection to mirror `python`'s.

The **fork is behind** that state:

- it has **no `go` block** and **no `ruby` block** at all;
- it has the **`node` block**, but sitting in its *old* alphabetical slot
  (between `ncdu` and `opentofu`), not in the top language group;
- it carries **none** of the three in the `Brewfile`.

So porting PR #8 into the fork means **adding** the `go` and `ruby` blocks,
**relocating** the existing `node` block into the top language group, and
syncing the `Brewfile` supporting lines — landing on a top language section
byte-identical to upstream `93b9788`.

## Scope (decided)

Tight: **the `go`, `node`, and `ruby` blocks and their `Brewfile` lines only.**

Every ported line is **byte-identical to `93b9788`**. The three `.zshrc` blocks
are taken verbatim from upstream; the only deviations are at the `Brewfile`
ordering / install-policy level (see Deviations), not inside any ported block.

### A. `zsh/.zshrc` — build the top language group

In upstream `93b9788` the top section runs:
`python` → `uv` → `argcomplete` → **`go`** → **`node`** → **`ruby`** →
`1password`. The fork already has `python`/`uv`/`argcomplete` and `1password`
byte-identical and adjacent (the `argcomplete` block ends with
`zi auto with"uv" for argcomplete`, immediately followed by the `# 1password`
block). This ring inserts the three language blocks between them, in order.

Insert, verbatim from upstream (tabs as in the file):

```zsh
# go: programming language
# https://www.golang.org
:go-init() {
	export GOPATH="${XDG_CACHE_HOME}/go"
	add path "${GOPATH}/bin"
}

zi auto has"go" for go

# node/npm: JavaScript runtime
# https://nodejs.org
:node-init() {
	export NODE_REPL_HISTORY="${XDG_DATA_HOME}/node/repl_history"
	mkdirp "${XDG_DATA_HOME}/node"
	link npm/npmrc .npmrc
}

zi auto has"node" wait1 for node

# ruby: programming language
# https://www.ruby-lang.org
:ruby-init() {
	export GEM_HOME="${XDG_CACHE_HOME}"/gem
	export GEM_SPEC_CACHE="${XDG_CACHE_HOME}"/gem
	export BUNDLE_USER_CONFIG="${XDG_CONFIG_HOME}"/bundle
	export BUNDLE_USER_CACHE="${XDG_CACHE_HOME}"/bundle
	export BUNDLE_USER_PLUGIN="${XDG_DATA_HOME}"/bundle

	# expose brew's ruby on PATH (macOS/brew only)
	if has brew; then
		add path "${HOMEBREW_PREFIX}/opt/ruby/bin"
	fi
}

zi auto has"ruby" for ruby
```

The **`node` block here is a relocation, not a duplicate**: the fork's existing
`node` block (currently between the `ncdu` and `opentofu` blocks) is already
byte-identical to the one above and must be **removed** from that old slot. After
removal the `ncdu` block is immediately followed by the `opentofu` block (one
blank line between), matching the fork's curated alphabetical app list with
`node` no longer in it. (Upstream's old `node` slot was between `ncdu` and
`nomad`; the fork does not carry `nomad`, so its neighbour is `opentofu` — a
pre-existing fork omission, not introduced here.)

The `go` and `ruby` blocks are **new** to the fork.

### B. `Brewfile` — supporting entries

Two added lines, byte-identical to upstream, placed in the fork's own
alphabetical order:

- `brew "go"` — between `brew "gnupg"` and `brew "graphviz"`.
- `brew "node"` — between `brew "nmap"` and `brew "ocrmypdf"`.

No `brew "ruby"` line is added (see Deviation 2): the `ruby` block exposes
`${HOMEBREW_PREFIX}/opt/ruby/bin` only `if has brew` and activates only under
`has"ruby"`, so on a fork machine it stays opportunistic — it targets a
brew-installed ruby if one is present, otherwise falls back to system ruby —
exactly as upstream behaves (upstream also carries no `brew "ruby"`).

### C. Supporting files — already in place, no change

- **`npm/npmrc`** — referenced by the `node` block's `link npm/npmrc .npmrc`.
  Already present in the fork and **byte-identical** to upstream `93b9788`. No
  change.
- **`mise/config.toml`** — already byte-identical to upstream. The empty
  `[tools]` table means go/node/ruby are not pinned via mise; they come from
  brew (`go`, `node`) or are opportunistic (`ruby`). No change.
- Upstream `93b9788` carries **no** `go`, `ruby`, `gem`, or `bundle` config
  directory (only `mise`, `npm`, `pip`, `python` exist at the top level, same as
  the fork). The `ruby` block's `GEM_*`/`BUNDLE_*` exports point at XDG cache /
  config / data paths that are created on demand; no committed config files back
  them. Nothing else to add.

## Deviations (documented)

1. **No README change.** Consistent with every prior tool ring — the fork's
   README documents no per-tool sections.
2. **No `brew "ruby"`.** Matches upstream `93b9788`, which also omits it. The
   `ruby` block is therefore opportunistic on the fork (brew ruby if installed,
   else system ruby), not backed by an installed brew formula. This is the
   default chosen for this ring; a future ring may add `brew "ruby"` if Remerge
   wants a guaranteed modern ruby.
3. **`Brewfile` `node` placement is alphabetical in the fork**, not upstream's
   literal position. Upstream places `brew "node"` non-alphabetically (right
   after `brew "make"`, before `brew "mermaid-cli"`); the fork's `Brewfile` is
   otherwise cleanly alphabetical, so `node` is inserted in its sorted slot
   (after `nmap`, before `ocrmypdf`) to keep the fork's `Brewfile` internally
   consistent. The ported **line** `brew "node"` is byte-identical either way;
   only its position differs. `brew "go"`'s alphabetical slot (gnupg → graphviz)
   coincides with upstream's relative position, so it carries no ordering
   deviation.

There are **no line-level deviations** inside the three ported `.zshrc` blocks;
every line of the `go`, `node`, and `ruby` blocks is byte-identical to upstream
`93b9788`.

## Dependency analysis

- **`has` guards make all three blocks safe to land together.** Each block loads
  under a `has` guard — `zi auto has"go" for go`, `zi auto has"node" wait1 for
  node`, `zi auto has"ruby" for ruby` — so a block is inert until its binary is
  on `PATH`. Adding `brew "go"`/`brew "node"` and the blocks in one commit is
  safe: the blocks no-op until `brew bundle` installs the tools, and `ruby`
  no-ops unless a ruby is present.
- **Helpers all predate this ring.** `add`, `has`, `link`, and `mkdirp` are
  defined early in `.zshrc` (the `mkdirp` helper landed in the recent init/load
  consistency sync); the `z-a-auto` annex backing `zi auto … for <tool>` is
  already loaded. The `node` block's `mkdirp "${XDG_DATA_HOME}/node"` and
  `link npm/npmrc .npmrc` use only existing helpers and the existing `npm/npmrc`.
- **`HOMEBREW_PREFIX` is set** by the early `brew shellenv` block; on the
  Apple-Silicon-only target it is `/opt/homebrew`, so the `ruby` block's
  `${HOMEBREW_PREFIX}/opt/ruby/bin` resolves correctly (no Intel `/usr/local`
  fallback — consistent with the fork's Apple-Silicon-only policy).
- **XDG variables** (`XDG_CACHE_HOME`, `XDG_CONFIG_HOME`, `XDG_DATA_HOME`) are
  all exported earlier in `.zshrc` and are used by the `go`, `node`, and `ruby`
  exports exactly as upstream uses them.
- **The relocation is load-order-neutral.** Moving the `node` block from the
  alphabetical app list into the top language group does not change when it
  loads relative to anything that depends on it — it carries the same `wait1`
  and `has"node"` guard, and nothing else references the `node`-set variables at
  load time.

## File inventory

### Create

- `docs/superpowers/specs/2026-06-08-zsh-dotfiles-ring13-design.md` (this file).
- `docs/superpowers/plans/2026-06-08-zsh-dotfiles-ring13.md` (+ `.tasks.json`).

### Modify

- `zsh/.zshrc` — §A: insert `go`/`node`/`ruby` blocks into the top language
  group (after `argcomplete`, before `1password`); remove the old `node` block
  from its alphabetical slot.
- `Brewfile` — §B: add `brew "go"` (gnupg → graphviz) and `brew "node"` (nmap →
  ocrmypdf).

## Path mapping

- The `.zshrc` edits live in `~/.config/zsh/.zshrc` (already linked).
- `brew "go"` / `brew "node"` → installed by `brew bundle`.
- `npm/npmrc` → already symlinked to `~/.npmrc` by the `node` block's
  `link npm/npmrc .npmrc` (unchanged).

## Verification

- **`zsh/.zshrc` byte-identity (top group):** the span from
  `zi auto with"uv" for argcomplete` through `zi auto has"op" wait1 for
  1password-cli` diffs clean against the same span of
  `git show 93b9788:zsh/.zshrc` — i.e. the inserted `go`/`node`/`ruby` blocks
  are byte-identical to upstream and in the order `go → node → ruby`.
- **No duplicate / no orphan `node` block:** `grep -c ':node-init' zsh/.zshrc`
  returns exactly `1`; the old slot (between the `ncdu` and `opentofu` blocks) no
  longer contains a `node` block, so `ncdu` is immediately followed by
  `opentofu`.
- **Per-block diff:** the `go`, `node`, and `ruby` blocks each equal upstream's;
  in particular the `ruby` block uses the post-PR-#8 `if has brew; then add path
  "${HOMEBREW_PREFIX}/opt/ruby/bin"; fi` form and carries **no** `opt/ruby@*`
  glob and **no** `RUBYHOME` export.
- **`Brewfile`:** `brew "go"` present between `gnupg` and `graphviz`; `brew
  "node"` present between `nmap` and `ocrmypdf`; both lines byte-identical to
  upstream; **no** `brew "ruby"` line. `brew bundle list --file=./Brewfile --all`
  parses.
- **Syntax:** `zsh -n zsh/.zshrc` passes.
- **Fresh-shell smoke test (best-effort, after `brew bundle install`):** in a new
  interactive shell, `go version` and `node --version` work and `GOPATH` /
  `NODE_REPL_HISTORY` point under the XDG dirs. Note the live `~/.config` on this
  machine tracks `hollow@main`, not the fork branch, so a full interactive smoke
  test of the branch is not meaningful here — same caveat as recent rings;
  byte-identity to the already-shipped upstream commit is the primary guarantee.

## Acceptance criteria

- `zsh/.zshrc`: the top language group reads `python → uv → argcomplete → go →
  node → ruby → 1password`, with the `go`/`node`/`ruby` blocks byte-identical to
  upstream `93b9788`; the old `node` block is removed from the alphabetical app
  list (`:node-init` appears exactly once); the `ruby` block uses the
  `has brew` / `${HOMEBREW_PREFIX}/opt/ruby/bin` detection (no `opt/ruby@*`, no
  `RUBYHOME`).
- `Brewfile`: contains `brew "go"` (between `gnupg` and `graphviz`) and `brew
  "node"` (between `nmap` and `ocrmypdf`), each byte-identical to upstream; no
  `brew "ruby"`; `brew bundle list --all` parses.
- `npm/npmrc` and `mise/config.toml` are unchanged (already byte-identical to
  upstream).
- `zsh -n zsh/.zshrc` passes.
- The only deviations are: no README change (Deviation 1), no `brew "ruby"`
  (Deviation 2), and the alphabetical `Brewfile` placement of `node` (Deviation
  3). Every ported `.zshrc` line is byte-identical to upstream `93b9788`.
- `LICENSE` and all prior-ring files are unchanged except the `zsh/.zshrc` and
  `Brewfile` edits described here.
