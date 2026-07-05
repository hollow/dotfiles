# Dotfiles update check design

## Goal

Add a daily, shell-only background check that notices when the dotfiles checkout is behind `origin/main` and tells the user to run `zup`.

The check must be notify-only. It must never pull, reset, rebase, run Homebrew, update plugins, or mutate the checkout. `zup` remains the explicit update command.

## Current context

- The dotfiles repo lives at `~/.config` and is `remerge/dotfiles`.
- `zup` is defined in `zsh/.zshrc` and currently starts with `git -C "${XDG_CONFIG_HOME}" pull --ff-only --quiet || :`.
- `zup` then runs Homebrew, uv, tmux, gcloud, and ZI update steps, and re-execs zsh unless `ZUP_NO_EXEC` is set.
- The repo has no existing LaunchAgent or background-update pattern.
- Existing tests cover `install.sh`; zsh behavior needs its own targeted shell tests or a small reusable test harness.

## Chosen approach

Use an async zsh startup check with cached state.

On interactive shell startup, zsh checks a timestamp file. If the last attempted check is less than 24 hours old, startup does no network work. If the check is stale, startup launches a detached background worker and returns immediately.

The worker fetches `origin main`, compares local `HEAD` with `origin/main`, and writes a small state file. Foreground startup code reads that state file and prints a short notice when the checkout is safely behind:

```text
dotfiles update available; run zup
```

This keeps shell startup responsive, avoids macOS-specific LaunchAgents, and avoids hidden mutation.

## Components

### `:dotfiles-update-notice`

Foreground reader called during interactive shell startup after base XDG directories exist.

Responsibilities:

- Read the cached state file.
- Print the update notice only when state is `behind`.
- Stay silent for `up-to-date`, `error`, missing state, or malformed state.

### `:dotfiles-update-check-start`

Foreground launcher called during interactive shell startup.

Responsibilities:

- Check the last-attempt timestamp.
- Skip when the last attempt was less than 24 hours ago.
- Start `:dotfiles-update-check-run` detached when a check is due.
- Produce no stdout/stderr during normal startup.

### `:dotfiles-update-check-run`

Background worker.

Responsibilities:

- Verify `XDG_CONFIG_HOME` is a git repo.
- Verify `origin/main` can be fetched.
- Compare `HEAD` and `origin/main`.
- Write state atomically.
- Write/update the last-attempt timestamp.
- Never mutate the checkout.

### `zup` integration

After `zup` runs its foreground `git pull --ff-only --quiet`, it should clear or refresh the cached update state so a stale `behind` notice disappears after a successful update.

## State files

Store checker state under the zsh state directory, using the existing XDG layout:

- `~/.local/state/zsh/dotfiles-update-check.last`
- `~/.local/state/zsh/dotfiles-update-check.state`

The state file is a single status token, one of:

- `behind`: `HEAD` is an ancestor of `origin/main`; `zup` should be able to fast-forward.
- `up-to-date`: `HEAD` equals `origin/main`.
- `error`: the checker could not establish a safe update state.

The foreground notice treats only `behind` as actionable.

## Data flow

1. Interactive shell starts and creates base XDG directories.
2. `:dotfiles-update-notice` reads the cached state and prints the notice if state is `behind`.
3. `:dotfiles-update-check-start` checks whether the daily interval has elapsed.
4. If due, `:dotfiles-update-check-start` launches `:dotfiles-update-check-run` detached with output redirected away from the terminal.
5. The worker fetches and writes state atomically.
6. A later shell startup shows the new state.
7. `zup` refreshes or clears the state after its foreground dotfiles pull.

The design intentionally does not require the background worker to print into the current terminal. Asynchronous output can interrupt commands and is harder to reason about than a cached notice on the next prompt/session.

## Failure handling

The checker must never block or break shell startup.

- Missing git repo: write `error` and stay silent.
- Missing `origin` or missing `origin/main`: write `error` and stay silent.
- Fetch failure/offline GitHub: write `error` and stay silent.
- Detached HEAD: write `error` and stay silent.
- Diverged checkout: write `error` and stay silent, because `zup` may not be able to resolve it with a fast-forward pull.
- Malformed state files: ignore them.
- Background worker stdout/stderr: redirect to `/dev/null`.

## Tests

Add targeted shell tests for the checker logic.

Use temporary git repositories to cover:

- Local checkout equals origin: state becomes `up-to-date`; no notice.
- Local checkout is one commit behind origin: state becomes `behind`; notice is printed.
- Local checkout diverged from origin: no misleading `behind` notice.
- Fetch failure or missing remote: no prompt noise; non-fatal state.
- Timestamp gate: repeated startup checks within 24 hours do not spawn another worker.
- `zup` state refresh/clear: stale `behind` state disappears after the foreground dotfiles pull succeeds.

Prefer testing pure comparison/state functions directly and smoke-testing the async launcher separately. This keeps tests deterministic while still covering startup behavior.

## Documentation

Update the `README.md` `zup` section to state:

- shells check daily in the background for dotfiles updates;
- the check is notify-only;
- when an update is available, the shell tells the user to run `zup`;
- only `zup` performs the actual dotfiles update and package/plugin updates.

## Non-goals

- No LaunchAgent.
- No macOS Notification Center integration.
- No automatic dotfiles pull from the background worker.
- No automatic full `zup` run.
- No package, plugin, Homebrew, uv, tmux, gcloud, or ZI update outside explicit `zup`.
