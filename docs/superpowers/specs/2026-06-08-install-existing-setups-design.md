# install.sh — robust handling of existing `~/.config` setups

**Date:** 2026-06-08
**Status:** Approved (design); ready for implementation planning
**Repo:** <https://github.com/remerge/dotfiles>
**Motivation:** IT-8323 / the onboarding session with Marwa
(`remerge.slack.com` DM, 2026-06-05) where the installer failed to migrate an
existing setup.

## Goal

Make `install.sh` migrate an **existing `~/.config`** onto `remerge/dotfiles`
cleanly and interactively, instead of either silently doing the wrong thing or
aborting and forcing a manual recovery dance.

## Background — why the current script fails

`curl -fsSL …/install.sh | sh` runs with the script piped to `sh`, so stdin is
the pipe, not a terminal. Interactive prompts therefore read from `/dev/tty`
and are guarded by `[ -e /dev/tty ]` (see the existing Git-identity block).

Step 2 of the current script ("Place the dotfiles in `~/.config`") has three
branches:

1. **`~/.config/.git` exists** → `git pull --ff-only`. This pulls from whatever
   `origin` points at. If the user has a *fork* checked out (the common case
   for people who installed from a personal dotfiles repo earlier), the pull
   succeeds against the **fork** and the repo is never switched to
   `remerge/dotfiles`.
2. **dir exists, non-empty, no `.git`** → `git init` + add remote + fetch +
   `git checkout -B main origin/main` **without `-f`**. This aborts the moment
   any untracked working-tree file (Brewfile, zshrc, …) would be overwritten.
3. **otherwise** → `git clone`.

In the onboarding session this produced: branch 1 silently kept the fork;
removing `.git` by hand dropped into branch 2, which aborted on untracked
conflicts; recovery then required a long manual sequence of
`git reset --soft`, `git reset HEAD`, `git checkout .`, and `rm -rf` of stale
files.

## Key insight

The only operation that reliably makes the working tree (Brewfile, zshrc, …)
match the repository is a **`git restore` from `origin/main`, followed by a
plumbing ref move** — never `git checkout`:

```sh
git fetch -q origin main
# Force index + working tree to match origin/main, discarding local edits and
# overwriting conflicting files; files NOT in the repo are left untouched:
git restore --source=origin/main --staged --worktree -- :/
# Point local main at origin/main without any further working-tree change:
git symbolic-ref HEAD refs/heads/main
git update-ref refs/heads/main refs/remotes/origin/main
git branch --set-upstream-to=origin/main main >/dev/null 2>&1 || true
```

`git restore --source=origin/main --staged --worktree -- :/` rewrites every
tracked file to the repo's version, **deletes** files the local checkout tracked
but the repo no longer has, and **overwrites untracked files that conflict**
(e.g. a pre-existing `Brewfile`) — crucially **without** the
"untracked working tree files would be overwritten" abort that `git checkout`
raises (the exact failure in the session). Untracked files that are **not** in
the repo (e.g. `git/local`, `mise/age.txt`) are left untouched. The subsequent
`symbolic-ref` + `update-ref` set the local `main` branch to `origin/main`
using plumbing, so the branch pointer moves without `git checkout`/`git switch`
and without re-touching the working tree. Verified against diverged-fork,
untracked-conflict, fresh-`init`, and already-clean checkouts.

This single primitive serves every "adopt/restore" path, so the three
special-cased
branches collapse into one decision flow plus one shared restore step.

## Decisions (locked)

| Decision | Choice |
| --- | --- |
| **Trigger** | Smart by remote. If `origin` is already `remerge/dotfiles`, skip the replace prompt and go straight to the diff + confirm restore. If `origin` is a different repo (fork/personal), prompt to replace first, then restore. |
| **Replace mechanism** | Re-point in place: `git remote set-url origin <REPO_URL>` on the existing `.git`. No `rm -rf .git`, no re-clone. Preserves untracked files and avoids the re-init path that aborted in the session. |
| **No-`.git` branch** | Fixed too: `git init` + add origin, then the same confirm + `git restore`. |
| **No TTY** | Abort safely. Any destructive step that needs a prompt aborts (printing the manual commands) when there is no `/dev/tty`. Never discards files unattended. |

## Design

### New helpers (placed near the existing `log`/`err`)

- `confirm "<prompt>"` — prints `<prompt>` to `/dev/tty`, reads a line, returns
  success only on `y`/`Y`(`es`). Returns **non-zero when there is no
  `/dev/tty`**, so every prompt degrades to "abort safely" automatically when
  non-interactive. Default is **No** (empty input → No).
- `is_remerge_remote "<url>"` — returns success when `<url>` refers to
  `remerge/dotfiles`. Normalizes a trailing `.git` and matches both forms:
  - `https://github.com/remerge/dotfiles[.git]`
  - `git@github.com:remerge/dotfiles[.git]`

