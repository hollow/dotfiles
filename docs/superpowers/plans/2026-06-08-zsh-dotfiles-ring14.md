# Ring 14 — Upstream Sync 93b9788 → c8a74a6 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers-extended-cc:subagent-driven-development (recommended) or superpowers-extended-cc:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Sync the curated fork forward over the 15 upstream commits `93b9788..c8a74a6` in one ring, landing every carried section/tool byte-identical to `hollow/dotfiles@c8a74a6` (sole exception: the fork's `claude` deviation).

**Architecture:** Because the fork is a clean **same-order subset** of upstream (verified: `diff 93b9788 ↔ fork@HEAD` shows only whole-section deletions plus one `claude` intra-section hunk), the most reliable port is **derive-by-deletion**: start from upstream's `c8a74a6` artifacts and remove exactly what the fork doesn't carry. `zsh/.zshrc` is rebuilt by dropping 15 regions + the `.envrc` tail, then re-applying the fork's `claude` omission; `vscode/settings.json` is rebuilt by `jq --sort-keys 'del(...)'` of 13 curation-out keys; `Brewfile` gets targeted line insertions. Every recipe in this plan has been executed and verified against `c8a74a6` before being written here.

**Tech Stack:** zsh, zi plugin manager, Homebrew Brewfile, VSCode settings JSON; `git`, `awk`, `perl`, `jq`, `zsh -n`.

**Branch:** `IT-8323-ring14-upstream-sync` (already created; spec already committed).

**Spec:** `docs/superpowers/specs/2026-06-08-zsh-dotfiles-ring14-design.md`

**Pin:** `hollow/dotfiles@c8a74a6` — referenced below as `hollow/main` (the fetched ref; HEAD = `c8a74a6`).

---

### Task 1: `zsh/.zshrc` + `zsh/mkdirp` — structural sync to c8a74a6

**Goal:** Rebuild `zsh/.zshrc` byte-identical to `c8a74a6` for all 55 carried regions (init consolidation, fold markers, `js/*` split, `:ssh-init`, new `postgresql` section, ruby markers, `.local/bin` moved to EOF), preserving the fork's `claude` deviation; and create the extracted `zsh/mkdirp` helper.

**Files:**
- Modify: `zsh/.zshrc`
- Create: `zsh/mkdirp`

**Acceptance Criteria:**
- [x] `diff zsh/.zshrc <(git show hollow/main:zsh/.zshrc)` shows **zero** `<` (fork-side) lines and only `>` hunks for the 15 omitted regions, the 3 `claude` sync lines, and the `.envrc` block.
- [x] `zsh/mkdirp` is byte-identical to `git show hollow/main:zsh/mkdirp`.
- [x] `grep -c 'local dst=.*claude_desktop_config' zsh/.zshrc` → `0` (claude deviation preserved).
- [x] `grep -c 'alias X' zsh/.zshrc` → `0`; no `zsh/X` file exists.
- [x] File ends with `add path "${HOME}/.local/bin"` + single newline (no trailing blank line, no `.envrc` block).
- [x] `zsh -n zsh/.zshrc` and `zsh -n zsh/mkdirp` pass.

**Verify:** `diff zsh/.zshrc <(git show hollow/main:zsh/.zshrc) | grep -c '^<'` → `0` AND `zsh -n zsh/.zshrc && echo OK`

**Steps:**

- [x] **Step 1: Create `zsh/mkdirp` byte-identical to upstream**

```bash
git show hollow/main:zsh/mkdirp > zsh/mkdirp
diff <(git show hollow/main:zsh/mkdirp) zsh/mkdirp && echo "mkdirp OK"
```
Expected: empty diff, prints `mkdirp OK`.

- [x] **Step 2: Rebuild `zsh/.zshrc` via the tested derive-by-deletion pipeline**

This single pipeline (1) drops the 15 regions the fork doesn't carry, (2) strips the trailing `.envrc` block leaving `.local/bin` as the final line, (3) re-applies the fork's `claude` deviation (drops the 3 `claude_desktop_config.json` sync lines). Run from the repo root:

