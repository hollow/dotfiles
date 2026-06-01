# Ring 5 (ssh + gpg) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers-extended-cc:subagent-driven-development (recommended) or superpowers-extended-cc:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Port upstream `hollow/dotfiles@5fd2f15`'s self-contained `gnupg` and `ssh` sections into this dotfiles repo as a faithful subset (including the 1Password SSH-agent block deferred from Ring 4).

**Architecture:** Two tool sections, each added at its upstream-relative position. `gnupg` is config-only (a `.zshrc` block + one Brewfile brew). `ssh` adds a `.zshrc` block, one Brewfile brew, and three vendored config files copied byte-identical from upstream (one with a single deletion). A final faithfulness/syntax audit confirms the subset invariant.

**Tech Stack:** zsh, Homebrew (`Brewfile`), zi plugin manager, oh-my-zsh plugins (`OMZP::gpg-agent`, `OMZP::ssh-agent`), OpenSSH client config, GnuPG.

**Spec:** `docs/superpowers/specs/2026-06-01-zsh-dotfiles-ring5-design.md`

---

## File Structure

- `Brewfile` (modify) — add `brew "gnupg"` and `brew "openssh"` at their alphabetical slots.
- `zsh/.zshrc` (modify) — add the `gnupg` block (after the git section) and the `ssh` block (after the rsync block).
- `ssh/config` (create) — upstream's, minus the Colima `Include` line.
- `ssh/config.crypto` (create) — upstream's, byte-identical.
- `ssh/.gitignore` (create) — upstream's, byte-identical (`config.local`).

All edits are additive except two intentional deletions (the `ssu` alias is never added; the Colima `Include` is removed from `ssh/config`).

---

### Task 0: Set up upstream reference clone

**Goal:** Have a byte-exact copy of `hollow/dotfiles@5fd2f15` on disk so vendored files can be copied verbatim and diffed.

**Files:**
- Create: `/tmp/hollow-dotfiles` (ephemeral working clone, not part of the repo)

**Acceptance Criteria:**
- [ ] `/tmp/hollow-dotfiles` exists and `git -C /tmp/hollow-dotfiles rev-parse --short HEAD` prints `5fd2f15`.

**Verify:** `git -C /tmp/hollow-dotfiles rev-parse --short HEAD` → `5fd2f15`

**Steps:**

- [ ] **Step 1: Clone upstream and check out the pinned commit**

```bash
rm -rf /tmp/hollow-dotfiles
git clone -q https://github.com/hollow/dotfiles /tmp/hollow-dotfiles
git -C /tmp/hollow-dotfiles checkout -q 5fd2f15
```

- [ ] **Step 2: Confirm the pinned commit**

Run: `git -C /tmp/hollow-dotfiles rev-parse --short HEAD`
Expected: `5fd2f15`

(No commit — this is a scratch clone, not a repo change.)

---

### Task 1: Add the gnupg section

**Goal:** Install GnuPG via Homebrew and add upstream's gnupg `.zshrc` block (GPG_TTY, XDG `GNUPGHOME`, gpg-agent plugin).

**Files:**
- Modify: `Brewfile` (add `brew "gnupg"` between `brew "gnu-time"` and `brew "grep"`)
- Modify: `zsh/.zshrc` (insert gnupg block immediately after `alias s="git st ."`, before `# glamour/glow`)

**Acceptance Criteria:**
- [ ] `Brewfile` contains `brew "gnupg"` on its own line, alphabetically placed between `gnu-time` and `grep`.
- [ ] `zsh/.zshrc` contains the 7-line gnupg block (2 comment + 5 code lines) exactly as upstream, located between the git section and the glamour/glow block.
- [ ] Every added `.zshrc` line is byte-identical to a line in `/tmp/hollow-dotfiles/zsh/.zshrc`.
- [ ] `zsh -n zsh/.zshrc` exits 0.

**Verify:** `zsh -n zsh/.zshrc && grep -A6 '^# gnupg: GNU privacy guard' zsh/.zshrc` → prints the full block, no syntax error

**Steps:**

- [ ] **Step 1: Add the Brewfile entry**

Edit `Brewfile`, inserting a new line between `brew "gnu-time"` and `brew "grep"`:

```ruby
brew "gnu-time"
brew "gnupg"
brew "grep"
```

- [ ] **Step 2: Add the gnupg `.zshrc` block**

In `zsh/.zshrc`, find the end of the git section:

```zsh
alias s="git st ."
```

Immediately after that line (and the blank line that follows it), insert:

```zsh
# gnupg: GNU privacy guard
# https://gnupg.org/
export GPG_TTY="${TTY}"
export GNUPGHOME="${XDG_DATA_HOME}/gnupg"
mkdir -p "${GNUPGHOME}"
chmod 0700 "${GNUPGHOME}"
zi auto wait for OMZP::gpg-agent
```

so the result reads `… alias s="git st ." → [blank] → # gnupg block → [blank] → # glamour/glow …`.

