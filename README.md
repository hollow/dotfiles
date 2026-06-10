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
  - [Set your git identity](#set-your-git-identity)
- [What you get](#what-you-get)
  - [The shell foundation](#the-shell-foundation)
  - [Your prompt and command line](#your-prompt-and-command-line)
  - [Languages and toolchains](#languages-and-toolchains)
  - [Command-line tools](#command-line-tools)
  - [Development and cloud](#development-and-cloud)
  - [Editors and terminal](#editors-and-terminal)

## Getting started

Open the **Terminal** app, paste this line, and press Enter:

```sh
curl -fsSL https://raw.githubusercontent.com/remerge/dotfiles/main/install.sh | sh
```

That's it. The installer will:

1. Install Apple's developer tools (for `git`) if they're missing.
2. Set up your shell configuration in `~/.config`.
3. **Ask for your name and email** to set up your git identity (see
   [below](#set-your-git-identity)).
4. Install Homebrew and everything in the [`Brewfile`](Brewfile)
5. Opens a fresh shell in [Ghostty](https://ghostty.org) so you land in a modern
   terminal.

To update everything later (Homebrew packages and plugins), run:

```sh
zup
```

This updates your Homebrew packages, the ZI plugin manager, and all installed
plugins in one go.

### Set your git identity

During setup the installer asks for your name and email and saves them to
`~/.config/git/local`, which git uses to author your commits. If you skipped the
prompt (just pressed Enter) or want to change them later, set them from the
command line:

```sh
git config --file ~/.config/git/local user.name "Your Name"
git config --file ~/.config/git/local user.email "you@remerge.io"
```

Or edit `~/.config/git/local` directly:

```ini
[user]
  name = Your Name
  email = you@remerge.io
```

Until it's set, git will ask you to configure your name and email on your first
commit. (Avoid `git config --global` here — because this repo lives at
`~/.config`, that may write into the shared `git/config` instead of `local`.)

## What you get

Everything below is set up automatically — the [`Brewfile`](Brewfile) installs
the tools and [`zsh/.zshrc`](zsh/.zshrc) wires each one up when it's present, so
there's nothing for you to configure. This section is a map of the pieces,
grouped by what they do, with a link to each project if you want to learn more.

### The shell foundation

[Z shell](https://www.zsh.org) (`zsh`) is the program that runs your commands —
the default shell on macOS. The configuration starts by forcing a UTF-8 locale,
advertising truecolor, raising the open-file limit, and laying out
[XDG base directories](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html)
so tools keep their files tidy under `~/.config`, `~/.cache`, and `~/.local`
instead of scattering dotfiles across your home directory.

[Homebrew](https://brew.sh) is the macOS package manager — it installs both
command-line programs and native apps. On first launch the config installs
Homebrew (if it's missing) and then everything in the [`Brewfile`](Brewfile):
the prompt, a terminal font with icons, the GNU command-line tools, `git`, and
the utilities listed below.

[ZI](https://github.com/z-shell/zi) is a fast plugin manager for zsh. It
installs itself on first launch and then downloads and loads each plugin on
demand, keeping startup quick. A few small ZI add-ons support it: one sets
sensible [default plugin options](https://github.com/z-shell/z-a-default-ice),
another [caches command output](https://github.com/z-shell/z-a-eval) so it isn't
recomputed every launch, and a local helper loads plugins by convention.

[Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh) contributes a handful of
well-worn library files — directory, key-binding, and color defaults plus
terminal-title handling — and the `..`, `...`, `....` shortcuts for moving up
directories. Your shell
[history](https://zsh.sourceforge.io/Doc/Release/Options.html#History) is kept
large and stored under XDG data. Run `zup` at any time to update Homebrew
packages, ZI, and all plugins in one go.

### Your prompt and command line

[Starship](https://starship.rs) is the prompt — the line shown before your
cursor. It displays the current directory, the active git branch and status, and
more, and it's fast and highly configurable. It's themed here with Catppuccin
Mocha colors and Nerd Font icons.

As you type, [F-Sy-H](https://github.com/z-shell/F-Sy-H) colors the command line
— known commands one color, unknown ones another, with strings and paths
highlighted — so you spot typos before pressing Enter.
[zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) suggests
the rest of a command in grey based on your history; press the right arrow (`→`)
to accept it. [zsh-autopair](https://github.com/hlissner/zsh-autopair)
automatically inserts the matching closing quote, bracket, or parenthesis — and
removes both when you delete one.

Press `Tab` to complete commands, file paths, options, git branches, and more.
[zsh-completions](https://github.com/zsh-users/zsh-completions) adds many extra
completion definitions on top of sensible, error-correcting defaults, and
[fzf-tab](https://github.com/Aloxaf/fzf-tab) turns the completion menu into a
fuzzy-searchable list with file previews. When you type a command that has a
shorter alias, [you-should-use](https://github.com/MichaelAquilina/zsh-you-should-use)
reminds you about it.

### Languages and toolchains

| Tool | What it does |
| --- | --- |
| [mise](https://github.com/jdx/mise) | Manages dev-tool versions, per-project environment variables, and tasks (OpenTofu is installed through it). |
| [Python](https://docs.python.org/3/) | Sets XDG-friendly paths and a virtualenv-first `pip`, with Homebrew's `python`/`pip` on `PATH`. |
| [uv](https://github.com/astral-sh/uv) | An extremely fast Python package and tool manager; `zup` upgrades the tools it installs. |
| [argcomplete](https://github.com/kislyuk/argcomplete#readme) | Tab completion for argparse-based Python programs (installed via uv). |
| [Go](https://go.dev) | Points `GOPATH` at the cache directory and adds `go install` binaries to `PATH`. |
| [Node.js](https://nodejs.org) | JavaScript runtime; keeps its REPL history under XDG data. |
| [npm](https://docs.npmjs.com) | Node's package manager, pointed at an XDG-friendly config. |
| [Bun](https://bun.sh) | All-in-one JavaScript runtime, bundler, and package manager. |
| [Biome](https://biomejs.dev) | Fast formatter and linter for JS, TS, JSON, and CSS. |
| [Ruby](https://www.ruby-lang.org) | Points gem and bundler caches at XDG dirs and puts Homebrew's Ruby first. |

### Command-line tools

| Tool | What it does |
| --- | --- |
| [atuin](https://github.com/atuinsh/atuin) | Searchable, optionally synced shell history (`a`); press `Ctrl-R` to search. |
| [bat](https://github.com/sharkdp/bat) | A `cat` with syntax highlighting and git integration; also colorizes `man` pages. |
| [eza](https://github.com/eza-community/eza) | A modern `ls` with icons and git status; aliased to `l` and `lR`. |
| [duf](https://github.com/muesli/duf) | A friendlier `df`, aliased over it. |
| [ncdu](https://dev.yorhel.nl/ncdu) | Interactive disk-usage explorer. |
| [fzf](https://github.com/junegunn/fzf) | Fuzzy finder powering interactive search and the completion menu (Catppuccin-themed). |
| [glow](https://github.com/charmbracelet/glow) | Renders Markdown in the terminal (Catppuccin Mocha theme). |
| [less](https://man7.org/linux/man-pages/man1/less.1.html) | The pager, tuned for case-insensitive search and raw colors; also drives `man`. |
| [colored man pages](https://www.nongnu.org/man-db/) | Adds color to `man` output. |
| [parallel](https://www.gnu.org/software/parallel/) | Runs commands in parallel. |
| [rsync](https://rsync.samba.org) | Fast incremental file copy and sync. |
| [wget](https://www.gnu.org/software/wget/) | Downloads files over HTTP(S) and FTP(S). |
| [LS_COLORS](https://github.com/trapd00r/LS_COLORS) | Rich color definitions shared by `ls`, `eza`, and the completion menu. |

### Development and cloud

| Tool | What it does |
| --- | --- |
| [git](https://git-scm.com) | Version control, with many short aliases (`s`, `gl`, `gd`, …) and git-aware completion. |
| [direnv](https://github.com/direnv/direnv) | Loads and unloads environment variables per directory from `.envrc` (`da` to allow). |
| [Docker](https://docs.docker.com) | The container CLI. |
| [Colima](https://github.com/abiosoft/colima) | Runs the container VM on macOS; started in the background on demand. |
| [OpenTofu](https://opentofu.org) | Open-source Terraform fork (`tf`), with a shared plugin cache. |
| [PostgreSQL](https://www.postgresql.org) | Adds the client tools and headers to `PATH` for building against libpq. |
| [gcloud](https://cloud.google.com/sdk) | Google Cloud SDK, with completion enabled and usage reporting off. |
| [SOPS](https://github.com/getsops/sops) | Edits secrets encrypted with age, GPG, or cloud KMS. |
| [GnuPG](https://gnupg.org/) | Encryption and signing; `GNUPGHOME` kept under XDG data. |
| [1Password](https://1password.com) | Password manager and CLI (`op`); also provides the SSH agent. |
| [SSH](https://www.openssh.com) | Secure shell, wired to 1Password's agent when it's available. |
| [tmux](https://github.com/tmux/tmux) | Terminal multiplexer (`T`), with tpm for plugins. |

### Editors and terminal

| Tool | What it does |
| --- | --- |
| [Neovim](https://neovim.io) | The default `$EDITOR`; `vim` is aliased to it. |
| [VS Code](https://code.visualstudio.com) | Editor; its settings, keybindings, and MCP config are symlinked in. |
| [Ghostty](https://ghostty.org) | Fast, native, GPU-accelerated terminal emulator. |
| [Claude](https://claude.ai) | Anthropic's AI assistant CLI. |
