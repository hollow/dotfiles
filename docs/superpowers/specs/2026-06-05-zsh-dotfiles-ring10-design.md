# Remerge dotfiles — Ring 10 (vscode) design

**Date:** 2026-06-05
**Status:** Approved (design); ready for implementation planning
**Repo:** <https://github.com/remerge/dotfiles>
**Builds on:** Rings 0–9 (merged) — see
`docs/superpowers/specs/2026-06-03-zsh-dotfiles-ring9-design.md`
**Upstream pin:** `hollow/dotfiles@main` at commit `cef10b6` (unchanged from Ring 9)

## Goal

Port the **vscode** tool section: the `visual-studio-code` cask, a curated set
of VS Code extensions, the three `vscode/` config files, and the `.zshrc`
section that symlinks the config into VS Code's user directory.

This ring departs from the strict "subset only" / byte-identical invariant of
prior rings in several documented ways (see Deviations): a **curated** extension
list (not all 91 upstream entries) that also includes **4 extensions not present
upstream**, a **curated `settings.json`**, and **emptied `keybindings.json` and
`mcp.json`**.

## Scope (decided)

### A. Brewfile

- **`cask "visual-studio-code"`** — inserted after `cask "tailscale-app"`
  (upstream cask order is `…tailscale-app, visual-studio-code, whatsapp`;
  `whatsapp` is un-ported, so VS Code becomes the last cask). Exists upstream →
  no cask deviation.
- **A new `vscode "…"` block** of **37 curated extensions**, alphabetically
  sorted (Homebrew Bundle keeps `vscode` entries sorted), placed after the cask
  block. The exact list is in "Extension list" below.

### B. Config files (`vscode/`)

- **`vscode/settings.json`** — a **curated owner version** (mode `100644`), not
  byte-identical to upstream. Vendored from upstream, then trimmed to the keys
  the owner wants (commit `0770dc5`). Documented deviation.
- **`vscode/keybindings.json`** — shipped **empty**: exactly `[]` + trailing
  newline (mode `100644`). All custom keybindings removed; not byte-identical to
  upstream. The file is still present and symlinked so each user has a
  dotfiles-managed `keybindings.json` to add their own. Documented deviation.
- **`vscode/mcp.json`** — shipped **empty**: exactly

  ```json
  {
  	"servers": {}
  }
  ```

  (tab-indented, trailing newline). This is **not** byte-identical to upstream
  (which registers a Playwright MCP server). The file is still present and
  symlinked so each user has a dotfiles-managed `mcp.json` to add their own
  servers. Documented deviation.

All three config files are symlinked by `:vscode-load`'s `for i in settings
keybindings mcp` loop, so the `.zshrc` section stays byte-identical to upstream;
only the file *contents* of `keybindings.json` and `mcp.json` (and the curated
`settings.json`) deviate.

### C. `.zshrc` vscode section

Inserted **byte-identical** to upstream, between the existing `brew` block
(after `zi auto has"dscl" for brew`) and the `# 1password` block. Upstream's
order is `brew → python → uv → argcomplete → vscode → 1password`; `python`,
`uv`, and `argcomplete` are un-ported, so vscode sits directly between our
`brew` and `1password` blocks.

```zsh
# vscode: visual studio code editor
# https://code.visualstudio.com
:vscode-load() {
    if ! has "${HOME}/Library/Application Support/Code/User"; then
        return
    fi

    for i in settings keybindings mcp; do
        link "vscode/${i}.json" "Library/Application Support/Code/User/${i}.json"
    done
}

zi auto has"code" wait for vscode
```

All three entries stay in the symlink loop, so the section is byte-identical to
upstream; only the linked files' *contents* deviate (curated `settings.json`,
empty `keybindings.json`, empty `mcp.json`). `:vscode-load` is guarded by
`has "…/Code/User"`, so it is a no-op when VS Code has never run — no error on a
fresh shell.

## Extension list

The 37 curated extensions, exactly as approved (source: the repo owner's
`extensions.txt`). **33** exist in upstream's `Brewfile` at `cef10b6`; **4** are
intentional additions (marked `[+]`) that back references already present in the
vendored `settings.json` (Catppuccin theme/icons, mise).

```
aaron-bond.better-comments
anthropic.claude-code
arcanis.vscode-zipfs
bibhasdn.unique-lines
bierner.github-markdown-preview
bierner.markdown-checkbox
bierner.markdown-emoji
bierner.markdown-footnotes
bierner.markdown-preview-github-styles
catppuccin.catppuccin-vsc            [+] not upstream
catppuccin.catppuccin-vsc-icons      [+] not upstream
catppuccin.catppuccin-vsc-pack       [+] not upstream
davidanson.vscode-markdownlint
dotjoshjohnson.xml
ecmel.vscode-html-css
editorconfig.editorconfig
formulahendry.auto-close-tag
formulahendry.auto-complete-tag
formulahendry.auto-rename-tag
grapecity.gc-excelviewer
hverlin.mise-vscode                  [+] not upstream
ibm.output-colorizer
jasonnutter.vscode-codeowners
kaiwood.endwise
marvhen.reflow-markdown
mechatroner.rainbow-csv
mkhl.shfmt
redhat.vscode-yaml
repreng.csv
richie5um2.vscode-sort-json
samuelcolvin.jinjahtml
sharat.vscode-brewfile
sleistner.vscode-fileutils
tamasfe.even-better-toml
timonwong.shellcheck
tomoki1207.pdf
yzhang.markdown-all-in-one
```

Note: `catppuccin.catppuccin-vsc-pack` is an extension pack that bundles
`catppuccin-vsc` + `catppuccin-vsc-icons`; listing all three is mildly redundant
but harmless, and is kept as the owner curated it.