- [ ] **Step 3: Verify zsh parses and the block is byte-identical to upstream**

Run:
```bash
zsh -n zsh/.zshrc && echo "PARSE OK"
diff <(grep -A6 '^# gnupg: GNU privacy guard' zsh/.zshrc) \
     <(grep -A6 '^# gnupg: GNU privacy guard' /tmp/hollow-dotfiles/zsh/.zshrc) \
  && echo "BLOCK IDENTICAL"
```
Expected: `PARSE OK` and `BLOCK IDENTICAL` (empty diff).

- [ ] **Step 4: Commit**

```bash
git add Brewfile zsh/.zshrc
git commit -m "Ring 5: add gnupg (brew + .zshrc block)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: Add the ssh section (config files + .zshrc block + brew)

**Goal:** Vendor upstream's ssh client config, install OpenSSH, and add upstream's ssh `.zshrc` block wiring the 1Password SSH agent with an `OMZP::ssh-agent` fallback — without the `ssu` alias and without the Colima `Include`.

**Files:**
- Create: `ssh/config.crypto` (byte-identical copy from upstream)
- Create: `ssh/.gitignore` (byte-identical copy from upstream)
- Create: `ssh/config` (upstream's, minus the Colima `Include` line)
- Modify: `Brewfile` (add `brew "openssh"` between `brew "neovim"` and `brew "ripgrep"`)
- Modify: `zsh/.zshrc` (insert ssh block immediately after `zi auto wait for OMZP::rsync`, before `# tmux: a terminal multiplexer`)

**Acceptance Criteria:**
- [ ] `ssh/config.crypto` and `ssh/.gitignore` are byte-identical to upstream (`diff` empty).
- [ ] `ssh/config` equals upstream's `ssh/config` with exactly one line removed: `Include %d/.config/colima/ssh_config`.
- [ ] `Brewfile` contains `brew "openssh"` between `neovim` and `ripgrep`.
- [ ] `zsh/.zshrc` contains the ssh block (without the `alias ssu=…` line), located between the rsync block and the tmux block; every added line except the omitted alias is byte-identical to upstream.
- [ ] `zsh -n zsh/.zshrc` exits 0.

**Verify:** `zsh -n zsh/.zshrc && diff ssh/config.crypto /tmp/hollow-dotfiles/ssh/config.crypto && diff ssh/.gitignore /tmp/hollow-dotfiles/ssh/.gitignore && diff <(grep -v 'colima/ssh_config' /tmp/hollow-dotfiles/ssh/config) ssh/config` → all empty (exit 0)

**Steps:**

- [ ] **Step 1: Copy the two verbatim files from upstream**

```bash
mkdir -p ssh
cp /tmp/hollow-dotfiles/ssh/config.crypto ssh/config.crypto
cp /tmp/hollow-dotfiles/ssh/.gitignore ssh/.gitignore
```

- [ ] **Step 2: Create the trimmed `ssh/config`**

Copy upstream's `ssh/config` with the Colima `Include` line removed:

```bash
grep -v '^Include %d/.config/colima/ssh_config$' /tmp/hollow-dotfiles/ssh/config > ssh/config
```

The resulting `ssh/config` must read exactly:

```ssh-config
Include %d/.config/ssh/config.crypto

HashKnownHosts no
StrictHostKeyChecking no

# Prevent connections from beind dropped
ServerAliveInterval 900
ServerAliveCountMax 0
```

