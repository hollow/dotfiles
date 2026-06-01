# Remerge dotfiles — Ring 5 (ssh, gpg) design

**Date:** 2026-06-01
**Status:** Approved (design); ready for implementation planning
**Repo:** <https://github.com/remerge/dotfiles>
**Builds on:** Rings 0–4 (merged) — see
`docs/superpowers/specs/2026-05-31-zsh-dotfiles-ring4-design.md`
**Upstream pin:** `hollow/dotfiles@main` at commit `5fd2f15`

## Goal

Port upstream's self-contained **`ssh`** and **`gnupg`** sections, staying a
faithful **subset** of <https://github.com/hollow/dotfiles>: a `diff` against
upstream shows only deletions and the previously-trimmed files.

This ring is the explicit home for the **1Password SSH-agent block** that Ring 4
deferred ("the `SSH_AUTH_SOCK` → 1Password-agent export is tangled inside
upstream's `ssh` section … Deferred to a future `ssh` ring").

## Scope (decided)

In scope:

- **gnupg**: `brew "gnupg"` plus the 5-line `.zshrc` block (`GPG_TTY`,
  `GNUPGHOME`, `mkdir`/`chmod`, `OMZP::gpg-agent`). No vendored config —
  `GNUPGHOME` is runtime state under `${XDG_DATA_HOME}/gnupg`.
- **ssh**: `brew "openssh"`, the vendored `ssh/config`, `ssh/config.crypto`, and
  `ssh/.gitignore`, plus the ssh `.zshrc` block — the `~/.ssh` setup,
  `link ssh/config`, and the **1Password agent-sock → `OMZP::ssh-agent`
  fallback**.

Out of scope / deferred:

- **`sshp` + `assh`** (parallel-ssh tooling): deferred. Upstream's `assh` helper
  calls `ah`, which belongs to upstream's un-ported Ansible tooling, so `assh`
  would be a dead command here. The `# sshp:` `.zshrc` block and the `zsh/assh`
  script are both omitted.
- **`ssu` alias + `zsh/sshlive`**: dropped at the user's request. Removing the
  single `alias ssu=…` line keeps the ssh block a strict line-subset and means
  no new helper script is vendored.
- **`age`**: upstream has `brew "age"`, but it is not part of the `ssh`/`gnupg`
  sections, so it is left out (adding it would be unrelated scope).
- The **`X` alias** (upstream's "misc other aliases", not the ssh section).

## Faithfulness principle (carried over)

Every kept line stays byte-identical to upstream. `zsh/.zshrc` remains a strict
line-subset: only upstream lines, re-inserted at their original relative
positions. Ring 5 introduces **two deletions** consistent with the subset
principle:

1. the `alias ssu=…` line is dropped from the ssh `.zshrc` block (user request);
2. the `Include %d/.config/colima/ssh_config` line is dropped from `ssh/config`
   because Colima is not ported to this repo.

Both `gnupg` and `openssh` exist in upstream's `Brewfile` at the pinned commit —
**no Brewfile deviations**.

## File inventory

### Modify

- `Brewfile` — add `brew "gnupg"` and `brew "openssh"`.
- `zsh/.zshrc` — add the **gnupg** and **ssh** blocks (strict subset; see below).

### Create — vendored from `hollow/dotfiles@5fd2f15`

- `ssh/config` — byte-identical **except** the trimmed Colima `Include` line.
- `ssh/config.crypto` — byte-identical (Fedora "FUTURE" crypto policy:
  `Ciphers`/`MACs`/`KexAlgorithms`/`PubkeyAcceptedAlgorithms`/etc.).
- `ssh/.gitignore` — byte-identical (`config.local`).

### Not added

- **gnupg** needs no vendored config (`GNUPGHOME` is runtime state, created and
  `chmod 0700`'d by the `.zshrc` block).
- **`zsh/sshlive`** and **`zsh/assh`** (deferred/dropped, see Scope).
- No `pinentry-mac`: Homebrew's `gnupg` formula already pulls a `pinentry`
  dependency, and upstream adds no `pinentry-mac`, so adding one would be a
  deviation.

## Path mapping

The repo lives at `~/.config`, so vendored directories map directly:

- `ssh/config` → linked to `~/.ssh/config` by the `.zshrc` block
  (`link ssh/config .ssh/config`), then `chmod 0600`.
- `ssh/config.crypto` → `~/.config/ssh/config.crypto`, pulled in by the
  `Include %d/.config/ssh/config.crypto` line inside `~/.ssh/config` (`%d` is the
  user's home directory).
- `ssh/.gitignore` → `~/.config/ssh/.gitignore`; keeps a user's private
  `config.local` out of git while leaving the tracked configs in place.
- `GNUPGHOME` → `~/.local/share/gnupg` (`${XDG_DATA_HOME}/gnupg`), created at
  shell startup; nothing tracked in the repo.

## `zsh/.zshrc` additions

Both blocks are byte-identical to upstream (modulo the dropped `ssu` alias) and
inserted preserving upstream's relative order.

**gnupg** — inserted between the existing `git` section (immediately after
`alias s="git st ."`) and the existing `# glamour/glow` block. Upstream order is
`git → gnupg → … → glamour/glow`:

```zsh
# gnupg: GNU privacy guard
# https://gnupg.org/
export GPG_TTY="${TTY}"
export GNUPGHOME="${XDG_DATA_HOME}/gnupg"
mkdir -p "${GNUPGHOME}"
chmod 0700 "${GNUPGHOME}"
zi auto wait for OMZP::gpg-agent
```

`GPG_TTY` lets `gpg` prompt for passphrases on the controlling terminal;
`GNUPGHOME` relocates GnuPG's state under XDG; the directory is created and
locked to `0700`; `OMZP::gpg-agent` is oh-my-zsh's gpg-agent plugin, loaded lazily
via `zi auto`.

**ssh** — inserted between the existing `rsync` block (immediately after
`zi auto wait for OMZP::rsync`) and the existing `# tmux` block. Upstream order is
`rsync → … → ssh → … → tmux`:

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

The block creates and secures `~/.ssh` (and the `${XDG_CACHE_HOME}/ssh` cache
dir), links the vendored `ssh/config` into place at `0600`, and wires SSH key
auth to the **1Password SSH agent** when its socket is present — otherwise
falling back to oh-my-zsh's `ssh-agent` plugin. The `link`/`has` helpers already
exist from prior rings; this block adds no new script.

## `ssh/config` (trimmed)

Byte-identical to upstream except the second `Include` line (Colima) is removed,
since Colima is not part of this repo:

```ssh-config
Include %d/.config/ssh/config.crypto

HashKnownHosts no
StrictHostKeyChecking no

# Prevent connections from beind dropped
ServerAliveInterval 900
ServerAliveCountMax 0
```

(The `beind` typo is upstream's and is preserved verbatim.)

## `Brewfile` additions

- **Brews:** add `gnupg` (alphabetical: between `gnu-time` and `grep`) and
  `openssh` (between `neovim` and `ripgrep`).
- No cask changes.

Both entries exist in upstream's `Brewfile` at `5fd2f15` — **no deviations**.

## Verification

- **Vendored verbatim files** (`ssh/config.crypto`, `ssh/.gitignore`) → `diff`
  byte-identical against `hollow/dotfiles@5fd2f15`.
- **`ssh/config`** → identical to upstream after removing exactly one line
  (the Colima `Include`); every remaining line is byte-identical.
- **`zsh/.zshrc`** → strict line-subset: every non-blank added line exists in
  upstream's `.zshrc` (the `ssu` alias is the only ssh-section line omitted).
  `zsh -n zsh/.zshrc` passes.
- **`Brewfile`** → `gnupg` and `openssh` both exist in upstream's `Brewfile`;
  `brew bundle list --file=./Brewfile --all` parses.
- **Faithfulness audit:** `comm -23` of our `brew`/`cask` lines against
  upstream's is empty (no deviations).
- **Manual smoke test:** on a fresh shell both blocks load without error;
  `gpg` and `ssh` resolve; `${GNUPGHOME}` (`~/.local/share/gnupg`) exists and is
  `0700`; `~/.ssh/config` is a link to the repo's `ssh/config` and is `0600`;
  `ssh -G somehost` resolves and reflects the `config.crypto` algorithms; with
  1Password's SSH agent enabled, `SSH_AUTH_SOCK` points at its socket and
  `ssh-add -l` lists 1Password-held keys.

## Acceptance criteria

- `gnupg` and `openssh` install via `brew bundle`, and the gnupg and ssh
  `.zshrc` blocks load without error on a fresh shell.
- The vendored `ssh/config.crypto` and `ssh/.gitignore` are byte-identical to
  upstream at `5fd2f15`; `ssh/config` differs only by the removed Colima line.
- The faithfulness checks above pass with **no** Brewfile deviations.
- `LICENSE` and all prior-ring files remain unchanged except the `Brewfile` and
  `zsh/.zshrc` edits described here.