`sleistner.vscode-fileutils` was originally kept because upstream's
`keybindings.json` bound `fileutils.renameFile` to F2; that keybinding is now
removed (emptied `keybindings.json`), but the extension is retained as a useful
file-operations helper.

## Deviations (documented)

This is the first ring whose Brewfile is **not** a strict subset of upstream,
and whose vendored config files are **not** all byte-identical. Four intentional
deviations, all owner-approved:

1. **Curated extension set with additions.** Of upstream's 91 `vscode` entries,
   33 are ported and 58 are omitted; additionally **4 entries not present
   upstream** (`catppuccin.catppuccin-vsc`, `catppuccin.catppuccin-vsc-icons`,
   `catppuccin.catppuccin-vsc-pack`, `hverlin.mise-vscode`) are added because
   the `settings.json` references the Catppuccin theme/icon themes and mise,
   which upstream never listed.
2. **Curated `settings.json`.** Vendored from upstream then trimmed to the
   owner's preferred keys (commit `0770dc5`); no longer byte-identical to
   upstream.
3. **Emptied `keybindings.json`.** Content is `[]` (all custom keybindings
   removed) instead of upstream's bindings; the file remains present and
   symlinked.
4. **Emptied `mcp.json`.** Content is `{"servers": {}}` instead of upstream's
   Playwright MCP registration; the file remains present and symlinked.

Everything else stays faithful: the cask and the 33 upstream extensions are
byte-identical upstream lines; the `.zshrc` section is byte-identical at its
upstream-relative position (the `settings keybindings mcp` symlink loop is
unchanged — only the linked files' contents deviate).

## Dependency analysis

- **cask `visual-studio-code`** installs the `code` CLI; `zi auto has"code"
  wait for vscode` then runs `:vscode-load`.
- **`:vscode-load`** uses the existing `has` and `link` helpers (present since
  the skeleton ring) and only acts when `~/Library/Application Support/Code/User`
  exists. It symlinks `settings.json`, `keybindings.json`, `mcp.json` from the
  repo into that directory.
- **Extensions** are installed by `brew bundle` via the `code --install-extension`
  path; they have no shell-runtime dependency.
- The 4 added extensions back `settings.json` references; no extension depends on
  an un-ported helper.

## File inventory

### Modify
- `Brewfile` — add `cask "visual-studio-code"` and the 37-entry `vscode` block.
- `zsh/.zshrc` — add the vscode section.

### Create — under `vscode/` (mode `100644`)
- `vscode/settings.json` (curated owner version — deviation).
- `vscode/keybindings.json` (emptied to `[]` — deviation).
- `vscode/mcp.json` (emptied to `{"servers": {}}` — deviation).

## Path mapping

- `vscode/settings.json`, `vscode/keybindings.json`, `vscode/mcp.json` →
  `~/.config/vscode/*.json`, symlinked by `:vscode-load` into
  `~/Library/Application Support/Code/User/*.json`.
- `cask "visual-studio-code"` + the `vscode "…"` block → installed by
  `brew bundle`.
- The vscode `.zshrc` section lives in `~/.config/zsh/.zshrc` (already linked).

## `Brewfile` additions

- **Cask:** `cask "visual-studio-code"` after `cask "tailscale-app"`.
- **Extensions:** the 37 `vscode "…"` lines (sorted) as a new block after the
  casks.

## Verification

- **Cask + upstream extensions:** every `cask` line and every *upstream* `vscode`
  line is byte-identical to upstream; `comm -23` of our `cask`/upstream-`vscode`
  lines against upstream's is empty. The 4 additions are validated as **exactly**
  the known set (`catppuccin.catppuccin-vsc`, `catppuccin.catppuccin-vsc-icons`,
  `catppuccin.catppuccin-vsc-pack`, `hverlin.mise-vscode`) — no other non-upstream
  entry exists. The full `vscode` block equals the sorted contents of the owner's
  curated list (37 lines).
- **`brew bundle list --file=./Brewfile --all`** parses.
- **Config files:** all three are mode `100644` and valid JSON.
  `keybindings.json` equals exactly `[]` (trailing newline) and defines no
  bindings; `mcp.json` equals exactly `{"servers": {}}` (tab-indented, trailing
  newline) and contains no `servers` members; `settings.json` is the owner's
  curated key set (a subset of upstream's keys).
- **`zsh/.zshrc`:** the vscode section diffs clean against upstream's; every
  non-blank line of our `.zshrc` exists in upstream's; `zsh -n zsh/.zshrc` passes.
- **Manual smoke test:** `brew bundle install` installs the cask + 37 extensions;
  on a fresh shell with VS Code's user dir present, `:vscode-load` symlinks the
  three files without error; the Catppuccin theme/icons and mise extension resolve
  the corresponding `settings.json` keys.

## Acceptance criteria

- `Brewfile` has `cask "visual-studio-code"` after `cask "tailscale-app"` and a
  37-line sorted `vscode` block equal to the curated list; the 33 upstream
  entries + cask are byte-identical upstream lines; the only non-upstream
  `vscode` entries are the 4 approved additions; `brew bundle list --all` parses.
- `vscode/keybindings.json` is exactly `[]` and `vscode/mcp.json` is exactly
  `{"servers": {}}` (both mode `100644`); `vscode/settings.json` is the owner's
  curated key set (mode `100644`).
- The vscode `.zshrc` section is byte-identical to upstream between the `brew` and
  `1password` blocks; `zsh -n zsh/.zshrc` passes; `.zshrc` is otherwise a strict
  line-subset of upstream.
- `LICENSE` and all prior-ring files remain unchanged except the `Brewfile` and
  `zsh/.zshrc` edits described here. The temporary `extensions.txt` at the repo
  root is removed before completion (it is an input artifact, not part of the
  dotfiles).