```bash
git show hollow/main:zsh/.zshrc | awk '
  $0 ~ /^# region (android|ansible|ansible\/ara|atuin|aws|aws\/boto|checkov|consul|direnv|nomad|sqlite|sshp|tmux\/xpanes|youtube|zsh\/bench): / {del=1; next}
  del && $0 == "# endregion" {del=0; sb=1; next}
  del {next}
  sb && $0 == "" {sb=0; next}
  {sb=0; print}
' \
| perl -0pe 's/\n\n# Load \.envrc after shell initialization if present\nif \[\[ -e \.envrc \]\]; then\n\tpushd "\$\{HOME\}" &>\/dev\/null && popd\nfi\n\z/\n/' \
| perl -0pe 's/\texport ENABLE_CLAUDEAI_MCP_SERVERS=true\n\n\tlocal src="\$\{HOME\}\/Library\/Application Support\/Claude\/claude_desktop_config.json"\n\tlocal dst="\$\{HOME\}\/.claude\/claude_desktop_config.json"\n\t\[\[ -e \$\{src\} && \$\{src\} -nt \$\{dst\} \]\] && cp "\$\{src\}" "\$\{dst\}"\n/\texport ENABLE_CLAUDEAI_MCP_SERVERS=true\n/' \
> zsh/.zshrc
```

(The awk `sb` flag consumes the blank line that followed each deleted region, so no double blanks remain. Both `perl -0pe` are full-file slurps anchored with `\z` / unique strings.)

- [x] **Step 3: Verify byte-identity against c8a74a6 (the core test)**

```bash
diff zsh/.zshrc <(git show hollow/main:zsh/.zshrc) > /tmp/r14.diff
echo "fork-side modifications (MUST be 0):"; grep -c '^<' /tmp/r14.diff
echo "omitted region headers in diff (MUST be 15):"; grep -cE '^> # region ' /tmp/r14.diff
```
Expected: `0` fork-side lines; `15` region headers. The full `/tmp/r14.diff` must contain **only**: the 15 omitted regions, the 3 `claude` sync lines, and the 4-line `.envrc` block — all as `>` (c8a74a6-only) lines. If any `<` line appears, the rebuild is wrong — stop and investigate.

- [x] **Step 4: Verify structural + deviation checks**

```bash
grep -c 'local dst=.*claude_desktop_config' zsh/.zshrc   # -> 0 (claude deviation)
grep -c 'alias X' zsh/.zshrc                              # -> 0
grep -c 'Load .envrc' zsh/.zshrc                          # -> 0
grep -cE '^# region (postgresql|js/node|js/npm|js/bun|js/biome): ' zsh/.zshrc  # -> 5
grep -c ':ssh-init()' zsh/.zshrc                          # -> 1
tail -1 zsh/.zshrc | cat -A                               # -> add path "${HOME}/.local/bin"$
test ! -e zsh/X && echo "no zsh/X OK"
```
Expected: `0`, `0`, `0`, `5`, `1`, the `.local/bin` line, `no zsh/X OK`.

- [x] **Step 5: Syntax check**

```bash
zsh -n zsh/.zshrc && echo ".zshrc syntax OK"
zsh -n zsh/mkdirp && echo "mkdirp syntax OK"
```
Expected: both print OK.

- [x] **Step 6: Commit**

