# Remerge dotfiles — Ring 10 (vscode) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers-extended-cc:subagent-driven-development (recommended) or superpowers-extended-cc:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Port the vscode tool section from upstream `hollow/dotfiles@cef10b6` — the `visual-studio-code` cask, a curated 37-extension set, the `vscode/` config files (with an emptied `mcp.json`), and the `.zshrc` symlink section.

**Architecture:** Two vendored-verbatim config files (`cp` from the upstream clone) plus a generated empty `mcp.json`, a `Brewfile` cask line + a sorted 37-entry `vscode` block, and a byte-identical `.zshrc` section inserted at its upstream-relative position. A final audit confirms config-file fidelity, the Brewfile subset + the exactly-4 approved additions, and the `.zshrc` line-subset.

**Tech Stack:** zsh, Homebrew Bundle (`brew bundle`), VS Code, git.

**Spec:** `docs/superpowers/specs/2026-06-05-zsh-dotfiles-ring10-design.md`

**Faithfulness invariant (with documented deviations):** `vscode/settings.json` and `vscode/keybindings.json` are byte+mode identical to upstream. The cask and the 33 upstream extensions are byte-identical upstream lines. `zsh/.zshrc` stays a strict line-subset; the vscode section is byte-identical upstream lines at the upstream-relative position. **Two intentional deviations:** (1) the extension set is curated (33 of 91) **plus 4 additions not present upstream** — `catppuccin.catppuccin-vsc`, `catppuccin.catppuccin-vsc-icons`, `catppuccin.catppuccin-vsc-pack`, `hverlin.mise-vscode`; (2) `vscode/mcp.json` is emptied to `{"servers": {}}`.

---

### Task 0: Set up upstream reference clone

**Goal:** Have a byte-exact copy of `hollow/dotfiles@cef10b6` on disk for verbatim copying and diffing (including tracked modes).

**Files:**
- Create: `/tmp/hollow-dotfiles` (ephemeral working clone — not part of the repo)

**Acceptance Criteria:**
- [ ] `git -C /tmp/hollow-dotfiles rev-parse --short HEAD` prints `cef10b6`.

**Verify:** `git -C /tmp/hollow-dotfiles rev-parse --short HEAD` → `cef10b6`

**Steps:**

- [ ] **Step 1: Clone and check out the pin (skip if already present at the pin)**

```bash
if [ "$(git -C /tmp/hollow-dotfiles rev-parse --short HEAD 2>/dev/null)" != "cef10b6" ]; then
    rm -rf /tmp/hollow-dotfiles
    git clone -q https://github.com/hollow/dotfiles /tmp/hollow-dotfiles
    git -C /tmp/hollow-dotfiles checkout -q cef10b6
fi
```

- [ ] **Step 2: Confirm the pin**

Run: `git -C /tmp/hollow-dotfiles rev-parse --short HEAD`
Expected: `cef10b6`

(No commit — scratch clone.)

---

### Task 1: Vendor the vscode config files

**Goal:** Create `vscode/settings.json` and `vscode/keybindings.json` byte-identical to upstream (mode `100644`), and `vscode/mcp.json` emptied to `{"servers": {}}`.

**Files:**
- Create: `vscode/settings.json` (vendored verbatim)
- Create: `vscode/keybindings.json` (vendored verbatim)
- Create: `vscode/mcp.json` (emptied — deviation)

**Acceptance Criteria:**
- [ ] `vscode/settings.json` mode `100644`, blob `efa248b91094a2ada7a8990431bf391339d4c8ab` (identical to upstream).
- [ ] `vscode/keybindings.json` mode `100644`, blob `e820d1c9bbaa30d064545d2c1a99611cb198e054` (identical to upstream).
- [ ] `vscode/mcp.json` is exactly `{` / `\t"servers": {}` / `}` + trailing newline, and registers no servers.

**Verify:** `git add vscode/settings.json vscode/keybindings.json && diff <(cd /tmp/hollow-dotfiles && git ls-files -s vscode/settings.json vscode/keybindings.json) <(git ls-files -s vscode/settings.json vscode/keybindings.json) && printf '{\n\t"servers": {}\n}\n' | diff - vscode/mcp.json` → empty diffs

**Steps:**

