# Ring 8 (gcloud, opentofu, shell/ssh helpers, sync) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers-extended-cc:subagent-driven-development (recommended) or superpowers-extended-cc:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Vendor upstream `hollow/dotfiles@cef10b6`'s gcloud + opentofu sections, the shell/ssh helper scripts, and three brews + one cask, plus sync `git/config`'s git-lfs filter — all a faithful subset.

**Architecture:** Mostly vendored-verbatim files (`cp` from the upstream reference clone guarantees byte-fidelity) plus two `.zshrc` tool sections, a `zup()` wiring edit, a one-tool `mise/config.toml`, and a byte-identical `git/config`. Scripts in `zsh/` auto-join PATH/fpath, so they need no wiring. A final audit confirms mode+content fidelity via `git ls-files -s` and a Brewfile/`.zshrc` faithfulness check.

**Tech Stack:** zsh, Homebrew (`Brewfile`), zi/z-a-auto + mise, gcloud SDK, OpenTofu, GNU parallel, git helper subcommands, git-lfs.

**Spec:** `docs/superpowers/specs/2026-06-02-zsh-dotfiles-ring8-design.md`

---

## File Structure

- `Brewfile` — add `brew "dog"`, `brew "git-delete-merged-branches"`, `brew "git-lfs"`, `cask "gcloud-cli"`.
- `zsh/.zshrc` — add gcloud + opentofu sections; wire `:tmux-update` + `:gcloud-update` into `zup()`.
- `mise/config.toml` — add `opentofu = "latest"`.
- `git/config` — add the `[filter "lfs"]` block (→ byte-identical to upstream).
- `gcloud/.gitignore` (create, 644).
- `zsh/:each`, `zsh/:parallel` (create, 644); `zsh/cdl`, `zsh/cdu`, `zsh/grc`, `zsh/sl`, `zsh/ssu`, `zsh/sshlive`, `zsh/ghc`, `zsh/ghm`, `zsh/tfa`, `zsh/tfp` (create, 755).

**Mode discipline:** `:each`/`:parallel` and `gcloud/.gitignore` are `100644`; all other new scripts are `100755`. Every vendoring task verifies mode+content via `git ls-files -s` against the upstream clone.

---

### Task 0: Set up upstream reference clone

**Goal:** Have a byte-exact copy of `hollow/dotfiles@cef10b6` on disk for verbatim copying and diffing (including tracked modes).

**Files:**
- Create: `/tmp/hollow-dotfiles` (ephemeral working clone)

**Acceptance Criteria:**
- [ ] `git -C /tmp/hollow-dotfiles rev-parse --short HEAD` prints `cef10b6`.

**Verify:** `git -C /tmp/hollow-dotfiles rev-parse --short HEAD` → `cef10b6`

**Steps:**

- [ ] **Step 1: Clone and check out the pin**

```bash
rm -rf /tmp/hollow-dotfiles
git clone -q https://github.com/hollow/dotfiles /tmp/hollow-dotfiles
git -C /tmp/hollow-dotfiles checkout -q cef10b6
```

- [ ] **Step 2: Confirm**

Run: `git -C /tmp/hollow-dotfiles rev-parse --short HEAD`
Expected: `cef10b6`

(No commit — scratch clone.)

---

### Task 1: gcloud (cask + .zshrc section + .gitignore + zup wiring)

**Goal:** Install the gcloud SDK cask, vendor `gcloud/.gitignore`, add the gcloud `.zshrc` section, and wire `:tmux-update` + `:gcloud-update` into `zup()`.

**Files:**
- Create: `gcloud/.gitignore` (mode 644)
- Modify: `Brewfile` (add `cask "gcloud-cli"` between `cask "font-meslo-lg-nerd-font"` and `cask "ghostty"`)
- Modify: `zsh/.zshrc` (gcloud section between the eza block and `# ghostty`; two new lines in `zup()`)