```bash
git add zsh/.zshrc zsh/mkdirp
git commit -m "$(cat <<'EOF'
feat(zsh): sync zshrc to upstream c8a74a6 (IT-8323)

Fold-region markers, init/bootstrap consolidation (mkdirp extracted to
zsh/mkdirp, homebrew block moved up, .local/bin to EOF), js/node→js/npm
split + js/bun + js/biome, ssh :ssh-init convention, new postgresql
section, ruby markers. Carried sections byte-identical to c8a74a6;
claude section keeps the fork's claude_desktop_config omission.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 2: `Brewfile` — bun/biome, go/ruby tooling, postgres + VSCode extensions

**Goal:** Add the 5 new `brew` lines and 5 new `vscode` extension lines at upstream's relative positions, each byte-identical to `c8a74a6`.

**Files:**
- Modify: `Brewfile`

**Acceptance Criteria:**
- [x] `Brewfile` contains `brew "biome"`, `brew "bun"`, `brew "gofumpt"`, `brew "gopls"`, `brew "postgresql@18", link: true`, `brew "ruby"` at the positions below.
- [x] `Brewfile` contains `vscode "biomejs.biome"`, `vscode "golang.go"`, `vscode "oven.bun-vscode"`, `vscode "shopify.ruby-lsp"`, `vscode "sorbet.sorbet-vscode-extension"`.
- [x] Each new line is byte-identical to its `c8a74a6` counterpart.
- [x] `diff <(git show hollow/main:Brewfile | grep -E 'biome|bun|gofumpt|gopls|postgresql@18|ruby|golang.go|oven.bun|shopify.ruby|sorbet') <(grep -E 'biome|bun|gofumpt|gopls|postgresql@18|ruby|golang.go|oven.bun|shopify.ruby|sorbet' Brewfile)` shows the same lines.

**Verify:** `grep -cE '^brew "(biome|bun|gofumpt|gopls|postgresql@18|ruby)"' Brewfile` → `6` AND `grep -cE '^vscode "(biomejs.biome|golang.go|oven.bun-vscode|shopify.ruby-lsp|sorbet.sorbet-vscode-extension)"' Brewfile` → `5`

**Steps:**

- [x] **Step 1: Insert the 5 `brew` lines** (each via exact two-line anchor)

`brew "biome"` between `bat` and `bottom`:
```
brew "bat"
brew "bottom"
```
→
```
brew "bat"
brew "biome"
brew "bottom"
```

`brew "bun"` between `bottom` and `ccusage`:
```
brew "bottom"
brew "ccusage"
```
→
```
brew "bottom"
brew "bun"
brew "ccusage"
```

`brew "gofumpt"` + `brew "gopls"` between `go` and `graphviz`:
```
brew "go"
brew "graphviz"
```
→
```
brew "go"
brew "gofumpt"
brew "gopls"
brew "graphviz"
```

`brew "postgresql@18", link: true` between `poppler` and `pre-commit`:
```
brew "poppler"
brew "pre-commit"
```
→
```
brew "poppler"
brew "postgresql@18", link: true
brew "pre-commit"
```

`brew "ruby"` between `rsync` and `ruff`:
```
brew "rsync"
brew "ruff"
```
→
```
brew "rsync"
brew "ruby"
brew "ruff"
```

- [x] **Step 2: Insert the 5 `vscode` extension lines** (each via exact two-line anchor)

`vscode "biomejs.biome"` between `bierner.markdown-preview-github-styles` and `catppuccin.catppuccin-vsc`:
```
vscode "bierner.markdown-preview-github-styles"
vscode "catppuccin.catppuccin-vsc"
```
→ insert `vscode "biomejs.biome"` between them.

`vscode "golang.go"` between `fredwangwang.vscode-hcl-format` and `grapecity.gc-excelviewer`:
```
vscode "fredwangwang.vscode-hcl-format"
vscode "grapecity.gc-excelviewer"
```
→ insert `vscode "golang.go"` between them.

`vscode "oven.bun-vscode"` between `opentofu.vscode-opentofu` and `redhat.vscode-yaml`:
```
vscode "opentofu.vscode-opentofu"
vscode "redhat.vscode-yaml"
```
→ insert `vscode "oven.bun-vscode"` between them.

`vscode "shopify.ruby-lsp"` between `sharat.vscode-brewfile` and `sleistner.vscode-fileutils`:
```
vscode "sharat.vscode-brewfile"
vscode "sleistner.vscode-fileutils"
```
→ insert `vscode "shopify.ruby-lsp"` between them.

`vscode "sorbet.sorbet-vscode-extension"` between `sleistner.vscode-fileutils` and `tamasfe.even-better-toml`:
```
vscode "sleistner.vscode-fileutils"
vscode "tamasfe.even-better-toml"
```
→ insert `vscode "sorbet.sorbet-vscode-extension"` between them.

- [x] **Step 3: Verify**

```bash
grep -cE '^brew "(biome|bun|gofumpt|gopls|postgresql@18|ruby)"' Brewfile   # -> 6
grep -cE '^vscode "(biomejs.biome|golang.go|oven.bun-vscode|shopify.ruby-lsp|sorbet.sorbet-vscode-extension)"' Brewfile  # -> 5
# each new line byte-matches upstream:
for l in 'brew "biome"' 'brew "bun"' 'brew "gofumpt"' 'brew "gopls"' 'brew "postgresql@18", link: true' 'brew "ruby"' 'vscode "biomejs.biome"' 'vscode "golang.go"' 'vscode "oven.bun-vscode"' 'vscode "shopify.ruby-lsp"' 'vscode "sorbet.sorbet-vscode-extension"'; do
  git show hollow/main:Brewfile | grep -qxF "$l" && grep -qxF "$l" Brewfile && echo "OK: $l" || echo "MISMATCH: $l"
