# Remerge dotfiles

A ready-to-use shell setup for your Mac. One command gives you a modern
terminal — a clean prompt, command autocompletion, syntax highlighting, and
autosuggestions — with nothing to configure.

## Install

Open the **Terminal** app, paste this line, and press Enter:

```sh
curl -fsSL https://raw.githubusercontent.com/remerge/dotfiles/main/install.sh | sh
```

That's it. The installer will:

1. Install Apple's developer tools (for `git`) and Homebrew if they're missing.
2. Set up your shell configuration.
3. Open a fresh shell. **The first launch takes about a minute** while it
   downloads the prompt and plugins — this happens only once.

## What you get

- [**zi**](https://github.com/z-shell/zi) — a fast zsh plugin manager
  (installs itself)
- [**starship**](https://starship.rs) — a clean, informative prompt
- **Syntax highlighting**, **autosuggestions**, **autopair**, and richer
  **tab completion**
- Sensible history and completion defaults

## Updating

To update everything later (Homebrew packages and plugins), run:

```sh
zup
```

## Linux

Linux is supported on a best-effort basis. The installer clones the config and
links `~/.zshrc`, but it does **not** auto-install Homebrew or starship (that
step is macOS-only). Install [Homebrew](https://brew.sh) and
[starship](https://starship.rs) yourself, then open a new shell.
