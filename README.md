# dotfiles

These are my personal dotfiles, carefully curated over more than a decade to
streamline terminal and development workflows and enhance productivity. This
repository includes configurations for various tools and shell programs,
ensuring a cohesive and efficient environment.

## Installation

```sh
git clone https://github.com/hollow/dotfiles ~/.config
ln -nfs ~/.config/zsh/.zshrc ~/.zshrc
exec zsh
```

## Configuration Details

### Z Shell

The repository includes extensive configurations for `zsh`, managed using
[zi](https://github.com/z-shell/zi). Zi allows for fast and flexible management
of zsh plugins, enabling users to load and configure plugins on demand,
enhancing shell performance and functionality.

- **User Information**: Environment variables `USER_NAME` and `USER_EMAIL` for
  Git and GPG.

- **Locale Settings**: Enforces `en_US.UTF-8` for consistent language and
  character encoding.

- **Truecolor Support**: Sets `COLORTERM` to `truecolor` for enhanced terminal
  colors.

- **Path Management**: Dynamically sets system and user paths for binaries and
  libraries.

- **XDG Directories**: Configures paths following the [XDG Base Directory
  Specification](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html)
  to organize user data in a clean, standardized structure:

  - `XDG_CONFIG_HOME` (`~/.config`): User-specific configuration files
  - `XDG_CACHE_HOME` (`~/.cache`): Non-essential cached data
  - `XDG_DATA_HOME` (`~/.local/share`): User-specific data files
  - `XDG_STATE_HOME` (`~/.local/state`): State data that should persist between restarts
  - `XDG_RUNTIME_DIR` (`~/.local/run`): Runtime files with restricted permissions (mode 0700)

  All directories are automatically created on shell startup, ensuring a consistent environment structure.

- **Oh My Zsh Libraries**: Leverages core [Oh My Zsh](https://ohmyz.sh/) library
  modules for essential shell functionality:

  - `completion.zsh`: Enhanced tab completion with visual feedback
  - `directories.zsh`: Directory navigation improvements and shortcuts
  - `functions.zsh`: Common utility functions
  - `grep.zsh`: Colorized grep output
  - `history.zsh`: Advanced history management and search
  - `key-bindings.zsh`: Standard keyboard shortcuts for line editing
  - `spectrum.zsh`: 256-color support utilities
  - `termsupport.zsh`: Terminal title and tab management

- **Prompt & Visual Feedback**: The shell uses
  [Powerlevel10k](https://github.com/romkatv/powerlevel10k), a fast and highly
  customizable zsh theme that provides instant command feedback with a rich,
  informative prompt. It displays Git status, command execution time, exit
  codes, background jobs, and more—all updated asynchronously for zero lag.

  Combined with [Fast Syntax Highlighting
  (F-Sy-H)](https://github.com/z-shell/F-Sy-H), commands are color-coded as you
  type: valid commands appear in green, invalid in red, with additional syntax
  highlighting for strings, redirections, and command options. This immediate
  visual feedback catches typos before execution and improves command-line
  awareness.

- **Enhanced Completion**: The shell integrates
  [fzf](https://github.com/junegunn/fzf) for fuzzy searching and
  [fzf-tab](https://github.com/Aloxaf/fzf-tab) to replace the traditional tab
  completion menu with an interactive fzf interface. When completing `cd`
  commands, fzf-tab displays a live preview of each directory's contents using
  `eza`, making navigation faster and more intuitive. The completion system is
  further enhanced with:

  - **Error Correction**: Approximate completion with automatic typo correction
    (up to 7 character errors based on input length)
  - **Formatted Messages**: Styled descriptions, warnings, and error counts for
    clearer feedback during completion
  - **Customized Sorting**: Disables alphabetical sorting for `git checkout` to
    preserve recency-based branch ordering
  - **Fish-like Autosuggestions**: As you type, the shell displays greyed-out
    suggestions from command history that can be accepted with the right arrow
    key, dramatically speeding up command recall
  - **Auto-pairing**: Automatically closes matching quotes, brackets, and
    parentheses as you type, reducing syntax errors in complex commands
  - **Extended Completions**: Installs additional completion definitions for
    hundreds of commands beyond the zsh defaults, auto-updating alongside other
    plugins

- **Directory Navigation**: Convenient aliases for navigating up multiple directory levels:
  - `..`: Navigate up one directory level
  - `...`: Navigate up two directory levels
  - `....`: Navigate up three directory levels
  - `.....`: Navigate up four directory levels

- **Per-Directory Environments (direnv)**: Integrates `direnv` to automatically
  adjust environment variables when entering project directories that define a
  `.envrc`. The config adds a concise helper alias `da` for `direnv allow` and
  wires the direnv shell hook so changes apply instantly. This keeps language
  versions, secrets, and tool paths scoped to their project without polluting
  the global shell session.

- **Batch & Parallel Helpers**: Two custom helpers streamline running commands
  across multiple project directories:

  - `:each DIRS... do <cmd>`: Iterates over matching directories, entering each
    one sequentially and executing the provided command (or just changing into
    it if no command is given). Output is grouped by directory for readability.
  - `:parallel DIRS... do <cmd>`: Executes the command in up to 5 parallel jobs
    using GNU `parallel`, sourcing the full zsh configuration for each job. Tags
    each line of output with its originating directory for easier log scanning.
    Ideal for bulk updates, status checks, or building many modules.

  These helpers reduce manual loop boilerplate and provide consistent context
  (environment, PATH, functions) in every invocation.

- **Update Management**: The `zup` command provides a unified update workflow
  that sequentially updates all major tools and packages in the environment:

  - Homebrew packages (via `brew update`, `brew upgrade`, and `brew bundle`)
  - Python applications installed via pipx
  - Tmux plugins
  - Google Cloud SDK components
  - Zi plugin manager itself
  - All Zi-managed zsh plugins

  This ensures the entire development environment stays current with a single
  command.

- **Common CLI Tooling**: Frequently used modern replacements and enhancers are
  installed and configured for an improved terminal experience:

  - `bat`: Syntax-highlighted `cat` with paging integration and man page coloring
  - `btop`: Rich terminal resource monitor (CPU, memory, processes)
  - `duf`: Readable disk/file system usage instead of classic `df`
  - `eza`: Feature-rich `ls` alternative with colors, icons, and tree views
  - `fd`: Fast, intuitive alternative to `find` with sensible defaults
  - `glow`: Render Markdown in the terminal nicely
  - `jq` / `yq` / `xq`: JSON, YAML, and XML query/transform tools for structured data
  - `less`: Configured pager with improved prompts, raw color support, and history
  - `man`: Colorized manual pages via integration with `bat`
  - `ncdu`: Interactive disk usage explorer for pruning large directories
  - `parallel`: Run commands across inputs concurrently with tagged output
  - `rg` (`ripgrep`): Fast recursive search with color and smart file ignores
  - `sponge`: Safely read & write in a pipeline without truncation races
  - `xh`: Modern `curl`-like HTTP client with nicer UX

### Homebrew

My installation leverages [Homebrew](https://brew.sh/) as the primary package
manager on macOS, with declarative package management through `Brewfile`. This
file defines all formulae (command-line tools), casks (GUI applications), Mac
App Store apps, and VS Code extensions to be installed.

- **Automatic Installation & Update**: On first shell startup after cloning the
  dotfiles, and whenever the `zup` update helper is run, the configuration
  ensures every entry in the `Brewfile` is installed. This is achieved through
  the `:brew-update` function which:

  - Dumps current state back into `Brewfile` (`brew bundle dump -f`) to keep it
    version-aligned
  - Runs `brew update` + `brew upgrade` for installed formulae
  - Applies the Brewfile (`brew bundle install`) so missing packages
    are installed and extraneous ones can be pruned
  - Performs cleanup (`brew autoremove`, `brew cleanup -s --prune=all`) for a
    lean installation

- **Reproducibility**: No manual `brew install` command is required—just on a
  new host. Start a shell with this configuration or run `zup` and the
  environment converges to the declared state.

- **GNU Utilities**: GNU versions of common Unix utilities (coreutils,
findutils, sed, tar, etc.) take precedence over macOS BSD versions, ensuring
consistent behavior across different Unix-like systems.

### SSH

SSH is configured for reliable, persistent connections with smart authentication
via 1Password integration.

- **Connection Persistence**: Configured to prevent dropped connections through
  keep-alive settings:

  - `ServerAliveInterval 60`: Sends keep-alive packets every 60 seconds to
    maintain idle connections
  - `ServerAliveCountMax 10`: Allows up to 10 missed responses before
    disconnecting (total ~10 minutes of unresponsiveness tolerance)

- **Simplified Host Management**: Host key verification is streamlined for
  development environments:

  - `HashKnownHosts no`: Known hosts are stored in plain text for easier manual
    inspection and troubleshooting
  - `StrictHostKeyChecking no`: Automatically accepts new host keys without
    prompting (suitable for dynamic environments where hosts change frequently)

- **1Password SSH Agent**: Seamlessly integrates with 1Password for SSH key
  management. If 1Password's SSH agent socket is detected, it's automatically
  configured as the authentication agent. This allows SSH keys stored in
  1Password to be used for authentication with biometric unlock, eliminating the
  need to manage separate SSH key files. Falls back to the standard Oh My Zsh
  SSH agent plugin if 1Password is unavailable.

- **Privileged Access Helper**: The `ssu` alias provides quick access to remote
  root shells via `sshlive -o RequestTTY=force -o RemoteCommand='sudo -i'`,
  automatically requesting a PTY and elevating to root upon connection.

### GnuPG

GNU Privacy Guard (GPG) is configured with XDG-compliant paths and automatic
agent management for cryptographic operations.

- **XDG Directory Compliance**: GPG configuration and keyring are stored in
  `~/.local/share/gnupg` (`GNUPGHOME`) following the XDG Base Directory
  specification, keeping GPG data out of the home directory root.

- **Terminal Integration**: `GPG_TTY` is automatically set to the current
  terminal device, enabling proper passphrase prompting in terminal sessions.
  This ensures GPG can securely request passphrases when needed for signing,
  encryption, or decryption operations.

- **GPG Agent**: The Oh My Zsh `gpg-agent` plugin is loaded to automatically
  start and manage the GPG agent, which handles key caching and passphrase
  management. The agent enables seamless GPG operations (signing, encryption,
  authentication) without repeatedly entering passphrases, using secure
  timeout-based credential caching.

This setup primarily supports GPG-signed Git commits (see Git section), but can
also be used for encrypted email communication, file encryption/decryption, and
GPG-based authentication workflows.

### Tmux

Tmux is configured as a powerful terminal multiplexer with plugin management,
session persistence, and ergonomic keybindings for efficient multitasking.

- **XDG Directory Compliance**: Plugin cache is stored in
  `~/.cache/tmux/plugins` (`TMUX_PLUGIN_MANAGER_PATH`) following the XDG Base
  Directory specification, keeping tmux data organized.

- **Custom Prefix Key**: Uses `Ctrl-a` instead of the default `Ctrl-b` as the
  prefix key, providing a more ergonomic alternative that's easier to reach on
  most keyboards.

- **Plugin Management**: Uses [TPM (Tmux Plugin
  Manager)](https://github.com/tmux-plugins/tpm) to manage plugins, with
  automatic installation and updates via the `:tmux-update` helper (invoked by
  `zup`):

  - `tmux-sensible`: Sensible default settings that everyone can agree on
  - `tmux-resurrect`: Save and restore tmux sessions across system restarts
  - `tmux-continuum`: Automatic session saving and restoration (works with
    tmux-resurrect)
  - `tmux-colors-solarized`: Solarized dark color scheme for consistent terminal
    aesthetics
  - `tmux-power`: Modern, informative status bar theme

- **256-Color Support**: Configured with `screen-256color` terminal type and
  true color support via terminal overrides, ensuring rich colors in terminal
  applications like vim and less.

- **Ergonomic Keybindings**: Enhanced navigation and management shortcuts:

  - `Shift-Left/Right`: Navigate between windows without prefix key
  - `Ctrl-Shift-Arrow`: Navigate between panes without prefix key
  - `Ctrl-k`: Clear screen and scrollback (emulates macOS Terminal behavior)
  - `Ctrl-a Ctrl-a`: Jump to last active window
  - `Ctrl-a i`: Toggle synchronized input across panes
  - `Ctrl-a x`: Close current pane
  - `Ctrl-a r`: Reload tmux configuration

- **Session Management**: Automatic session persistence through tmux-continuum
  ensures work context is preserved across system reboots. Sessions are
  automatically saved every 15 minutes and restored on tmux start.

- **Default Session**: The Oh My Zsh tmux plugin integration sets `default` as
  the default session name and provides the `T` alias for quick tmux access.

- **Window & Pane Indexing**: Windows and panes start at index 1 instead of 0,
  making keyboard shortcuts more intuitive (1 is closer to the other numbers on
  the keyboard than 0).

### Vim/Neovim

Vim is configured with XDG-compliant paths and modern defaults for efficient
text editing. The configuration works with both Vim and Neovim, with the shell
aliasing `vim` to `nvim` when available.

- **XDG Directory Compliance**: All Vim data is stored following the XDG Base
  Directory specification:

  - Configuration: `~/.config/vim` (runtime path and packpath)
  - Data: `~/.local/share/vim` (plugins, spell files, views, viminfo)
  - Cache: `~/.cache/vim` (backup, swap, undo files)

  This keeps the home directory clean by avoiding the traditional `~/.vim` and
  `~/.vimrc` clutter.

- **Plugin Management**: Uses [vim-plug](https://github.com/junegunn/vim-plug)
  to manage plugins, with plugins installed to `~/.local/share/vim/plugged`:

  - `vim-code-dark`: Visual Studio Code dark color scheme for consistent
    aesthetics across editors

- **Modern Defaults**: Enhanced from the base Vim configuration by Amir
  Salihefendic's [vimrc](https://github.com/amix/vimrc):

  - 500 lines of command history
  - Auto-reload files changed externally
  - Smart case-insensitive searching with incremental search
  - Syntax highlighting with 256-color support
  - UTF-8 encoding by default
  - Unix line endings preferred
  - Persistent undo, backup, and swap files (in XDG cache)

- **Editing Enhancements**:

  - Leader key: `,` (comma) for custom command combinations
  - `<leader>w`: Quick save
  - `:W`: Save with sudo (handles permission-denied errors)
  - `0`: Jump to first non-blank character instead of line start
  - Space: Search forward, Ctrl-Space: Search backward
  - Auto-delete trailing whitespace on save for common file types
  - Smart tab handling (4 spaces, expandtab enabled)

- **Window & Buffer Management**:

  - `Ctrl-h/j/k/l`: Navigate between split windows
  - `<leader>bd`: Close current buffer
  - `<leader>ba`: Close all buffers
  - `<leader>tn`: New tab, `<leader>tc`: Close tab
  - `<leader>tl`: Toggle to last accessed tab
  - Return to last edit position when reopening files

- **Visual Enhancements**:

  - Informative status line showing file path, CWD, line, and column
  - Highlight matching brackets
  - Show line numbers and ruler
  - Visual error feedback (no annoying beeps)

- **Spell Checking**:

  - `<leader>ss`: Toggle spell checking
  - `<leader>sn/sp`: Next/previous spelling error
  - `<leader>sa`: Add word to dictionary
  - `<leader>s?`: Suggest corrections

- **Neovim Integration**: The `VIMINIT` environment variable points to the
  vimrc configuration, ensuring both Vim and Neovim use the same settings. The
  `EDITOR` environment variable is set to `nvim`, making it the default editor
  for Git commits, cron jobs, and other system operations.

### Git

Git is configured for secure, efficient workflows with GPG-signed commits,
sensible defaults, and extensive shell integration for GitHub operations.

- **Identity & Security**: User name and email are set globally for commits,
  with automatic GPG signing enabled for all commits using a configured signing
  key. This ensures commit authenticity and non-repudiation.

- **Modern Defaults**: Uses `main` as the default branch for new repositories,
  enables fast-forward-only pulls to maintain linear history, and automatically
  sets up remote tracking branches on first push. Rerere (reuse recorded
  resolution) is enabled to remember conflict resolutions.

- **SSH for GitHub**: HTTPS GitHub URLs are automatically rewritten to SSH for
  seamless authentication via SSH keys.

- **Workflow Aliases**: Short, memorable commands for common operations:

  - `c`: Show changes (modified files, excluding untracked)
  - `ga`: Stage all changes
  - `gap`: Stage changes interactively (patch mode)
  - `ci`: Commit staged changes
  - `amend`: Amend the last commit without changing the message
  - `co`: Checkout branches or files
  - `gcm`: Checkout the main branch (detects `main` or `master`)
  - `gd`: Show unstaged changes
  - `gdc`: Show staged changes (diff cached)
  - `gdm`: Diff against the main branch
  - `gf`: Fetch with automatic pruning of deleted remote branches
  - `gl`: Pretty-formatted log graph with colors
  - `gp`: Pull changes
  - `gpr`: Pull with rebase and auto-stash
  - `grh`: Unstage all changes
  - `s`: Compact status (current directory only)

- **GitHub Integration**: Helper functions streamline GitHub workflows via `gh`
  CLI:

  - `pr`: Push current branch and open a pull request creation form, then view
    in browser
  - `ghm`: Merge a PR and clean up local branches
  - `hub-repo-list`: List all repositories (with filtering options)
  - `hub-clone-all`: Clone all non-archived repos in parallel
  - `hub-remove-archived`: Delete local copies of archived repositories

- **Batch Operations**: Apply commands across multiple Git repositories:

  - `git-each DIRS... do <cmd>`: Run git commands sequentially in matching
    repositories
  - `git-parallel DIRS... do <cmd>`: Run git commands in parallel across
    repositories (up to 5 jobs)

- **Additional Git Config Aliases**: The git config file defines additional
  utility aliases for specialized tasks:

  - `aliases`: List all configured git aliases with their definitions
  - `amend`: Amend the last commit reusing its message (same as shell alias)
  - `changes`: Show modified files excluding untracked (same as shell alias `c`)
  - `ci`: Shorthand for commit
  - `co`: Shorthand for checkout
  - `dc`: Show staged changes (diff cached)
  - `lg`: Pretty-formatted log graph with colors, relative dates, and author names
  - `ls`: List all files tracked in HEAD
  - `new`: Show commits added to a branch since last fetch (e.g., `git new main`)
  - `rank`: Contributor rankings by commit count (excluding merges)
  - `st`: Compact status with branch info
  - `stat`: Show diff statistics (files changed, insertions, deletions)
  - `tags`: List all tags
  - `whatis`: One-line commit summary with hash and short date

- **Configuration Details**: Additional settings include:

  - Branch sorting by most recent commit date (`-committerdate`)
  - Detached HEAD warnings suppressed for intentional detached states
  - Copy detection enabled for renames in diffs
  - Automatic tag pushing when pushing commits (`followTags`)
  - Git LFS (Large File Storage) filters configured for binary file management

### Copier

Copier is a project templating tool that maintains synchronization between
template repositories and generated projects, enabling consistent updates across
multiple codebases.

- **Template-Based Project Generation**: Copier generates new projects from
  template repositories, prompting for customization values that are stored in
  `.copier-answers.yml` for reproducibility and future updates.

- **Template Updates**: Projects generated with Copier can pull in template
  updates while preserving local customizations. The answers file tracks which
  template version was used, enabling smart merges when templates evolve.

- **Batch Operations**: Helper functions streamline working with multiple
  Copier-managed projects:

  - `copier-each DIRS... do <cmd>`: Run commands sequentially in directories
    containing `.copier-answers.yml`
  - `copier-parallel DIRS... do <cmd>`: Run commands in parallel across
    Copier-managed projects (up to 5 jobs)

  These helpers automatically discover all projects generated from Copier
  templates, making it easy to apply template updates, check status, or perform
  bulk operations across entire project families.

### Python

The Python setup favors a clean, isolated tooling environment while keeping the
system free from ad‑hoc `pip install --user` clutter.

- **Runtime Discovery**: `PYTHONHOME` is set dynamically to the newest Homebrew
  installed Python (pattern `python@*`), and its `libexec/bin` directory is
  added early to `PATH` to provide the correct `python`, `pip`, and venv tools.

- **Interactive Startup**: `PYTHONSTARTUP` points to `python/startup.py` so
  every REPL session loads personal helper code (history, quality‑of‑life
  tweaks, etc.).

- **Application Isolation via pipx**: `pipx` is configured with
  `PIPX_HOME` (cached environments) and `PIPX_BIN_DIR` (binaries added to
  `PATH`). Tools installed through pipx (e.g. linters, formatters, CLIs) run in
  dedicated virtual environments, avoiding dependency conflicts.

- **Automatic Tool Refresh**: The `:pipx-update` helper (invoked by `zup`)
  reinstalls and upgrades all pipx‑managed applications, including injected
  dependencies, ensuring they stay current without manual tracking.

- **Tab Completion for Python CLIs**: `argcomplete` integration extends shell
  completion for Python programs (e.g. `pipx`) by adding its
  generated completion functions to `fpath` and registering them after the
  packages are available.

- **Clean Separation of Caches/Data**: All Python‑related config, cache, and
  data locations honor the XDG directory setup, keeping the home directory
  tidy and making backup/cleanup operations safer.

### Ansible

Ansible is configured with XDG-compliant paths and convenient helpers for
infrastructure automation workflows.

- **XDG Directory Compliance**: All Ansible data is stored following the XDG
  specification:

  - `ANSIBLE_GALAXY_CACHE_DIR`: Galaxy role/collection cache in `~/.cache/ansible`
  - `ANSIBLE_GALAXY_TOKEN_PATH`: API tokens in `~/.local/share/ansible/galaxy_token`
  - `ANSIBLE_LOCAL_TEMP`: Temporary files in `~/.local/run/ansible/tmp`
  - `ANSIBLE_PERSISTENT_CONTROL_PATH_DIR`: SSH control sockets in
    `~/.local/run/ansible/cp`

- **Quick Access Aliases**: Short commands for common Ansible operations:

  - `ad`: ansible-doc (view module documentation)
  - `ai`: ansible-inventory (inspect inventory)
  - `ap`: ansible-playbook (run playbooks)

- **Host Management Helpers**: Functions for working with AlmaLinux platform hosts:

  - `ah`: List all AlmaLinux platform hosts from inventory (via jq filtering)
  - `asu [pattern] <command>`: Run ad-hoc shell commands on hosts matching a
    pattern (defaults to `platform_almalinux`). Executes with privilege
    escalation (`-b`) using the shell module.

- **Batch Operations**: Apply commands across multiple Ansible projects:

  - `ansible-each DIRS... do <cmd>`: Run commands sequentially in directories
    containing `ansible.mk`
  - `ansible-parallel DIRS... do <cmd>`: Run commands in parallel across
    Ansible projects (up to 5 jobs)

### Terraform

Terraform is configured for infrastructure-as-code workflows with XDG-compliant
paths and convenient aliases for common operations.

- **XDG Directory Compliance**: Terraform plugin cache is stored in
  `~/.cache/terraform/plugins` (`TF_PLUGIN_CACHE_DIR`), following the XDG Base
  Directory specification. This prevents duplicate provider downloads across
  multiple Terraform projects and keeps plugin binaries organized.

- **Checkpoint Telemetry Disabled**: `CHECKPOINT_DISABLE=true` disables
  HashiCorp's checkpoint telemetry system, preventing version checks and
  analytics reporting for enhanced privacy and performance.

- **Configuration Symlink**: The `.terraform.d` directory is symlinked from
  `terraform/config.tfrc` in the dotfiles, centralizing Terraform CLI
  configuration.

- **Quick Aliases**: Short commands for common Terraform operations:

  - `tf`: Shorthand for `terraform`
  - `tfd`: Destroy infrastructure (`terraform destroy`)
  - `tfi`: Import existing resources (`terraform import`)

- **Targeted Operations**: Helper functions for selective plan/apply operations:

  - `tfa [resources...]`: Apply changes, optionally targeting specific resources
    (e.g., `tfa module.vpc aws_instance.web` expands to `terraform apply
    -target=module.vpc -target=aws_instance.web`)
  - `tfp [resources...]`: Plan changes with optional resource targeting, using
    the same syntax as `tfa`

  When called without arguments, these functions operate on the entire
  configuration. With arguments, they automatically prefix each resource with
  `-target=` for selective operations.

- **Batch Operations**: Apply commands across multiple Terraform projects:

  - `terraform-each DIRS... do <cmd>`: Run commands sequentially in directories
    containing `terraform.mk`
  - `terraform-parallel DIRS... do <cmd>`: Run commands in parallel across
    Terraform projects (up to 5 jobs)