done
```
Expected: `6`, `5`, and `OK:` for every line.

- [x] **Step 4: Commit**

```bash
git add Brewfile
git commit -m "$(cat <<'EOF'
build(brewfile): add bun, biome, ruby, postgresql, go formatters (IT-8323)

brew: biome, bun, gofumpt, gopls, postgresql@18 (link), ruby.
vscode: biomejs.biome, golang.go, oven.bun-vscode, shopify.ruby-lsp,
sorbet.sorbet-vscode-extension. Lines and relative placement
byte-identical to upstream c8a74a6.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 3: `vscode/settings.json` — per-language format-on-save

**Goal:** Add the formatter-feature keys from `c8a74a6` (the `[lang]` blocks, `editor.codeActionsOnSave`, `go.useLanguageServer`, `gopls`, `json.schemaDownload.trustedDomains`), values byte-identical to `c8a74a6`, in the fork's `jq --sort-keys` canonical form, preserving the fork's existing curation-outs.

**Files:**
- Modify: `vscode/settings.json`

**Acceptance Criteria:**
- [x] `vscode/settings.json` is valid JSON.
- [x] `diff <(git show HEAD:vscode/settings.json) vscode/settings.json` shows **only additions** (`>`), no removals (`<`) of the fork's existing keys.
- [x] The added keys are exactly: the 15 `[lang]` blocks (`[css] [go] [hcl] [html] [javascript] [json] [jsonc] [markdown] [opentofu] [opentofu-vars] [python] [ruby] [shellscript] [typescript] [yaml]`), `editor.codeActionsOnSave`, `go.useLanguageServer`, `gopls`, `json.schemaDownload.trustedDomains`.
- [x] The fork's previous omissions stay absent: `grep -c 'ansible.lightspeed\|files.associations\|makefile.configureOnOpen\|window.commandCenter\|workbench.activityBar\|yaml.customTags' vscode/settings.json` → `0`.
- [x] File round-trips: `diff vscode/settings.json <(jq -S . vscode/settings.json)` is empty.

**Verify:** `jq -e . vscode/settings.json >/dev/null && echo VALID` AND `diff <(git show HEAD:vscode/settings.json) vscode/settings.json | grep -c '^<'` → `0`

**Steps:**

