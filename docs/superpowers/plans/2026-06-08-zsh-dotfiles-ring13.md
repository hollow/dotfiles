# Ring 13 (go + node + ruby) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers-extended-cc:subagent-driven-development (recommended) or superpowers-extended-cc:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Port the programming-language tooling slice (`go`, `node`, `ruby`) from `hollow/dotfiles@93b9788` (the merge of upstream PR #8 "Group language blocks in zshrc top section") into the fork — add the `go` and `ruby` blocks, relocate the existing `node` block into the top language group, and add `brew "go"` / `brew "node"`.

**Architecture:** Two independent file edits plus an install/verify pass. `zsh/.zshrc` gains a `go → node → ruby` group between the `argcomplete` and `1password` blocks (byte-identical to upstream), and the duplicate `node` block in its old alphabetical slot is removed. `Brewfile` gains two upstream-identical lines in the fork's own alphabetical order. The `.zshrc` blocks load under `has` guards, so they no-op until the brews are installed — the two commits are independent and safe in either order. Every ported `.zshrc` line is byte-identical to upstream `93b9788`; deviations are confined to the Brewfile (no `brew "ruby"`; alphabetical `node` placement) and no README change.

**Tech Stack:** zsh + `zi` plugin manager (`z-a-auto` annex, `has`/`add`/`link`/`mkdirp` helpers), Homebrew (`go`, `node`), opportunistic brew ruby. XDG base-dir layout.

**Reference spec:** `docs/superpowers/specs/2026-06-08-zsh-dotfiles-ring13-design.md`

**Upstream pin:** `hollow/dotfiles@main` = `93b9788` (already fetched as `hollow/main`; `git show 93b9788:<path>` works locally).

---

### Task 1: Build the top language group in `.zshrc` (add go + ruby, relocate node)

**Goal:** Make the fork's top language section read `python → uv → argcomplete → go → node → ruby → 1password`, byte-identical to upstream `93b9788`: insert the `go`/`node`/`ruby` blocks after the `argcomplete` block, and remove the now-duplicate `node` block from its old alphabetical slot (between `ncdu` and `opentofu`).

**Files:**
- Modify: `zsh/.zshrc`

**Acceptance Criteria:**
- [ ] The `go`, `node`, and `ruby` blocks appear, in that order, between `zi auto with"uv" for argcomplete` and the `# 1password` block, byte-identical to upstream `93b9788`.
- [ ] The `ruby` block uses the post-PR-#8 detection (`if has brew; then add path "${HOMEBREW_PREFIX}/opt/ruby/bin"; fi`) — **no** `opt/ruby@*` glob, **no** `RUBYHOME` export.
- [ ] The old `node` block is removed from between the `ncdu` and `opentofu` blocks, leaving `ncdu` immediately followed by `opentofu`.
- [ ] `:node-init` appears exactly once in the file (relocated, not duplicated).
- [ ] `zsh -n zsh/.zshrc` passes.

**Verify:**
```bash
# whole span argcomplete→go→node→ruby→1password is byte-identical to upstream
diff <(git show 93b9788:zsh/.zshrc | sed -n '/^zi auto with"uv" for argcomplete$/,/^zi auto has"op" wait1 for 1password-cli$/p') \
     <(sed -n '/^zi auto with"uv" for argcomplete$/,/^zi auto has"op" wait1 for 1password-cli$/p' zsh/.zshrc) \
&& [ "$(grep -c ':node-init' zsh/.zshrc)" = 1 ] \
&& ( sed -n '/^zi auto has"ncdu" wait1 for ncdu$/,/^# opentofu/p' zsh/.zshrc | grep -q 'node' && echo "FAIL: node still in old slot" >&2 && false || true ) \
&& zsh -n zsh/.zshrc \
&& echo OK
```
→ prints `OK` (the top group matches upstream byte-for-byte, exactly one `:node-init`, old slot clear, file parses).

**Steps:**

- [ ] **Step 1: Insert the `go`/`node`/`ruby` group after `argcomplete`.** Replace:

```zsh
zi auto with"uv" for argcomplete

# 1password: remembers all your passwords for you
```

with (tabs inside the function bodies, matching the file):

```zsh
zi auto with"uv" for argcomplete

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

# 1password: remembers all your passwords for you
```

- [ ] **Step 2: Remove the old `node` block from its alphabetical slot.** Replace:

```zsh
zi auto has"ncdu" wait1 for ncdu

# node/npm: JavaScript runtime
# https://nodejs.org
:node-init() {
	export NODE_REPL_HISTORY="${XDG_DATA_HOME}/node/repl_history"
	mkdirp "${XDG_DATA_HOME}/node"
	link npm/npmrc .npmrc
}

zi auto has"node" wait1 for node

# opentofu: open-source terraform fork, installed via mise
```

