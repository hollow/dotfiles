# install.sh fresh-provision (brew bundle before first :brew-update) design

**Date:** 2026-06-09
**Status:** Approved (design); ready for implementation planning
**Repo:** <https://github.com/remerge/dotfiles>
**Builds on:** the `install.sh` existing-setup work (IT-8323, PRs #20–#23)

## Problem

During a live install test (a teammate running `curl -fsSL …/install.sh | sh`,
then `zup`), `git -C ~/.config status` afterwards showed **`modified: Brewfile`**.
Root cause: `zup` → `:brew-update` (in `zsh/.zshrc`) runs

```zsh
if ! has brew; then
    # install Homebrew, no dump
else
    brew bundle dump -f      # <-- rewrites the Brewfile from INSTALLED packages
fi
brew update; brew upgrade; brew bundle install; …
```

On a machine that **already has Homebrew** (common for developers), the first
`zup` takes the `else` branch and `brew bundle dump -f` **overwrites the
committed Brewfile with whatever is currently installed** — which, on a fresh
checkout, does *not* include the dotfiles' packages. The Brewfile is clobbered
(shows modified) and the subsequent `brew bundle install` then installs only
that reduced set → "a lot of missing packages".

`:brew-update` lives in `zsh/.zshrc`, which the fork keeps **byte-identical to
upstream `hollow/dotfiles`**; `install.sh` is **fork-only** (absent upstream).
So the fix belongs in `install.sh`, not in `.zshrc`.

## Goal

Make `install.sh` **fully provision** a machine before handing off: ensure
Homebrew is present, install the committed Brewfile, then run `zup` to update
everything (incl. zi plugins) and land in a ready shell. Because the committed
Brewfile is installed *before* any `:brew-update` dump runs, the dump can no
longer drop packages.

## Decided behavior

- **Full provision** in `install.sh` (install Homebrew if missing + `brew bundle
  install` + `zup`).
- **`zsh/.zshrc` / `:brew-update` untouched** — no upstream deviation; the dump
  stays as upstream's personal-sync behavior.
- **Apple-Silicon only** (`/opt/homebrew`), consistent with the fork's
  no-Intel-Mac policy.
- **macOS + usable terminal only**; non-macOS and no-tty keep today's behavior.

## Design

### New function: `provision_macos` (extracted above the test-lib guard)

Placed with the other helpers, before the `DOTFILES_INSTALL_LIB` early-return so
the test harness can source and exercise it. Signature: `provision_macos <dir>`
where `<dir>` is the config dir holding the `Brewfile`.

```sh
# Ensure Homebrew is installed and the committed Brewfile is fully installed,
# so the first `:brew-update` dump (later, via zup) cannot drop packages.
# Apple-Silicon (/opt/homebrew) only. A bundle failure is warned, not fatal.
provision_macos() {
    _dir=$1
    if ! command -v brew > /dev/null 2>&1; then
        if [ ! -x /opt/homebrew/bin/brew ]; then
            log "Installing Homebrew..."
            NONINTERACTIVE=1 /bin/bash -c \
                "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" \
                < /dev/tty
        fi
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi

    log "Installing packages from the Brewfile (this can take a while)..."
    if ! HOMEBREW_BUNDLE_FILE="$_dir/Brewfile" HOMEBREW_BUNDLE_NO_LOCK=1 \
        brew bundle install; then
        err "Some Brewfile packages failed to install; continuing."
        err "Re-run 'zup' later to retry."
    fi
}
```

Notes:
- `command -v brew` already on PATH → skip the Homebrew install entirely. Not on
  PATH but `/opt/homebrew/bin/brew` exists (installed, not yet shell-loaded) →
  just `eval shellenv`. Neither → install, then `eval shellenv`.
- `< /dev/tty` gives the Homebrew installer's `sudo` prompt the terminal even
  though `install.sh`'s own stdin is the `curl` pipe. `NONINTERACTIVE=1` skips
  its "press RETURN" prompt.
- `HOMEBREW_BUNDLE_NO_LOCK=1` matches `:brew-init`, so no untracked
  `Brewfile.lock.json` is created. `HOMEBREW_BUNDLE_FILE` points at the committed
  Brewfile explicitly (don't rely on the not-yet-loaded shell env).
- Bundle failure is **non-fatal** (logged): a working shell beats an aborted
  onboarding. `install.sh` runs under `set -eu`, so the `if ! …; then` form is
  required to keep a failure from aborting.

### Handoff change (the script's tail)

Today the tail is `exec zsh -i </dev/tty` (or a print when there's no tty). New
tail (the Linux notice is unchanged):

```sh
if [ -e /dev/tty ]; then
    if [ "$os" = "Darwin" ]; then
        provision_macos "$CONFIG_DIR"
        log "Provisioning done. Updating everything via zup and starting zsh..."
        exec zsh -ic zup < /dev/tty
    else
        log "Starting zsh..."
        exec zsh -i </dev/tty
    fi
else
    log "Open a new terminal window to finish setup (zsh bootstraps on first launch)."
fi
```

`exec zsh -ic zup` sources `.zshrc` (interactive → `zzinit` loads `zi`), runs
`zup` — `:brew-update` (now-safe dump + `brew update`/`upgrade` + `brew bundle
install` + cleanup), the `uv`/`tmux`/`gcloud` updates, `zi self-update`, `zi
update --all` — and `zup` ends in its own `exec zsh`, landing the user in a
fully-updated interactive shell. (This is a single `exec`, deliberately not the
`zup …|| true; exec zsh` shape floated during design, which would spawn a second
shell on the success path because `zup` already execs.)

**`zup` failure path:** if `zup` aborts before its `exec zsh` (e.g. a flaky
network `zi update`), `exec zsh -ic zup` exits and control returns to the
caller's shell. This is recoverable and non-catastrophic: `provision_macos`
already installed Homebrew + the full Brewfile and `~/.zshrc` is linked, so
opening a new terminal yields a working dotfiles shell and `zup` can be re-run.

The first-run comment near the top of `install.sh` ("first launch installs
Homebrew, plugins, and the prompt") becomes accurate and should be left/clarified
accordingly.

## Why this fixes it

On a truly fresh Mac: Homebrew is installed clean, `brew bundle install`
installs exactly the committed Brewfile, then `zup`'s `:brew-update` dump
reproduces that same Brewfile → `git -C ~/.config status` is **clean**, no
missing packages.

## Deviations / known limitations

1. **Brew-already-present machines may still show a modified Brewfile.** If the
   machine had Homebrew with packages *beyond* the committed Brewfile,
   `:brew-update`'s kept `brew bundle dump -f` records those extras → the
   Brewfile shows modified there. This is inherent to keeping the upstream dump
   (the deliberate Q2 choice) and does **not** cause missing packages. The clean
   case is the real onboarding target (a fresh company Mac).
2. **`zsh/.zshrc` is unchanged** — byte-identical to upstream; the fix is
   `install.sh`-only.
3. **Apple-Silicon only** — `/opt/homebrew` hardcoded, no Intel `/usr/local`
   fallback, consistent with the fork's existing policy.

## Testing

`tests/install_test.sh` sources `install.sh` in library mode
(`DOTFILES_INSTALL_LIB=1`) and exercises functions in isolation. Add a
`provision_macos` scenario block that PATH-shims fakes and records invocations:

- A fake `brew` on `PATH` that appends its args + the relevant env
  (`HOMEBREW_BUNDLE_FILE`, `HOMEBREW_BUNDLE_NO_LOCK`) to a log file, and a fake
  `curl` that must **not** be called when brew is present.
- **Case A — brew present:** `command -v brew` succeeds → assert the Homebrew
  installer (`curl`) was **not** invoked, and `brew bundle install` was invoked
  with `HOMEBREW_BUNDLE_FILE=<dir>/Brewfile` and `HOMEBREW_BUNDLE_NO_LOCK=1`.
- **Case B — bundle failure non-fatal:** fake `brew bundle` returns non-zero →
  assert `provision_macos` still returns 0 (does not abort).

The real, end-to-end fresh install (Homebrew install + `exec zsh -ic zup`) is
verified manually (the screen-share install test), as it mutates the machine and
needs a tty; the unit test covers the control-flow/contract only. Document the
manual step rather than silently skipping it.

## File inventory

### Create
- `docs/superpowers/specs/2026-06-09-install-fresh-provision-design.md` (this file)
- `docs/superpowers/plans/2026-06-09-install-fresh-provision.md` (+ `.tasks.json`)

### Modify
- `install.sh` — add `provision_macos` (above the lib guard); change the tail to
  call it and hand off via `exec zsh -ic zup` on macOS+tty.
- `tests/install_test.sh` — add the `provision_macos` scenario block.

## Verification

- `sh tests/install_test.sh` → `ALL PASS` (existing scenarios + the new
  `provision_macos` cases).
- `sh -n install.sh` and `sh -n tests/install_test.sh` parse clean.
- `shellcheck install.sh tests/install_test.sh` clean (if `shellcheck` available).
- Manual (screen-share, fresh-ish Mac): `curl … | sh` finishes with Homebrew +
  all Brewfile packages installed, `zup` updates everything, and on a fresh Mac
  `git -C ~/.config status` shows a **clean** Brewfile.

## Acceptance criteria

- `provision_macos` exists above the `DOTFILES_INSTALL_LIB` guard; installs
  Homebrew only when absent (Apple-Silicon path), then runs `brew bundle install`
  with `HOMEBREW_BUNDLE_FILE`/`HOMEBREW_BUNDLE_NO_LOCK` set; bundle failure is
  non-fatal.
- On macOS + tty, the tail calls `provision_macos "$CONFIG_DIR"` then
  `exec zsh -ic zup </dev/tty`. Non-macOS and no-tty behavior is unchanged.
- `zsh/.zshrc` is **not** modified.
- `tests/install_test.sh` gains the two `provision_macos` cases and still ends
  `ALL PASS`; `sh -n` parses both scripts.
- The only documented deviations are the three listed above.
