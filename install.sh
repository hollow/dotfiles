#!/bin/sh
# Remerge dotfiles installer.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/remerge/dotfiles/main/install.sh | sh
#
# Installs Apple Command Line Tools (for git) on macOS, clones this repo into
# ~/.config, links ~/.zshrc, then (macOS) installs Homebrew and the Brewfile and
# hands off via `zup` to update everything and start a fresh zsh; when run from a
# non-Ghostty terminal it then opens Ghostty so you land in the configured one.
# On non-macOS it just starts zsh and the shell bootstraps plugins/prompt on
# first launch.
set -eu

REPO_URL="https://github.com/remerge/dotfiles"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"

log() { printf '\033[1;34m==>\033[0m %s\n' "$1"; }
err() { printf '\033[1;31merror:\033[0m %s\n' "$1" >&2; }

# Ask a yes/no question on the controlling terminal. Returns success only on an
# explicit "yes". With no terminal (e.g. `curl ... | sh`, whose stdin is the
# pipe), we cannot prompt — so we answer "no" and destructive steps abort safely.
confirm() {
    # Need a usable controlling terminal to prompt. Open /dev/tty (not just test
    # for the node): the node can exist while the process has no controlling
    # terminal (background/CI), where opening fails — answer "no" cleanly.
    { : < /dev/tty; } 2>/dev/null || return 1
    printf '%s' "$1" > /dev/tty
    read -r _reply < /dev/tty || return 1
    case "$_reply" in
        [Yy] | [Yy][Ee][Ss]) return 0 ;;
        *) return 1 ;;
    esac
}

# True when the given remote URL refers to remerge/dotfiles, in any of the forms
# git prints (https, https with .git, ssh shorthand, ssh URL).
is_remerge_remote() {
    _url=${1%.git}
    _url=${_url%/}
    case "$_url" in
        https://github.com/remerge/dotfiles) return 0 ;;
        http://github.com/remerge/dotfiles) return 0 ;;
        git@github.com:remerge/dotfiles) return 0 ;;
        ssh://git@github.com/remerge/dotfiles) return 0 ;;
        *) return 1 ;;
    esac
}

# Point local main at origin/main and track it, without touching the working
# tree. Plumbing only — deliberately avoids `git checkout`/`git switch`.
# Precondition: the caller must have fetched origin/main first.
ensure_main_branch() {
    _dir=$1
    git -C "$_dir" symbolic-ref HEAD refs/heads/main
    git -C "$_dir" update-ref refs/heads/main refs/remotes/origin/main
    git -C "$_dir" branch --set-upstream-to=origin/main main > /dev/null 2>&1 || true
}

# Fetch origin/main and force the working tree to match it, after showing what
# will change and confirming twice. Untracked files that are not in the repo
# (e.g. git/local, mise/age.txt) are preserved. Aborts (exit 1) if the user
# declines or there is no terminal to confirm on.
restore_dotfiles() {
    _dir=$1
    if ! git -C "$_dir" fetch -q origin main; then
        err "Could not fetch from origin for $_dir. Check your network/credentials, then re-run."
        exit 1
    fi

    if git -C "$_dir" diff --quiet origin/main 2> /dev/null; then
        log "$_dir is already up to date with remerge/dotfiles."
        ensure_main_branch "$_dir"
        return 0
    fi

    log "These files in $_dir will be reset to match remerge/dotfiles:"
    git -C "$_dir" --no-pager diff --stat origin/main

    if confirm "Show the full diff first? [y/N] "; then
        git -C "$_dir" --no-pager diff origin/main || true
    fi

    if ! confirm "Discard these local changes and restore $_dir to remerge/dotfiles? [y/N] "; then
        err "Left $_dir untouched. To restore it manually later, run:"
        err "  git -C $_dir restore --source=origin/main --staged --worktree -- :/"
        exit 1
    fi

    git -C "$_dir" restore --source=origin/main --staged --worktree -- :/
    ensure_main_branch "$_dir"
    log "Restored $_dir to match remerge/dotfiles."
}

# Put remerge/dotfiles into $1 (the config dir), adopting whatever is already
# there: an existing repo whose origin is remerge/dotfiles is just refreshed; a
# repo pointing elsewhere (a fork) is offered for replacement; a non-empty plain
# directory is adopted in place; an empty/missing directory is cloned.
place_dotfiles() {
    _dir=$1
    _repo=$2

    if [ -e "$_dir/.git" ]; then
        _origin=$(git -C "$_dir" remote get-url origin 2> /dev/null || true)
        if [ -n "$_origin" ] && is_remerge_remote "$_origin"; then
            log "Dotfiles already present in $_dir (remerge/dotfiles)."
        else
            if [ -n "$_origin" ]; then
                log "$_dir is a git repo for $_origin,"
                log "not remerge/dotfiles."
            else
                log "$_dir is a git repo with no 'origin' remote."
            fi
            if ! confirm "Replace it with remerge/dotfiles? [y/N] "; then
                err "Left $_dir untouched. To migrate it manually later, run:"
                err "  git -C $_dir remote set-url origin $_repo"
                err "  git -C $_dir fetch origin main"
                err "  git -C $_dir restore --source=origin/main --staged --worktree -- :/"
                exit 1
            fi
            if git -C "$_dir" remote get-url origin > /dev/null 2>&1; then
                git -C "$_dir" remote set-url origin "$_repo"
            else
                git -C "$_dir" remote add origin "$_repo"
            fi
        fi
        restore_dotfiles "$_dir"
    elif [ -d "$_dir" ] && [ -n "$(find "$_dir" -mindepth 1 -maxdepth 1 2> /dev/null | head -n 1)" ]; then
        log "$_dir exists and is not empty; adopting the dotfiles in place..."
        git -C "$_dir" init -q
        git -C "$_dir" remote add origin "$_repo" 2> /dev/null \
            || git -C "$_dir" remote set-url origin "$_repo"
        restore_dotfiles "$_dir"
    else
        log "Cloning dotfiles into $_dir..."
        git clone -q "$_repo" "$_dir"
    fi
}

