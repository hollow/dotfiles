# Remerge dotfiles

A ready-to-use shell setup for your Mac. One command gives you a modern terminal
— a clean prompt, command autocompletion, syntax highlighting, and
autosuggestions — with nothing to configure.

Linux is supported on a best-effort basis: the installer clones the config and
links `~/.zshrc`, but it does **not** auto-install Homebrew or starship (that
step is macOS-only). Install [Homebrew](https://brew.sh) and
[starship](https://starship.rs) yourself, then open a new shell.

## Contents <!-- omit in toc -->

- [Getting started](#getting-started)
- [What you get](#what-you-get)
  - [Homebrew](#homebrew)
  - [Z Shell and the ZI plugin manager](#z-shell-and-the-zi-plugin-manager)
  - [Starship prompt](#starship-prompt)
  - [Syntax highlighting](#syntax-highlighting)
  - [Autosuggestions](#autosuggestions)
  - [Autopair](#autopair)
  - [Tab completion](#tab-completion)

## Getting started

Open the **Terminal** app, paste this line, and press Enter:

```sh
curl -fsSL https://raw.githubusercontent.com/remerge/dotfiles/main/install.sh | sh
```

That's it. The installer will:

1. Install Apple's developer tools (for `git`) and Homebrew if they're missing.
2. Set up your shell configuration.
3. Open a fresh shell. **The first launch takes about a minute** while it
   downloads the prompt and plugins — this happens only once.

To update everything later (Homebrew packages and plugins), run:

```sh
zup
```

This updates your Homebrew packages, the ZI plugin manager, and all installed
plugins in one go.

## What you get

Everything below is installed and configured for you. You don't need to touch
any of it — this section just explains what the pieces are.

### Homebrew

[Homebrew](https://brew.sh) is the package manager for macOS — the tool that
installs both command-line programs and native macOS apps. The first time you
open your shell, the config
installs Homebrew (if it isn't already there) and then installs everything
listed in the [`Brewfile`](Brewfile): the prompt, a terminal font with icons,
the GNU command-line tools, `git`, and a few common utilities.

### Z Shell and the ZI plugin manager

[Z shell](https://www.zsh.org) (`zsh`) is the shell — the program that runs your
commands. It's the default shell on macOS; this repo configures it with sensible
history and key-binding defaults.

[ZI](https://github.com/z-shell/zi) is a fast plugin manager for zsh. It
installs itself on first launch and then downloads and loads the plugins below
on demand, keeping startup quick.

### Starship prompt

[Starship](https://starship.rs) is the prompt — the line shown before your
cursor. It displays the current directory, the active git branch and status, and
more, and it's fast and highly configurable. It's themed here with Catppuccin
Mocha colors and Nerd Font icons.

### Syntax highlighting

[F-Sy-H](https://github.com/z-shell/F-Sy-H) colors your command line as you
type: known commands turn one color, unknown commands another, and strings and
paths are highlighted — so you spot typos before pressing Enter.

### Autosuggestions

[zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) suggests
the rest of a command in grey as you type, based on your history. Press the
right arrow (`→`) to accept the suggestion.

### Autopair

[zsh-autopair](https://github.com/hlissner/zsh-autopair) automatically inserts
the matching closing character when you type an opening quote, bracket, or
parenthesis — and removes both when you delete one.

### Tab completion

Press `Tab` to complete commands, file paths, options, git branches, and more.
[zsh-completions](https://github.com/zsh-users/zsh-completions) adds many extra
completion definitions, on top of sensible, error-correcting completion
defaults.