**Acceptance Criteria:**
- [ ] `gcloud/.gitignore` byte-identical to upstream, mode `100644`.
- [ ] `Brewfile` has `cask "gcloud-cli"` between `font-meslo-lg-nerd-font` and `ghostty`.
- [ ] The gcloud `.zshrc` section is byte-identical to upstream, between the eza block and `# ghostty`.
- [ ] `zup()` contains `:tmux-update && \` and `:gcloud-update && \` between `:brew-update && \` and `zi self-update && \`.
- [ ] `zsh -n zsh/.zshrc` exits 0.

**Verify:** `zsh -n zsh/.zshrc && git add gcloud/.gitignore && diff <(cd /tmp/hollow-dotfiles && git ls-files -s gcloud/.gitignore) <(git ls-files -s gcloud/.gitignore) && diff <(sed -n '/^# gcloud: Google Cloud SDK/,/^zi auto has"gcloud" wait1 for gcloud/p' zsh/.zshrc) <(sed -n '/^# gcloud: Google Cloud SDK/,/^zi auto has"gcloud" wait1 for gcloud/p' /tmp/hollow-dotfiles/zsh/.zshrc) && grep -qx '    :tmux-update && \' zsh/.zshrc && grep -qx '    :gcloud-update && \' zsh/.zshrc` → all pass

**Steps:**

- [ ] **Step 1: Vendor `gcloud/.gitignore`**

```bash
cd /Users/bene/src/remerge/dotfiles
mkdir -p gcloud
cp /tmp/hollow-dotfiles/gcloud/.gitignore gcloud/.gitignore
```

- [ ] **Step 2: Add the cask**

Edit `Brewfile`, inserting between `cask "font-meslo-lg-nerd-font"` and `cask "ghostty"`:

```ruby
cask "font-meslo-lg-nerd-font"
cask "gcloud-cli"
cask "ghostty"
```

- [ ] **Step 3: Add the gcloud `.zshrc` section**

In `zsh/.zshrc`, find the end of the eza block (`zi auto has"eza" wait for eza`). Immediately after it (and the blank line that follows), before `# ghostty`, insert:

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

- [ ] **Step 4: Wire `zup()`**

In `zsh/.zshrc`, change the `zup()` body from:

```zsh
zup() {
    local oldpwd="${PWD}"
    :brew-update && \
    zi self-update && \
    zi update --all
    cd "${oldpwd}"
}
```