# When sourced for testing (DOTFILES_INSTALL_LIB=1), stop here so the helper
# functions above can be exercised without running the installer.
if [ "${DOTFILES_INSTALL_LIB:-0}" = 1 ]; then
    return 0
fi

os="$(uname -s)"

# 1. Ensure git is available (macOS ships it via the Command Line Tools).
if [ "$os" = "Darwin" ] && ! xcode-select -p >/dev/null 2>&1; then
    log "Installing Xcode Command Line Tools (a dialog will open)..."
    xcode-select --install || true
    log "Waiting for the Command Line Tools to finish installing..."
    waited=0
    while ! { xcode-select -p >/dev/null 2>&1 && command -v git >/dev/null 2>&1; }; do
        waited=$((waited + 5))
        if [ "$waited" -ge 1800 ]; then
            err "Timed out waiting for the Command Line Tools. Install them, then re-run this script."
            exit 1
        fi
        sleep 5
    done
fi

if ! command -v git >/dev/null 2>&1; then
    err "git is required but was not found. Install git, then re-run this script."
    exit 1
fi

# 2. Place the dotfiles in ~/.config, adopting any existing setup.
place_dotfiles "$CONFIG_DIR" "$REPO_URL"

# 3. Link the zsh entrypoint.
log "Linking ~/.zshrc -> $CONFIG_DIR/zsh/.zshrc"
ln -nfs "$CONFIG_DIR/zsh/.zshrc" "$HOME/.zshrc"

# Seed a per-user git identity. Prompt interactively when we have a terminal;
# otherwise fall back to copying the example for the user to edit later.
if [ ! -f "$CONFIG_DIR/git/local" ]; then
    if [ -e /dev/tty ]; then
        log "Setting up your Git identity (used to author your commits)."
        printf 'Full name (e.g. Jane Doe): ' > /dev/tty
        read -r git_name < /dev/tty || git_name=""
        printf 'Email (e.g. jane@remerge.io): ' > /dev/tty
        read -r git_email < /dev/tty || git_email=""
        if [ -n "$git_name" ] && [ -n "$git_email" ]; then
            printf '[user]\n\tname = %s\n\temail = %s\n' "$git_name" "$git_email" > "$CONFIG_DIR/git/local"
            log "Saved your Git identity to $CONFIG_DIR/git/local"
        else
            log "Skipped (empty input). Edit $CONFIG_DIR/git/local later to set your name/email."
            [ -f "$CONFIG_DIR/git/local.example" ] && cp "$CONFIG_DIR/git/local.example" "$CONFIG_DIR/git/local"
        fi
    elif [ -f "$CONFIG_DIR/git/local.example" ]; then
        log "Creating git identity file $CONFIG_DIR/git/local (edit it with your name/email)"
        cp "$CONFIG_DIR/git/local.example" "$CONFIG_DIR/git/local"
    fi
fi

# 4. Provision (macOS) and hand off to a fresh interactive zsh.
if [ "$os" != "Darwin" ]; then
    log "Linux detected (best-effort): Homebrew and starship will NOT auto-install."
    log "See the README for manual steps: $REPO_URL"
fi

if [ -e /dev/tty ]; then
    if [ "$os" = "Darwin" ] && [ "${TERM_PROGRAM:-}" != "ghostty" ]; then
        # Run from a non-Ghostty terminal (e.g. the stock Terminal.app on a
        # fresh Mac): update/provision here — this is also where the Brewfile
        # installs Ghostty itself — then open Ghostty so the user lands in the
        # configured terminal. Can't `exec`: we must return here to open it.
        # `|| true` so a zup hiccup still lets us hand off if Ghostty installed.
        zsh -ic zup </dev/tty || true
        if [ -d /Applications/Ghostty.app ]; then
            log "Opening Ghostty..."
            open -a Ghostty
        else
            log "Ghostty isn't installed; staying in this terminal."
        fi
    else
        # Already in Ghostty (or non-macOS): update in place and stay here.
        exec zsh -ic zup </dev/tty
    fi
else
    log "Open a new terminal window to finish setup (zsh bootstraps on first launch)."
fi