(The `beind` typo is upstream's — keep it verbatim.)

- [ ] **Step 3: Add the Brewfile entry**

Edit `Brewfile`, inserting a new line between `brew "neovim"` and `brew "ripgrep"`:

```ruby
brew "neovim"
brew "openssh"
brew "ripgrep"
```

- [ ] **Step 4: Add the ssh `.zshrc` block**

In `zsh/.zshrc`, find the end of the rsync block:

```zsh
# rsync: fast incremental file transfer
# https://rsync.samba.org
zi auto wait for OMZP::rsync
```

Immediately after `zi auto wait for OMZP::rsync` (and the blank line that follows), insert the ssh block — **note the `alias ssu=…` line is intentionally omitted**:

```zsh
# ssh: secure shell
# https://www.openssh.com
mkdir -p "${HOME}/.ssh" "${XDG_CACHE_HOME}"/ssh
chmod 0700 "${HOME}/.ssh"

link ssh/config .ssh/config
chmod 0600 "${HOME}/.ssh/config"

# https://1password.community/discussion/comment/660153/#Comment_660153
if [[ -e "${HOME}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock" ]]; then
    export SSH_AUTH_SOCK="${HOME}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
else
    zi auto silent for OMZP::ssh-agent
fi
```

so the result reads `… zi auto wait for OMZP::rsync → [blank] → # ssh block → [blank] → # tmux …`.

- [ ] **Step 5: Verify files, subset, and syntax**

Run:
```bash
zsh -n zsh/.zshrc && echo "PARSE OK"
diff ssh/config.crypto /tmp/hollow-dotfiles/ssh/config.crypto && echo "CRYPTO IDENTICAL"
diff ssh/.gitignore   /tmp/hollow-dotfiles/ssh/.gitignore   && echo "GITIGNORE IDENTICAL"
diff <(grep -v 'colima/ssh_config' /tmp/hollow-dotfiles/ssh/config) ssh/config \
  && echo "CONFIG = UPSTREAM MINUS COLIMA"
# Every added ssh-block line (header through the closing `fi`) must exist upstream:
awk '/^# ssh: secure shell/{f=1} f{print} f&&/^fi$/{exit}' zsh/.zshrc > /tmp/our_ssh_block
while IFS= read -r line; do
  [ -z "$line" ] && continue
  grep -qF -- "$line" /tmp/hollow-dotfiles/zsh/.zshrc || { echo "NOT IN UPSTREAM: $line"; exit 1; }
done < /tmp/our_ssh_block
echo "SSH BLOCK SUBSET OK"
```
Expected: `PARSE OK`, `CRYPTO IDENTICAL`, `GITIGNORE IDENTICAL`, `CONFIG = UPSTREAM MINUS COLIMA`, `SSH BLOCK SUBSET OK` (all diffs empty).

- [ ] **Step 6: Commit**

```bash
git add Brewfile zsh/.zshrc ssh/config ssh/config.crypto ssh/.gitignore
git commit -m "Ring 5: add ssh (config files, brew, 1Password agent .zshrc block)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 3: Faithfulness + Brewfile audit

**Goal:** Confirm the whole ring is a clean subset — no Brewfile deviations, valid Brewfile, valid zsh, and the only `.zshrc`/config deviations are the two intended deletions.

**Files:**
- None (verification only)

**Acceptance Criteria:**
- [ ] `brew bundle list --file=./Brewfile --all` parses without error and lists `gnupg` and `openssh`.
- [ ] `comm -23` of this repo's `brew`/`cask` lines against upstream's is empty (no entry exists here that isn't upstream).
- [ ] `zsh -n zsh/.zshrc` exits 0.
- [ ] The only ssh-section line present upstream but absent here is `alias ssu=…`; the only `ssh/config` line removed is the Colima `Include`.

**Verify:** `bash` block in Step 1 below → ends with `AUDIT CLEAN`

**Steps:**

- [ ] **Step 1: Run the faithfulness audit**

```bash
set -e
# 1. Brewfile parses and includes the new entries
brew bundle list --file=./Brewfile --all | grep -qx gnupg
brew bundle list --file=./Brewfile --all | grep -qx openssh

# 2. No brew/cask deviation vs upstream (our lines ⊆ upstream lines)
ours=$(grep -E '^(brew|cask) ' Brewfile | sort -u)
theirs=$(grep -E '^(brew|cask) ' /tmp/hollow-dotfiles/Brewfile | sort -u)
dev=$(comm -23 <(printf '%s\n' "$ours") <(printf '%s\n' "$theirs"))
[ -z "$dev" ] || { echo "DEVIATIONS:"; echo "$dev"; exit 1; }

# 3. zsh syntax
zsh -n zsh/.zshrc

# 4. ssh/config differs from upstream by exactly the Colima Include line
diff <(grep -v 'colima/ssh_config' /tmp/hollow-dotfiles/ssh/config) ssh/config

echo "AUDIT CLEAN"
```
Expected: prints `AUDIT CLEAN` with no `DEVIATIONS` and no diff output.

- [ ] **Step 2: (Optional) Manual smoke test on a fresh shell**

After `brew bundle install`, open a new shell and confirm:
```bash
command -v gpg && command -v ssh                 # both resolve
ls -ld "${XDG_DATA_HOME}/gnupg"                   # exists, drwx------ (0700)
ls -l "${HOME}/.ssh/config"                       # symlink -> ~/.config/ssh/config
stat -f '%Lp' "${HOME}/.ssh/config"               # 600
ssh -G github.com | grep -i ciphers               # reflects config.crypto
```
With the 1Password SSH agent enabled, `echo $SSH_AUTH_SOCK` points at the 1Password socket and `ssh-add -l` lists 1Password-held keys.

(No commit — verification only.)

---

## Notes for the implementer

- **Order matters:** Task 0 must run first (later tasks `cp`/`diff` against `/tmp/hollow-dotfiles`). Tasks 1 and 2 are independent of each other but both edit `Brewfile` and `zsh/.zshrc` — run them sequentially to avoid edit conflicts. Task 3 runs last.
- **Byte-identical means byte-identical:** prefer `cp` from the upstream clone over hand-typing the long crypto algorithm lines.
- **Do not add** `age`, `pinentry-mac`, `sshp`, `zsh/assh`, `zsh/sshlive`, or the `ssu` alias — all intentionally out of scope (see spec).