with:

```zsh
zi auto has"ncdu" wait1 for ncdu

# opentofu: open-source terraform fork, installed via mise
```

(The `ncdu` and `opentofu` anchors keep this old-slot text unique even though the `node` block now also exists in the top group.)

- [ ] **Step 3: Verify byte-identity, single `node` block, and syntax.**

Run:
```bash
diff <(git show 93b9788:zsh/.zshrc | sed -n '/^zi auto with"uv" for argcomplete$/,/^zi auto has"op" wait1 for 1password-cli$/p') \
     <(sed -n '/^zi auto with"uv" for argcomplete$/,/^zi auto has"op" wait1 for 1password-cli$/p' zsh/.zshrc) \
&& [ "$(grep -c ':node-init' zsh/.zshrc)" = 1 ] && echo "node-init count OK" \
&& ( sed -n '/^zi auto has"ncdu" wait1 for ncdu$/,/^# opentofu/p' zsh/.zshrc | grep -q 'node' && echo "FAIL: node still in old slot" || echo "old slot clear OK" ) \
&& zsh -n zsh/.zshrc && echo "syntax OK"
```
Expected: no diff output, then `node-init count OK`, `old slot clear OK`, `syntax OK`.

- [ ] **Step 4: Commit.**

```bash
git add zsh/.zshrc
git commit -m "$(printf 'feat(zsh): group go, node, ruby into top language section (IT-8323)\n\nAdd the go and ruby blocks and relocate the existing node block into the\ntop language group (python -> uv -> argcomplete -> go -> node -> ruby),\nbyte-identical to hollow/dotfiles@93b9788 (PR #8). Ruby uses the\nunversioned brew detection (HOMEBREW_PREFIX/opt/ruby/bin behind has brew);\nthe old node block is removed from its alphabetical slot.\n\nCo-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>')"
```

---

### Task 2: Add `brew "go"` and `brew "node"` to the Brewfile

**Goal:** Add the two new brews this ring installs, each byte-identical to upstream's line, in the fork's own alphabetical order. No `brew "ruby"` (ruby stays opportunistic, matching upstream).

**Files:**
- Modify: `Brewfile`

**Acceptance Criteria:**
- [ ] `brew "go"` sits between `brew "gnupg"` and `brew "graphviz"`.
- [ ] `brew "node"` sits between `brew "nmap"` and `brew "ocrmypdf"`.
- [ ] Both added lines are byte-identical to upstream's (they do NOT appear in the fork-only diff against upstream).
- [ ] No `brew "ruby"` line is added.
- [ ] `brew bundle list --file=./Brewfile --all` parses without error.

**Verify:**
```bash
grep -nE '"(go|node|ruby)"' Brewfile
comm -13 <(git show 93b9788:Brewfile | sort) <(sort Brewfile) | grep -E '"(go|node)"' \
  && echo "FAIL: go/node not byte-identical to upstream" || echo "OK: go/node are upstream lines"
brew bundle list --file=./Brewfile --all >/dev/null && echo "OK: parses"
```
→ `grep` shows `brew "go"` and `brew "node"` only (no `ruby`); the `comm` check prints `OK: go/node are upstream lines`; then `OK: parses`.

**Steps:**

- [ ] **Step 1: Add `brew "go"`.** Replace:

```ruby
brew "gnupg"
brew "graphviz"
```

with:

```ruby
brew "gnupg"
brew "go"
brew "graphviz"
```

- [ ] **Step 2: Add `brew "node"`.** Replace:

```ruby
brew "nmap"
brew "ocrmypdf"
```

with:

```ruby
brew "nmap"
brew "node"
brew "ocrmypdf"
```

- [ ] **Step 3: Verify placement, upstream-identity, no ruby, and that the file parses.**

Run:
```bash
grep -nE '"(go|node|ruby)"' Brewfile
comm -13 <(git show 93b9788:Brewfile | sort) <(sort Brewfile) | grep -E '"(go|node)"' \
  && echo "FAIL: go/node not byte-identical to upstream" || echo "OK: go/node are upstream lines"
brew bundle list --file=./Brewfile --all >/dev/null && echo "OK: parses"
```
Expected: `grep` lists exactly `brew "go"` and `brew "node"` (no `ruby`); then `OK: go/node are upstream lines`; then `OK: parses`.

- [ ] **Step 4: Commit.**

```bash
git add Brewfile
git commit -m "$(printf 'build(brewfile): add go and node (IT-8323)\n\nInstall the go and node toolchains the Ring 13 zshrc blocks guard on.\nByte-identical to hollow/dotfiles@93b9788; ruby is intentionally omitted\n(its block stays opportunistic, matching upstream).\n\nCo-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>')"
```