- [x] **Step 1: Rebuild `vscode/settings.json` from upstream minus the 13 curation-out keys** (tested — `jq -S` round-trips the repo's settings format byte-identically)

```bash
git show hollow/main:vscode/settings.json | jq -S 'del(
  ."ansible.lightspeed.enabled",
  ."ansible.lightspeed.suggestions.enabled",
  ."ansible.validation.lint.enabled",
  ."files.associations",
  ."makefile.configureOnOpen",
  ."window.commandCenter",
  ."window.newWindowDimensions",
  ."workbench.activityBar.location",
  ."workbench.browser.showInTitleBar",
  ."workbench.layoutControl.enabled",
  ."workbench.navigationControl.enabled",
  ."workbench.startupEditor",
  ."yaml.customTags"
)' > vscode/settings.json
```

- [x] **Step 2: Verify additions-only against the fork's previous settings**

```bash
diff <(git show HEAD:vscode/settings.json) vscode/settings.json > /tmp/r14_settings.diff
echo "removals of existing keys (MUST be 0):"; grep -c '^<' /tmp/r14_settings.diff
echo "added [lang] blocks (MUST be 15):"; grep -cE '^>   "\[' /tmp/r14_settings.diff
```
Expected: `0` removals; `15` `[lang]` blocks. The `>` additions must be exactly the formatter-feature keys listed in the acceptance criteria.

- [x] **Step 3: Verify curation-outs absent + valid JSON + round-trip**

```bash
jq -e . vscode/settings.json >/dev/null && echo "VALID JSON"
grep -c 'ansible.lightspeed\|files.associations\|makefile.configureOnOpen\|window.commandCenter\|workbench.activityBar\|yaml.customTags' vscode/settings.json  # -> 0
diff vscode/settings.json <(jq -S . vscode/settings.json) && echo "round-trip OK"
```
Expected: `VALID JSON`, `0`, `round-trip OK`.

- [x] **Step 4: Commit**

```bash
git add vscode/settings.json
git commit -m "$(cat <<'EOF'
feat(vscode): per-language format-on-save + go/ruby/biome formatters (IT-8323)

Add [lang] default-formatter blocks, editor.codeActionsOnSave,
go.useLanguageServer + gopls gofumpt, and json schema trusted domains
from upstream c8a74a6. Values byte-identical to upstream; maintained in
jq --sort-keys form. Fork's existing settings.json omissions preserved.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 4: Mark plan tasks complete

**Goal:** Flip this plan's task checkboxes to done and commit, per ring convention (final bookkeeping commit before the PR).

**Files:**
- Modify: `docs/superpowers/plans/2026-06-08-zsh-dotfiles-ring14.md`
- Modify: `docs/superpowers/plans/2026-06-08-zsh-dotfiles-ring14.md.tasks.json`

**Acceptance Criteria:**
- [x] All Task 1–3 acceptance-criteria/step checkboxes in this plan are checked.
- [x] `.tasks.json` statuses for Tasks 1–3 are `completed`.
- [x] Whole-ring re-verification passes (commands below).

**Verify:** the full re-verification block prints all-OK.

**Steps:**

- [x] **Step 1: Whole-ring re-verification** (run all at once; everything must pass)

```bash
# .zshrc byte-identity (0 fork-side lines)
diff zsh/.zshrc <(git show hollow/main:zsh/.zshrc) | grep -c '^<'        # -> 0
diff <(git show hollow/main:zsh/mkdirp) zsh/mkdirp && echo "mkdirp OK"     # empty diff
zsh -n zsh/.zshrc && zsh -n zsh/mkdirp && echo "syntax OK"
# Brewfile
grep -cE '^brew "(biome|bun|gofumpt|gopls|postgresql@18|ruby)"' Brewfile   # -> 6
grep -cE '^vscode "(biomejs.biome|golang.go|oven.bun-vscode|shopify.ruby-lsp|sorbet.sorbet-vscode-extension)"' Brewfile  # -> 5
brew bundle list --file=./Brewfile --all >/dev/null && echo "brewfile parses"
# settings.json
jq -e . vscode/settings.json >/dev/null && echo "settings valid"
diff vscode/settings.json <(jq -S . vscode/settings.json) && echo "settings round-trip OK"
```
Expected: `0`, `mkdirp OK`, `syntax OK`, `6`, `5`, `brewfile parses`, `settings valid`, `settings round-trip OK`.

- [x] **Step 2: Check the boxes** in this plan doc (Tasks 1–3 acceptance criteria + steps) and set Task 1–3 status to `completed` in `2026-06-08-zsh-dotfiles-ring14.md.tasks.json`.

- [x] **Step 3: Commit**

```bash
git add docs/superpowers/plans/2026-06-08-zsh-dotfiles-ring14.md docs/superpowers/plans/2026-06-08-zsh-dotfiles-ring14.md.tasks.json
git commit -m "$(cat <<'EOF'
docs(ring14): mark plan tasks complete (IT-8323)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Notes for the implementer

- **Do not run `brew bundle install`** — this machine's live `~/.config` tracks `hollow@main`, not this branch; installing tools is out of scope. `brew bundle list --all` only parses the file.
- **Byte-identity is the contract.** If any verification diff shows unexpected `<` (fork-side) lines, the derive-by-deletion produced something wrong — re-run the exact pipeline from the spec; do not hand-patch.
- **The `claude` section is the one intentional non-identity** (Deviation 6) — its 3 `claude_desktop_config.json` sync lines must stay removed.
- **No PR is opened by this plan.** After Task 4, hand back for the user to review and push/open the `IT-8323: Ring 14` PR (run `mise run lint` / pre-commit first if configured).
