# Remerge dotfiles — Ring 9 (claude + opentofu/.gitignore fix) design

**Date:** 2026-06-03
**Status:** Approved (design); ready for implementation planning
**Repo:** <https://github.com/remerge/dotfiles>
**Builds on:** Rings 0–8 (merged) — see
`docs/superpowers/specs/2026-06-02-zsh-dotfiles-ring8-design.md`
**Upstream pin:** `hollow/dotfiles@main` at commit `cef10b6` (unchanged from Ring 8)

## Goal

Port the **claude** tool section as a faithful subset, and fix the
`opentofu/.gitignore` that was missed in Ring 8 (which ported opentofu's
`.zshrc` section, `mise` entry, and `tfa`/`tfp` scripts but not its
`.gitignore`).

## Scope (decided)

### A. claude

The complete claude footprint upstream at `cef10b6` is:

- `Brewfile`: `cask "claude"` and `vscode "anthropic.claude-code"`.
- `zsh/.zshrc`: a six-line claude section (comment + two `export`s + a
  two-line `cp`).
- `git/ignore`: `**/.claude/settings.local.json`.
- `.claude/skills/macos-defaults/SKILL.md`.

This ring ports:

- **`cask "claude"`** — the Claude desktop app.
- **claude `.zshrc` section** — trimmed to a strict line-subset: the comment
  and the two `export` lines, byte-identical to upstream. The two `cp` lines
  are **omitted** (see Documented deviation).

Out of scope:

- **`vscode "anthropic.claude-code"`** — this repo ports no `vscode` Brewfile
  entries (it has none at any prior ring); deferred with the rest of the vscode
  block to a possible future ring.
- **`git/ignore` sync** — our `git/ignore` is already byte-identical to
  upstream (`**/.claude/settings.local.json`); no change needed.
- **`.claude/skills/macos-defaults/SKILL.md`** — it is a macOS-defaults skill,
  not claude configuration, and this repo clones to `~/.config`, so a
  repo-root `.claude/` maps to `~/.config/.claude/` — which Claude Code does
  not read (it reads `~/.claude/`). Deferred to a future `macos` ring where its
  path and wiring can be solved properly.

### B. opentofu/.gitignore (Ring 8 fix)

- **Create `opentofu/.gitignore`**, vendored byte-identical to upstream
  (mode `100644`), single line `credentials.tfrc.json`. Keeps the `opentofu`
  config dir present while ignoring the generated credentials file, mirroring
  the `gcloud/.gitignore` pattern from Ring 8.

## Faithfulness principle (carried over)

Every vendored file is byte-identical to upstream at `cef10b6`, with matching
tracked git mode. `zsh/.zshrc` remains a strict line-subset; the added claude
section is byte-identical upstream lines inserted at its upstream-relative
position, minus the omitted `cp` lines (still a line-subset — we only ever drop
upstream lines, never alter them).

`cask "claude"` exists in upstream's `Brewfile` at `cef10b6`, so there is **no
Brewfile deviation**.

## Documented deviation (new)

The claude `.zshrc` section omits upstream's final two lines:

```zsh
cp "${HOME}/Library/Application Support/Claude/claude_desktop_config.json" \
    "${HOME}/.claude/claude_desktop_config.json"
```

This `cp` runs unconditionally on every interactive shell startup and writes an
error to stderr whenever the source file is absent (e.g. the Claude desktop app
is installed but never launched, or not installed at all). Omitting it keeps a
fresh shell quiet and is consistent with the line-subset principle — we drop
upstream lines without altering the ones we keep. This is the only file-level
deviation in this ring.

## Dependency analysis

- **claude:** `cask "claude"` installs the Claude desktop app. The two retained
  exports (`CLAUDE_CODE_NEW_INIT`, `ENABLE_CLAUDEAI_MCP_SERVERS`) are plain
  environment variables with no runtime dependency on any binary or un-ported
  helper. The section has no `zi` line upstream.
- **opentofu/.gitignore:** inert; no dependency. Complements the opentofu
  section already shipped in Ring 8.

No artifact in this ring depends on an un-ported upstream helper.

## File inventory

### Modify

- `Brewfile` — add `cask "claude"`.
- `zsh/.zshrc` — add the trimmed claude section.

### Create — vendored verbatim from `hollow/dotfiles@cef10b6`

- `opentofu/.gitignore` (mode `100644`).

## Path mapping

- `opentofu/.gitignore` → `~/.config/opentofu/.gitignore` (keeps the opentofu
  config dir present while ignoring its generated `credentials.tfrc.json`).
- The claude `.zshrc` section lives in `~/.config/zsh/.zshrc` (already linked).
- `cask "claude"` is installed by `brew bundle` from the `Brewfile`.

## `Brewfile` addition

Add `cask "claude"` between `cask "1password-cli"` and
`cask "font-meslo-lg-nerd-font"`.

Upstream cask order at `cef10b6` is `1password`, `1password-cli`, `adguard`,
`claude`, `font-meslo-lg-nerd-font`, … — `adguard` is un-ported, so `claude`
lands directly after `1password-cli`. It exists upstream → **no deviation**.

## `zsh/.zshrc` addition

Inserted byte-identical (minus the omitted `cp`), preserving upstream's relative
order: between the existing `bat` block (after `zi auto has"bat" wait for bat`)
and the `# dircolors` block.

Upstream's section order around claude is `bat → boto → checkov → claude →
consul → copier → dircolors`; `boto`, `checkov`, `consul`, and `copier` are
un-ported, so claude sits directly between our `bat` and `dircolors` blocks.

```zsh
# claude: AI assistant by Anthropic
# https://claude.ai
export CLAUDE_CODE_NEW_INIT=1
export ENABLE_CLAUDEAI_MCP_SERVERS=true
```

## `opentofu/.gitignore`

```gitignore
credentials.tfrc.json
```

(Byte-identical to upstream at `cef10b6`; mode `100644`.)

## Verification

- **`opentofu/.gitignore`** → mode+content identical to upstream via
  `git ls-files -s` (mode `100644`, same blob hash).
- **`zsh/.zshrc`** → the four-line claude block diffs clean against upstream
  lines 333–336; every non-blank line in our `.zshrc` exists in upstream's;
  `zsh -n zsh/.zshrc` passes; the omitted `cp`/`claude_desktop_config.json`
  lines are absent from our file.
- **`Brewfile`** → `cask "claude"` exists upstream;
  `brew bundle list --file=./Brewfile --all` parses; `comm -23` of our
  `brew`/`cask` lines against upstream's is empty.
- **Manual smoke test:** `brew bundle install` installs the cask; on a fresh
  shell the claude section loads without error, `$CLAUDE_CODE_NEW_INIT` and
  `$ENABLE_CLAUDEAI_MCP_SERVERS` are set, and no `cp` error appears.

## Acceptance criteria

- `opentofu/.gitignore` is vendored byte-identical to upstream with mode
  `100644`.
- The claude `.zshrc` section's four lines are byte-identical to upstream and
  sit between the `bat` and `dircolors` blocks; the `cp` lines are omitted;
  `zsh -n zsh/.zshrc` passes.
- `cask "claude"` installs via `brew bundle`; the faithfulness checks pass with
  **no Brewfile deviations**.
- `LICENSE` and all prior-ring files remain unchanged except the `Brewfile` and
  `zsh/.zshrc` edits described here; `git/ignore`, `mise/config.toml`, and the
  README are untouched.