to (insert the two lines after `:brew-update && \`):

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

- [ ] **Step 5: Verify**

```bash
zsh -n zsh/.zshrc && echo "PARSE OK"
git add gcloud/.gitignore
diff <(cd /tmp/hollow-dotfiles && git ls-files -s gcloud/.gitignore) <(git ls-files -s gcloud/.gitignore) && echo "GITIGNORE IDENTICAL"
diff <(sed -n '/^# gcloud: Google Cloud SDK/,/^zi auto has"gcloud" wait1 for gcloud/p' zsh/.zshrc) \
     <(sed -n '/^# gcloud: Google Cloud SDK/,/^zi auto has"gcloud" wait1 for gcloud/p' /tmp/hollow-dotfiles/zsh/.zshrc) && echo "GCLOUD BLOCK IDENTICAL"
grep -qx '    :tmux-update && \' zsh/.zshrc && grep -qx '    :gcloud-update && \' zsh/.zshrc && echo "ZUP WIRED"
grep -nE '^cask "(font-meslo-lg-nerd-font|gcloud-cli|ghostty)"' Brewfile
```
Expected: `PARSE OK`, `GITIGNORE IDENTICAL`, `GCLOUD BLOCK IDENTICAL`, `ZUP WIRED`, and `gcloud-cli` between the two casks.

- [ ] **Step 6: Commit**

```bash
git add Brewfile zsh/.zshrc gcloud/.gitignore
git commit -m "Ring 8: add gcloud (cask, .zshrc section, .gitignore, zup wiring)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: opentofu (.zshrc section + mise config + tfa/tfp)

**Goal:** Add the opentofu `.zshrc` section, declare `opentofu` in `mise/config.toml`, and vendor the `tfa`/`tfp` wrapper scripts.

**Files:**
- Modify: `zsh/.zshrc` (opentofu section between the ssh block's closing `fi` and `# tmux`)
- Modify: `mise/config.toml` (add `opentofu = "latest"`)
- Create (mode 755): `zsh/tfa`, `zsh/tfp`

**Acceptance Criteria:**
- [ ] The opentofu `.zshrc` section is byte-identical to upstream, between the ssh block and `# tmux`.
- [ ] `mise/config.toml` equals upstream's with only `[tools]` + `opentofu = "latest"` retained.
- [ ] `zsh/tfa` and `zsh/tfp` byte-identical to upstream, mode `100755`, parse under `zsh -n`.
- [ ] `zsh -n zsh/.zshrc` exits 0.

**Verify:** `zsh -n zsh/.zshrc && zsh -n zsh/tfa && zsh -n zsh/tfp && diff <(sed -n '/^# opentofu:/,/^zi auto with"mise" wait1 for opentofu/p' zsh/.zshrc) <(sed -n '/^# opentofu:/,/^zi auto with"mise" wait1 for opentofu/p' /tmp/hollow-dotfiles/zsh/.zshrc) && diff <(grep -E '^\[tools\]$|^opentofu = ' /tmp/hollow-dotfiles/mise/config.toml) mise/config.toml && git add zsh/tfa zsh/tfp && diff <(cd /tmp/hollow-dotfiles && git ls-files -s zsh/tfa zsh/tfp) <(git ls-files -s zsh/tfa zsh/tfp)` → all pass

**Steps:**

- [ ] **Step 1: Vendor `tfa` and `tfp`**

```bash
cd /Users/bene/src/remerge/dotfiles
for f in tfa tfp; do cp /tmp/hollow-dotfiles/zsh/$f zsh/$f; chmod 755 zsh/$f; done
```

- [ ] **Step 2: Add `opentofu` to `mise/config.toml`**

Derive from upstream (keep only the `[tools]` header and the opentofu entry):

```bash
grep -E '^\[tools\]$|^opentofu = ' /tmp/hollow-dotfiles/mise/config.toml > mise/config.toml
```

The result must be exactly:

```toml
[tools]
opentofu = "latest"
```

- [ ] **Step 3: Add the opentofu `.zshrc` section**

In `zsh/.zshrc`, find the end of the ssh block (its closing `fi`). Immediately after it (and the blank line that follows), before `# tmux: a terminal multiplexer`, insert:

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

- [ ] **Step 4: Verify**

```bash
zsh -n zsh/.zshrc && zsh -n zsh/tfa && zsh -n zsh/tfp && echo "PARSE OK"
diff <(sed -n '/^# opentofu:/,/^zi auto with"mise" wait1 for opentofu/p' zsh/.zshrc) \
     <(sed -n '/^# opentofu:/,/^zi auto with"mise" wait1 for opentofu/p' /tmp/hollow-dotfiles/zsh/.zshrc) && echo "OPENTOFU BLOCK IDENTICAL"
diff <(grep -E '^\[tools\]$|^opentofu = ' /tmp/hollow-dotfiles/mise/config.toml) mise/config.toml && echo "MISE CONFIG OK"
git add zsh/tfa zsh/tfp
diff <(cd /tmp/hollow-dotfiles && git ls-files -s zsh/tfa zsh/tfp) <(git ls-files -s zsh/tfa zsh/tfp) && echo "TF SCRIPTS IDENTICAL"
```
Expected: `PARSE OK`, `OPENTOFU BLOCK IDENTICAL`, `MISE CONFIG OK`, `TF SCRIPTS IDENTICAL` (both `100755`).

- [ ] **Step 5: Commit**

```bash
git add zsh/.zshrc mise/config.toml zsh/tfa zsh/tfp
git commit -m "Ring 8: add opentofu (.zshrc section, mise config, tfa/tfp)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 3: Vendor shell + ssh helper scripts

**Goal:** Vendor the helper scripts: `:each`, `:parallel` (autoloaded functions, mode 644) and `cdl`, `cdu`, `grc`, `sl`, `ssu`, `sshlive` (executable, mode 755).

**Files:**
- Create (mode 644): `zsh/:each`, `zsh/:parallel`
- Create (mode 755): `zsh/cdl`, `zsh/cdu`, `zsh/grc`, `zsh/sl`, `zsh/ssu`, `zsh/sshlive`

**Acceptance Criteria:**
- [ ] `zsh/:each`, `zsh/:parallel` byte-identical to upstream, mode `100644`.
- [ ] `zsh/cdl`, `zsh/cdu`, `zsh/grc`, `zsh/sl`, `zsh/ssu`, `zsh/sshlive` byte-identical to upstream, mode `100755`.
- [ ] `zsh -n` parses each script cleanly.

**Verify:** `for f in cdl cdu grc sl ssu sshlive; do zsh -n zsh/$f || echo "FAIL $f"; done; for f in ':each' ':parallel'; do zsh -n "zsh/$f" || echo "FAIL $f"; done; git add 'zsh/:each' 'zsh/:parallel' zsh/cdl zsh/cdu zsh/grc zsh/sl zsh/ssu zsh/sshlive && diff <(cd /tmp/hollow-dotfiles && git ls-files -s 'zsh/:each' 'zsh/:parallel' zsh/cdl zsh/cdu zsh/grc zsh/sl zsh/ssu zsh/sshlive) <(git ls-files -s 'zsh/:each' 'zsh/:parallel' zsh/cdl zsh/cdu zsh/grc zsh/sl zsh/ssu zsh/sshlive)` → no FAIL, empty diff

**Steps:**

- [ ] **Step 1: Copy the scripts with correct modes**

```bash
cd /Users/bene/src/remerge/dotfiles
for f in ':each' ':parallel'; do cp "/tmp/hollow-dotfiles/zsh/$f" "zsh/$f"; chmod 644 "zsh/$f"; done
for f in cdl cdu grc sl ssu sshlive; do cp "/tmp/hollow-dotfiles/zsh/$f" "zsh/$f"; chmod 755 "zsh/$f"; done
```

- [ ] **Step 2: Parse-check + verify mode/content vs upstream**

```bash
for f in cdl cdu grc sl ssu sshlive; do zsh -n zsh/$f && echo "ok $f" || echo "FAIL $f"; done
for f in ':each' ':parallel'; do zsh -n "zsh/$f" && echo "ok $f" || echo "FAIL $f"; done
FILES="zsh/:each zsh/:parallel zsh/cdl zsh/cdu zsh/grc zsh/sl zsh/ssu zsh/sshlive"
git add $FILES
diff <(cd /tmp/hollow-dotfiles && git ls-files -s $FILES) <(git ls-files -s $FILES) && echo "HELPERS IDENTICAL"
```
Expected: `ok` for all eight, `HELPERS IDENTICAL`. `:each`/`:parallel` lines start `100644`; the rest `100755`.

- [ ] **Step 3: Commit**

```bash
git add 'zsh/:each' 'zsh/:parallel' zsh/cdl zsh/cdu zsh/grc zsh/sl zsh/ssu zsh/sshlive
git commit -m "Ring 8: vendor shell + ssh helper scripts

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 4: gh helpers + git-delete-merged-branches

**Goal:** Vendor `ghc`/`ghm` and add `brew "git-delete-merged-branches"` so `git dmb` (which `ghc` calls) works.

**Files:**
- Create (mode 755): `zsh/ghc`, `zsh/ghm`
- Modify: `Brewfile` (add `brew "git-delete-merged-branches"` between `brew "git"` and `brew "glow"`)

**Acceptance Criteria:**
- [ ] `zsh/ghc`, `zsh/ghm` byte-identical to upstream, mode `100755`, parse under `zsh -n`.
- [ ] `Brewfile` has `brew "git-delete-merged-branches"` between `git` and `glow`.

**Verify:** `zsh -n zsh/ghc && zsh -n zsh/ghm && git add zsh/ghc zsh/ghm && diff <(cd /tmp/hollow-dotfiles && git ls-files -s zsh/ghc zsh/ghm) <(git ls-files -s zsh/ghc zsh/ghm) && grep -qx 'brew "git-delete-merged-branches"' Brewfile && grep -qx 'brew "git-delete-merged-branches"' /tmp/hollow-dotfiles/Brewfile` → all pass

**Steps:**

- [ ] **Step 1: Vendor `ghc` and `ghm`**

```bash
cd /Users/bene/src/remerge/dotfiles
for f in ghc ghm; do cp /tmp/hollow-dotfiles/zsh/$f zsh/$f; chmod 755 zsh/$f; done
```

- [ ] **Step 2: Add the brew**

Edit `Brewfile`, inserting between `brew "git"` and `brew "glow"`:

```ruby
brew "git"
brew "git-delete-merged-branches"
brew "glow"
```

- [ ] **Step 3: Verify**

```bash
zsh -n zsh/ghc && zsh -n zsh/ghm && echo "PARSE OK"
git add zsh/ghc zsh/ghm
diff <(cd /tmp/hollow-dotfiles && git ls-files -s zsh/ghc zsh/ghm) <(git ls-files -s zsh/ghc zsh/ghm) && echo "GH HELPERS IDENTICAL"
grep -qx 'brew "git-delete-merged-branches"' Brewfile && echo "BREW ADDED"
grep -qx 'brew "git-delete-merged-branches"' /tmp/hollow-dotfiles/Brewfile && echo "BREW IN UPSTREAM"
grep -nE '^brew "(git|git-delete-merged-branches|glow)"' Brewfile
```
Expected: `PARSE OK`, `GH HELPERS IDENTICAL` (both `100755`), `BREW ADDED`, `BREW IN UPSTREAM`, brew between `git` and `glow`.

- [ ] **Step 4: Commit**

```bash
git add Brewfile zsh/ghc zsh/ghm
git commit -m "Ring 8: vendor gh helpers (ghc, ghm) + git-delete-merged-branches

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 5: dog + git-lfs brews + git/config lfs sync

**Goal:** Add `brew "dog"` and `brew "git-lfs"`, and sync `git/config` to upstream by adding the `[filter "lfs"]` block.

**Files:**
- Modify: `Brewfile` (add `brew "dog"` between `brew "curl"` and `brew "duf"`; add `brew "git-lfs"` between `brew "git-delete-merged-branches"` and `brew "glow"`)
- Modify: `git/config` (add the `[filter "lfs"]` block → byte-identical to upstream)

**Acceptance Criteria:**
- [ ] `Brewfile` has `dog` between `curl` and `duf`, and `git-lfs` between `git-delete-merged-branches` and `glow`.
- [ ] `git/config` is byte-identical to upstream at `cef10b6`.

**Verify:** `diff git/config /tmp/hollow-dotfiles/git/config && grep -qx 'brew "dog"' Brewfile && grep -qx 'brew "git-lfs"' Brewfile && grep -qx 'brew "dog"' /tmp/hollow-dotfiles/Brewfile && grep -qx 'brew "git-lfs"' /tmp/hollow-dotfiles/Brewfile` → all pass

**Steps:**

- [ ] **Step 1: Sync `git/config`**

Our `git/config` equals upstream's minus only the `[filter "lfs"]` block, so copying upstream's is the exact sync (adds the block, changes nothing else):

```bash
cd /Users/bene/src/remerge/dotfiles
cp /tmp/hollow-dotfiles/git/config git/config
```

- [ ] **Step 2: Add the brews**

Edit `Brewfile`. Insert `brew "dog"` between `brew "curl"` and `brew "duf"`:

```ruby
brew "curl"
brew "dog"
brew "duf"
```

Insert `brew "git-lfs"` between `brew "git-delete-merged-branches"` (added in Task 4) and `brew "glow"`:

```ruby
brew "git-delete-merged-branches"
brew "git-lfs"
brew "glow"
```

- [ ] **Step 3: Verify**

```bash
diff git/config /tmp/hollow-dotfiles/git/config && echo "GIT CONFIG IDENTICAL"
grep -qx 'brew "dog"' Brewfile && grep -qx 'brew "git-lfs"' Brewfile && echo "BREWS ADDED"
grep -qx 'brew "dog"' /tmp/hollow-dotfiles/Brewfile && grep -qx 'brew "git-lfs"' /tmp/hollow-dotfiles/Brewfile && echo "BREWS IN UPSTREAM"
grep -nE '^brew "(curl|dog|duf|git-delete-merged-branches|git-lfs|glow)"' Brewfile
```
Expected: `GIT CONFIG IDENTICAL`, `BREWS ADDED`, `BREWS IN UPSTREAM`, and correct ordering (`curl`→`dog`→`duf`; `git-delete-merged-branches`→`git-lfs`→`glow`).

- [ ] **Step 4: Commit**

```bash
git add Brewfile git/config
git commit -m "Ring 8: add dog + git-lfs brews; sync git/config lfs filter

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 6: Faithfulness + Brewfile audit

**Goal:** Confirm the whole ring is a clean subset — valid Brewfile with no deviations, valid zsh, every vendored file mode+content-identical to upstream, `git/config` byte-identical, and `.zshrc` a strict line-subset.

**Files:**
- None (verification only)

**Acceptance Criteria:**
- [ ] `brew bundle list --file=./Brewfile --all` parses and lists `dog`, `git-delete-merged-branches`, `git-lfs`, `gcloud-cli`.
- [ ] `comm -23` of this repo's `brew`/`cask` lines against upstream's is empty.
- [ ] `zsh -n zsh/.zshrc` exits 0 and every new `zsh/*` script parses.
- [ ] Every vendored file (`gcloud/.gitignore`, the twelve new `zsh/*` scripts) is mode+content-identical to upstream; `git/config` byte-identical; `mise/config.toml` equals upstream minus the non-opentofu tools; every non-blank `.zshrc` line exists upstream.

**Verify:** the Step 1 bash block → ends with `AUDIT CLEAN`

**Steps:**

- [ ] **Step 1: Run the faithfulness audit**

```bash
set -e
# 1. Brewfile parses and includes the new entries
for x in dog git-delete-merged-branches git-lfs gcloud-cli; do
  brew bundle list --file=./Brewfile --all | grep -qx "$x"
done

# 2. No brew/cask deviation vs upstream
dev=$(comm -23 <(grep -E '^(brew|cask) ' Brewfile | sort -u) \
                <(grep -E '^(brew|cask) ' /tmp/hollow-dotfiles/Brewfile | sort -u))
[ -z "$dev" ] || { echo "DEVIATIONS:"; echo "$dev"; exit 1; }

# 3. zsh syntax: .zshrc + every new script
zsh -n zsh/.zshrc
for f in cdl cdu grc sl ssu sshlive ghc ghm tfa tfp; do zsh -n zsh/$f; done
for f in ':each' ':parallel'; do zsh -n "zsh/$f"; done

# 4. mode + content identical to upstream for every vendored file
FILES="gcloud/.gitignore zsh/:each zsh/:parallel zsh/cdl zsh/cdu zsh/grc zsh/sl \
zsh/ssu zsh/sshlive zsh/ghc zsh/ghm zsh/tfa zsh/tfp"
diff <(cd /tmp/hollow-dotfiles && git ls-files -s $FILES) <(git ls-files -s $FILES)

# 5. git/config byte-identical; mise/config.toml = upstream minus non-opentofu tools
diff git/config /tmp/hollow-dotfiles/git/config
diff <(grep -E '^\[tools\]$|^opentofu = ' /tmp/hollow-dotfiles/mise/config.toml) mise/config.toml

# 6. .zshrc strict line-subset (every non-blank our-line exists upstream)
missing=$(comm -23 <(sort -u zsh/.zshrc) <(sort -u /tmp/hollow-dotfiles/zsh/.zshrc) | grep -v '^[[:space:]]*$' || true)
[ -z "$missing" ] || { echo "NON-UPSTREAM .zshrc LINES:"; echo "$missing"; exit 1; }

echo "AUDIT CLEAN"
```
Expected: prints `AUDIT CLEAN` with no `DEVIATIONS`, no diff output, no non-upstream lines.

- [ ] **Step 2: (Optional) Manual smoke test on a fresh shell**

After `brew bundle install`:
```bash
command -v gcloud tofu dog git-lfs              # resolve
git is-dirty; echo "exit=$?"                    # git-* subcommands
type ghc ghm grc sl cdl cdu ssu sshlive tfa tfp # resolve as commands
tofu version                                    # installed via mise
```

(No commit — verification only.)

---

## Notes for the implementer

- **Order:** Task 0 first. Tasks 1, 2, 4, 5 all edit `Brewfile` and/or `zsh/.zshrc`/`mise/config.toml`/`git/config` — run sequentially to avoid edit conflicts. Task 6 last.
- **Modes:** `:each`/`:parallel` and `gcloud/.gitignore` are `100644`; all other new scripts `100755`. The `git ls-files -s` diffs catch any drift — don't skip them.
- **`git/config`:** our pre-Ring-8 file equals upstream minus only the `[filter "lfs"]` block, so `cp` of upstream's file is the exact, safe sync. If a future check shows extra local lines, stop and reconcile instead.
- **`:`-prefixed paths:** always quote (`"zsh/:each"`) so the shell doesn't treat `:` specially.
- **Do not add** any other upstream helper, a `git-lfs`/`dog` `.zshrc` section (none exist upstream), or extra `mise` `[tools]` entries.
