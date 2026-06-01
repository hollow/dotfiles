#!/bin/sh
# Remerge dotfiles installer.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/remerge/dotfiles/main/install.sh | sh
#
# Installs Apple Command Line Tools (for git) on macOS, clones this repo into
# ~/.config, links ~/.zshrc, and starts a fresh zsh. The shell finishes the
# bootstrap on first launch (Homebrew, plugins, prompt).
set -eu

REPO_URL="https://github.com/remerge/dotfiles"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"

log() { printf '\033[1;34m==>\033[0m %s\n' "$1"; }
err() { printf '\033[1;31merror:\033[0m %s\n' "$1" >&2; }

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

# 2. Place the dotfiles in ~/.config.
if [ -e "$CONFIG_DIR/.git" ]; then
    log "Dotfiles already present in $CONFIG_DIR; updating..."
    if ! git -C "$CONFIG_DIR" pull --ff-only; then
        err "Could not fast-forward $CONFIG_DIR (local changes or a different branch)."
        err "Commit or stash your changes, or remove $CONFIG_DIR, then re-run this script."
        exit 1
    fi
elif [ -d "$CONFIG_DIR" ] && [ -n "$(find "$CONFIG_DIR" -mindepth 1 -maxdepth 1 2>/dev/null | head -n 1)" ]; then
    log "$CONFIG_DIR exists and is not empty; adding the dotfiles in place..."
    git -C "$CONFIG_DIR" init -q
    git -C "$CONFIG_DIR" remote add origin "$REPO_URL" 2>/dev/null \
        || git -C "$CONFIG_DIR" remote set-url origin "$REPO_URL"
    git -C "$CONFIG_DIR" fetch -q origin main
    # No -f: refuse rather than overwrite any of the user's existing files.
    if ! git -C "$CONFIG_DIR" checkout -B main origin/main; then
        err "Some files in $CONFIG_DIR conflict with the dotfiles and were left untouched."
        err "Back up or remove the conflicting files, then re-run this script."
        exit 1
    fi
else
    log "Cloning dotfiles into $CONFIG_DIR..."
    git clone -q "$REPO_URL" "$CONFIG_DIR"
fi

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

# 4. Hand off to a fresh interactive zsh to run the first-run bootstrap.
if [ "$os" != "Darwin" ]; then
    log "Linux detected (best-effort): Homebrew and starship will NOT auto-install."
    log "See the README for manual steps: $REPO_URL"
fi

log "Done. Starting zsh — the first launch installs Homebrew, plugins, and the prompt."
if [ -e /dev/tty ]; then
    exec zsh -i </dev/tty
else
    log "Open a new terminal window to finish setup (zsh bootstraps on first launch)."
fi