### Step 2 control flow (replaces current lines ~41–64)

**Case A — `~/.config/.git` exists.** Read `origin`'s URL (`git -C … remote
get-url origin`, tolerating a missing `origin`).

- **Foreign remote** (not `is_remerge_remote`): prompt once —

  > `~/.config is a git repo for <url>, not remerge/dotfiles.`
  > `Replace it with remerge/dotfiles? [y/N]`

  - **No / no TTY** → abort, printing the manual commands and exit non-zero.
  - **Yes** → `git remote set-url origin <REPO_URL>` (add `origin` if it was
    missing), then fall through to the **restore step**.
- **Already `remerge/dotfiles`** → skip the replace prompt, fall through to the
  **restore step**.

**Case B — `~/.config` exists, non-empty, no `.git`.** `git init -q`, add
`origin` → `REPO_URL`, then fall through to the **restore step**.

**Case C — `~/.config` absent or empty.** `git clone` as today. No prompts, no
diff (nothing pre-existing to protect).

### Shared restore step (Cases A and B)

1. `git fetch -q origin main`.
2. **Up-to-date short-circuit:** if `HEAD` already resolves to `origin/main`
   **and** `git diff --quiet origin/main` (no working-tree differences), print
   "already up to date" and skip to step 3 of the installer (symlink). No
   prompt.
3. Otherwise, show the affected files:

   ```sh
   git --no-pager diff --stat origin/main
   ```

4. **Optional diff:** `confirm "Show the full diff first? [y/N]"` → on Yes,
   `git --no-pager diff origin/main > /dev/tty`.
5. **Second confirm (the "ask again" step):**

   > `Discard these local changes and restore ~/.config to remerge/dotfiles? [y/N]`

   - **Yes** → run the restore primitive: `git restore --source=origin/main
     --staged --worktree -- :/`, then `git symbolic-ref HEAD refs/heads/main`
     and `git update-ref refs/heads/main refs/remotes/origin/main`
     (+ `git branch --set-upstream-to=origin/main main`). No `git checkout`.
   - **No / no TTY** → abort, printing the manual commands and exit non-zero.

Steps 3 (symlink `~/.zshrc`), the Git-identity seeding, and step 4 (hand off to
`zsh`) are unchanged and run after the dotfiles are in place.

## Behavior on the onboarding scenario

1. `~/.config/.git` exists and points at the fork → **Case A, foreign**.
2. One prompt: replace the fork with `remerge/dotfiles`? → Yes →
   `origin` re-pointed.
3. `git fetch`; working tree differs → file list shown; optional full diff.
4. Second prompt: discard local changes and restore? → Yes →
   `git restore --source=origin/main --staged --worktree -- :/` + the plumbing
   ref move.
5. Result: every tracked file matches `remerge/dotfiles`; `git/local` and
   `mise/age.txt` survive because they are untracked and not in the repo tree.
   No `rm -rf .git`, no manual `reset`/`checkout` recovery.

## Scope and non-goals

- **In scope:** step 2 of `install.sh` only — the `confirm`/`is_remerge_remote`
  helpers and the rewritten placement flow; aborting safely with printed manual
  commands when non-interactive.
- **Out of scope:** the `zup` update path; the Git-identity block; Linux
  best-effort handling; README copy (a follow-up doc tweak may be worthwhile but
  is not part of this change).
- **Accepted behavior change:** an already-`remerge/dotfiles` working copy
  with **local tracked edits** now gets the diff + confirm force-restore
  instead of the old `git pull --ff-only`. This is strictly more robust (the
  old path failed on any local edit) and matches "make the files up to date
  with the repository", at the cost of discarding local tracked edits — always
  behind the confirm, never silently.

## Testing approach

Because the script is destructive and TTY-sensitive, validate it with a
disposable `HOME` and a fake `/dev/tty`-free invocation:

- **Foreign repo, confirmed:** seed `$CONFIG_DIR` from a throwaway "fork" repo
  with local edits; run with answers piped via a stubbed `confirm`; assert
  `origin` is re-pointed and tracked files match `origin/main` while a planted
  untracked file (e.g. `mise/age.txt`) survives.
- **Foreign repo, declined / no TTY:** assert the script aborts non-zero and
  leaves `~/.config` untouched.
- **Already remerge, clean:** assert the up-to-date short-circuit (no prompt,
  no restore).
- **Already remerge, local edits:** assert diff shown + restore on confirm.
- **No `.git`, non-empty:** assert init + restore on confirm; conflicting
  untracked files overwritten, non-repo untracked files preserved.
- **Empty / absent:** assert plain `git clone`, no prompts.

Exact harness (shell stubs vs. a tiny BATS-style runner vs. manual smoketest in
a scratch dir) is a planning decision.