- [ ] **Step 1: Copy the two verbatim files from the upstream clone**

```bash
cp /tmp/hollow-dotfiles/vscode/settings.json vscode/settings.json
cp /tmp/hollow-dotfiles/vscode/keybindings.json vscode/keybindings.json
```

- [ ] **Step 2: Write the emptied mcp.json (tab-indented, trailing newline)**

```bash
printf '{\n\t"servers": {}\n}\n' > vscode/mcp.json
```

- [ ] **Step 3: Verify mode+content of the two verbatim files vs upstream**

```bash
git add vscode/settings.json vscode/keybindings.json
diff <(cd /tmp/hollow-dotfiles && git ls-files -s vscode/settings.json vscode/keybindings.json) <(git ls-files -s vscode/settings.json vscode/keybindings.json) && echo "CONFIG FILES IDENTICAL"
```
Expected: `CONFIG FILES IDENTICAL` (settings blob `efa248b`, keybindings blob `e820d1c`, both mode `100644`).

- [ ] **Step 4: Verify mcp.json is exactly the empty skeleton**

```bash
printf '{\n\t"servers": {}\n}\n' | diff - vscode/mcp.json && echo "MCP EMPTY OK"
python3 -c "import json; d=json.load(open('vscode/mcp.json')); assert d == {'servers': {}}, d; print('MCP JSON VALID + NO SERVERS')"
```
Expected: `MCP EMPTY OK`, `MCP JSON VALID + NO SERVERS`.

- [ ] **Step 5: Commit**

```bash
git add vscode/settings.json vscode/keybindings.json vscode/mcp.json
git commit -m "Ring 10: vendor vscode config (settings, keybindings, empty mcp.json)"
```

---

### Task 2: Add the visual-studio-code cask + curated extension block

**Goal:** Add `cask "visual-studio-code"` and the sorted 37-entry `vscode` block to the `Brewfile`.

**Files:**
- Modify: `Brewfile` (append `cask "visual-studio-code"` after `cask "tailscale-app"`, then the 37 `vscode` lines)

**Acceptance Criteria:**
- [ ] `cask "visual-studio-code"` appears directly after `cask "tailscale-app"`.
- [ ] A 37-line `vscode "…"` block follows, alphabetically sorted, exactly matching the curated list.
- [ ] The only non-upstream `vscode` entries are the 4 approved additions; all other `vscode`/`cask` lines exist upstream.
- [ ] `brew bundle list --file=./Brewfile --all` parses (skip with a note if `brew` unavailable).

**Verify:** see the verification block in Step 3 — prints `CASK PLACED`, `37 VSCODE LINES`, `ADDITIONS EXACTLY 4`, `NO UNEXPECTED EXTRAS`.

**Steps:**

- [ ] **Step 1: Append the cask + extension block to the Brewfile**

The Brewfile currently ends with `cask "tailscale-app"`. Replace that final line:

```ruby
cask "tailscale-app"
```

with:

```ruby
cask "tailscale-app"
cask "visual-studio-code"
vscode "aaron-bond.better-comments"
vscode "anthropic.claude-code"
vscode "arcanis.vscode-zipfs"
vscode "bibhasdn.unique-lines"
vscode "bierner.github-markdown-preview"
vscode "bierner.markdown-checkbox"
vscode "bierner.markdown-emoji"
vscode "bierner.markdown-footnotes"
vscode "bierner.markdown-preview-github-styles"
vscode "catppuccin.catppuccin-vsc"
vscode "catppuccin.catppuccin-vsc-icons"
vscode "catppuccin.catppuccin-vsc-pack"
vscode "davidanson.vscode-markdownlint"
vscode "dotjoshjohnson.xml"
vscode "ecmel.vscode-html-css"
vscode "editorconfig.editorconfig"
vscode "formulahendry.auto-close-tag"
vscode "formulahendry.auto-complete-tag"
vscode "formulahendry.auto-rename-tag"
vscode "grapecity.gc-excelviewer"
vscode "hverlin.mise-vscode"
vscode "ibm.output-colorizer"
vscode "jasonnutter.vscode-codeowners"
vscode "kaiwood.endwise"
vscode "marvhen.reflow-markdown"
vscode "mechatroner.rainbow-csv"
vscode "mkhl.shfmt"
vscode "redhat.vscode-yaml"
vscode "repreng.csv"
vscode "richie5um2.vscode-sort-json"
vscode "samuelcolvin.jinjahtml"
vscode "sharat.vscode-brewfile"
vscode "sleistner.vscode-fileutils"
vscode "tamasfe.even-better-toml"
vscode "timonwong.shellcheck"
vscode "tomoki1207.pdf"
vscode "yzhang.markdown-all-in-one"
```