---

### Task 3: Install go + node and run the end-to-end byte-identity + smoke check

**Goal:** Install `go` and `node` and confirm the ported slice is correct — the top language group is byte-identical to upstream `93b9788`, the file parses, both binaries are on PATH, and (best-effort) the blocks behave in an interactive shell.

**Files:** _(none — verification only)_

**Acceptance Criteria:**
- [ ] `brew bundle install --file=./Brewfile` installs `go` and `node` without error.
- [ ] The argcomplete→1password span diffs clean against upstream `93b9788` and `zsh -n zsh/.zshrc` passes (re-run of Task 1 Verify).
- [ ] `command -v go` and `command -v node` both resolve after install.
- [ ] Best-effort interactive check recorded (see the live-config caveat note).

**Verify:**
```bash
diff <(git show 93b9788:zsh/.zshrc | sed -n '/^zi auto with"uv" for argcomplete$/,/^zi auto has"op" wait1 for 1password-cli$/p') \
     <(sed -n '/^zi auto with"uv" for argcomplete$/,/^zi auto has"op" wait1 for 1password-cli$/p' zsh/.zshrc) \
&& zsh -n zsh/.zshrc && command -v go >/dev/null && command -v node >/dev/null && echo OK
```
→ prints `OK` (top group matches upstream, file parses, both tools installed).

**Steps:**

- [ ] **Step 1: Install the brews.**

Run:
```bash
brew bundle install --file=./Brewfile
```
Expected: completes without error; `go` and `node` are installed.

- [ ] **Step 2: Byte-identity + syntax (full slice).**

Run:
```bash
diff <(git show 93b9788:zsh/.zshrc | sed -n '/^zi auto with"uv" for argcomplete$/,/^zi auto has"op" wait1 for 1password-cli$/p') \
     <(sed -n '/^zi auto with"uv" for argcomplete$/,/^zi auto has"op" wait1 for 1password-cli$/p' zsh/.zshrc) \
&& zsh -n zsh/.zshrc && echo OK
```
Expected: `OK` (no diff output; file parses).

- [ ] **Step 3: Confirm go + node on PATH and a best-effort interactive smoke test.**

Run:
```bash
command -v go && go version
command -v node && node --version
```
Expected: a path + version string for each.

Note (live-config caveat): the live `~/.config` on this machine is a checkout of `hollow/dotfiles@main` (= `93b9788`, the commit being ported), not the fork branch — so `zsh -ic` exercises an equivalent post-PR-#8 layout, not the fork branch's working copy. Interactive behavior to spot-check in a fresh terminal: in a new shell, `echo $GOPATH` is `${XDG_CACHE_HOME}/go`, `echo $NODE_REPL_HISTORY` points under `${XDG_DATA_HOME}/node`, and `~/.npmrc` resolves to the repo's `npm/npmrc`. Record the observed result; byte-identity to the already-shipped upstream commit (Step 2) is the primary guarantee.

- [ ] **Step 4: No commit.**

This task changes no tracked files. The repo sets `HOMEBREW_BUNDLE_NO_LOCK=1`, so `brew bundle install` writes no lock file; if any untracked lock file appears, discard it.

---

## Self-Review

**Spec coverage:** Spec §A (top language group: insert go/node/ruby, relocate node) → Task 1; §B (Brewfile go + node, no ruby) → Task 2; §C (supporting files already in place) → no edit needed, confirmed during exploration (npm/npmrc + mise/config.toml already byte-identical); Verification + smoke section → Task 1 Step 3, Task 2 Step 3, Task 3. Deviations: no README (no task — intentional); no `brew "ruby"` (Task 2 AC + commit body); alphabetical `node` placement (Task 2 Step 2, between `nmap` and `ocrmypdf`). All covered.

**Placeholder scan:** No TBD/TODO; every edit step shows the exact old and new text, and every verify step shows the command and expected output.

**Type/name consistency:** `93b9788`, the block order `go → node → ruby`, the guards `zi auto has"go" for go` / `zi auto has"node" wait1 for node` / `zi auto has"ruby" for ruby`, the ruby `if has brew; then add path "${HOMEBREW_PREFIX}/opt/ruby/bin"; fi` form, and the Brewfile slots (`gnupg → go → graphviz`, `nmap → node → ocrmypdf`) are used consistently across tasks and match the spec. The sed range `/^zi auto with"uv" for argcomplete$/,/^zi auto has"op" wait1 for 1password-cli$/` is identical in every verify command and brackets exactly the ported span.