- [ ] **Step 2: (optional) parse-check**

```bash
brew bundle list --file=./Brewfile --all >/dev/null 2>&1 && echo "BREWFILE PARSES" || echo "BREWFILE PARSE SKIPPED (brew unavailable)"
```

- [ ] **Step 3: Verify cask placement, extension count, and exactly-4-additions**

```bash
# cask directly after tailscale-app
grep -A1 '^cask "tailscale-app"' Brewfile | grep -qx 'cask "visual-studio-code"' && echo "CASK PLACED"
# 37 vscode lines
test "$(grep -c '^vscode ' Brewfile)" = "37" && echo "37 VSCODE LINES"
# additions = exactly the 4 known ids
grep '^vscode ' Brewfile | sed 's/vscode "//; s/"//' | sort -u > /tmp/our-ext.txt
grep '^vscode ' /tmp/hollow-dotfiles/Brewfile | sed 's/vscode "//; s/"//' | sort -u > /tmp/up-ext.txt
diff <(comm -23 /tmp/our-ext.txt /tmp/up-ext.txt) <(printf 'catppuccin.catppuccin-vsc\ncatppuccin.catppuccin-vsc-icons\ncatppuccin.catppuccin-vsc-pack\nhverlin.mise-vscode\n') && echo "ADDITIONS EXACTLY 4"
# every cask line exists upstream (no cask deviation)
comm -23 <(grep -E '^cask ' Brewfile | sort -u) <(grep -E '^cask ' /tmp/hollow-dotfiles/Brewfile | sort -u) | sed 's/^/EXTRA CASK: /'
echo "NO UNEXPECTED EXTRAS"
```
Expected: `CASK PLACED`, `37 VSCODE LINES`, `ADDITIONS EXACTLY 4`, no `EXTRA CASK:` lines, `NO UNEXPECTED EXTRAS`.

- [ ] **Step 4: Commit**

```bash
git add Brewfile
git commit -m "Ring 10: add visual-studio-code cask + curated vscode extensions"
```

---

### Task 3: Add the vscode .zshrc section

**Goal:** Insert the byte-identical vscode section into `zsh/.zshrc` between the `brew` block and `# 1password`.

**Files:**
- Modify: `zsh/.zshrc` (insert the vscode section)

**Acceptance Criteria:**
- [ ] The vscode section is byte-identical to upstream, between `zi auto has"dscl" for brew` and `# 1password`.
- [ ] `zsh -n zsh/.zshrc` passes.

**Verify:** `zsh -n zsh/.zshrc && diff <(sed -n '/^# vscode: visual studio code editor/,/^zi auto has"code" wait for vscode/p' zsh/.zshrc) <(sed -n '/^# vscode: visual studio code editor/,/^zi auto has"code" wait for vscode/p' /tmp/hollow-dotfiles/zsh/.zshrc)` → parses + empty diff

**Steps:**

- [ ] **Step 1: Insert the section**

Find this block (end of the `brew` section, start of `1password`):

```zsh
zi auto has"dscl" for brew

# 1password: remembers all your passwords for you
```

Replace with:

```zsh
zi auto has"dscl" for brew

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

# 1password: remembers all your passwords for you
```

- [ ] **Step 2: Parse-check + verify the block vs upstream**

```bash
zsh -n zsh/.zshrc && echo "ZSHRC PARSES"
diff <(sed -n '/^# vscode: visual studio code editor/,/^zi auto has"code" wait for vscode/p' zsh/.zshrc) \
     <(sed -n '/^# vscode: visual studio code editor/,/^zi auto has"code" wait for vscode/p' /tmp/hollow-dotfiles/zsh/.zshrc) && echo "VSCODE BLOCK IDENTICAL"
```
Expected: `ZSHRC PARSES`, `VSCODE BLOCK IDENTICAL`.

- [ ] **Step 3: Commit**

```bash
git add zsh/.zshrc
git commit -m "Ring 10: add vscode .zshrc section"
```

---

### Task 4: Remove input artifact + faithfulness audit

**Goal:** Remove the temporary `extensions.txt` (an input artifact, not part of the dotfiles) and confirm the whole ring is faithful: config-file fidelity, Brewfile subset + exactly-4 additions, `.zshrc` strict line-subset.

**Files:**
- Delete: `extensions.txt`

**Acceptance Criteria:**
- [ ] `extensions.txt` no longer exists in the repo.
- [ ] `vscode/settings.json` + `vscode/keybindings.json` mode+blob match upstream; `vscode/mcp.json` is `{"servers": {}}`.
- [ ] Every non-blank line of `zsh/.zshrc` exists in upstream's; `zsh -n` passes.
- [ ] Every `cask` line and every *upstream* `vscode` line exists upstream; the only non-upstream `vscode` entries are the 4 approved additions.
- [ ] `git status` is clean.

**Verify:** the audit script below prints all OK markers and no `EXTRA`/`UNEXPECTED` lines.

**Steps:**

- [ ] **Step 1: Remove the input artifact**

```bash
git rm -q extensions.txt 2>/dev/null || rm -f extensions.txt
```

- [ ] **Step 2: Config-file fidelity**

```bash
diff <(cd /tmp/hollow-dotfiles && git ls-files -s vscode/settings.json vscode/keybindings.json) <(git ls-files -s vscode/settings.json vscode/keybindings.json) && echo "CONFIG FILES OK"
python3 -c "import json; assert json.load(open('vscode/mcp.json'))=={'servers':{}}; print('MCP EMPTY OK')"
```
Expected: `CONFIG FILES OK`, `MCP EMPTY OK`.

- [ ] **Step 3: Brewfile subset + exactly-4 additions**

```bash
grep '^vscode ' Brewfile | sed 's/vscode "//; s/"//' | sort -u > /tmp/our-ext.txt
grep '^vscode ' /tmp/hollow-dotfiles/Brewfile | sed 's/vscode "//; s/"//' | sort -u > /tmp/up-ext.txt
diff <(comm -23 /tmp/our-ext.txt /tmp/up-ext.txt) <(printf 'catppuccin.catppuccin-vsc\ncatppuccin.catppuccin-vsc-icons\ncatppuccin.catppuccin-vsc-pack\nhverlin.mise-vscode\n') && echo "ADDITIONS EXACTLY 4"
comm -23 <(grep -E '^cask ' Brewfile | sort -u) <(grep -E '^cask ' /tmp/hollow-dotfiles/Brewfile | sort -u) | sed 's/^/UNEXPECTED CASK: /'
echo "BREWFILE CHECK DONE"
```
Expected: `ADDITIONS EXACTLY 4`, no `UNEXPECTED CASK:` lines, `BREWFILE CHECK DONE`.

- [ ] **Step 4: `.zshrc` strict line-subset + parse**

```bash
zsh -n zsh/.zshrc && echo "ZSHRC PARSES"
comm -23 <(grep -vE '^[[:space:]]*$' zsh/.zshrc | sort -u) <(grep -vE '^[[:space:]]*$' /tmp/hollow-dotfiles/zsh/.zshrc | sort -u) | sed 's/^/EXTRA: /'
echo "ZSHRC SUBSET CHECK DONE"
```
Expected: `ZSHRC PARSES`, no `EXTRA:` lines, `ZSHRC SUBSET CHECK DONE`.

- [ ] **Step 5: Commit the artifact removal + confirm clean tree**

```bash
git add -A
git commit -m "Ring 10: remove extensions.txt input artifact"
git status --short && echo "STATUS DONE"
```
Expected: no output before `STATUS DONE`.

---

## Notes

- The README is intentionally **not** updated (curated subset; prior rings added no README change).
- `:vscode-load` uses the existing `has`/`link` helpers and the symlink loop keeps `mcp` — the empty `mcp.json` is still linked into VS Code's user dir.
- The two deviations (curated/added extensions; emptied `mcp.json`) are owner-approved and recorded in the spec.
