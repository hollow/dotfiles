# Remerge dotfiles — Ring 12 (completion rework + fzf + fzf-tab) design

**Date:** 2026-06-06
**Status:** Approved (design); ready for implementation planning
**Repo:** <https://github.com/remerge/dotfiles>
**Builds on:** Rings 0–11 (merged) — see
`docs/superpowers/specs/2026-06-06-zsh-dotfiles-ring11-design.md`
**Upstream pin:** `hollow/dotfiles@main` at commit `236cfef` (advanced from
Ring 11's `906b19e`)

## Goal

Port the **zsh completion rework + fzf + fzf-tab** slice from upstream. This is
a single self-contained upstream change — commit `236cfef` "Rework zsh
completion setup (#3)" — plus the one tool it depends on that the fork has never
carried (`fzf`).

The rework:

- inlines `OMZL::completion.zsh` into an owned, commented `# zsh/completion`
  block at the end of the file and deletes the small completion-zstyle block
  that used to sit near the top;
- moves `compinit` out of F-Sy-H's `atinit` and into `zsh-completions`' `atload`
  (so it runs *after* `zsh-completions` adds its functions to `fpath`, replaying
  the compdefs queued by every completion plugin above it);
- adds **fzf** (a new tool for the fork) and **fzf-tab**, loading fzf-tab after
  `compinit` and before the widget-wrapping plugins (autosuggestions, F-Sy-H);
- switches to case-sensitive matching, keeps common-prefix auto-insert via
  `menu no` (no `menu_complete`), broadens `list-colors` to `:completion:*` so
  fzf-tab's menu is colorized, and adds `bashcompinit` for `complete -C`-style
  programmable completion.

## Scope (decided)

Tight: **completion rework + fzf + fzf-tab only.** The same upstream file at
`236cfef` also carries `zsh-bench`, `direnv`/`.envrc`, `atuin`, and `copier`
(plus dozens of other brews/casks/extensions); none are ported here — they are
tools the fork has never carried and are out of scope for this ring (see
Deviations).

Every ported line is **byte-identical to `236cfef`**. Unlike Ring 11, this ring
has **no line-level deviations** inside its slice; the only deviations are the
omission of whole upstream tool blocks the fork does not carry.

### A. `Brewfile`

One added line, byte-identical to upstream, in sorted position:

- `brew "fzf"` — after `brew "findutils"`, before `brew "gawk"`.

`fzf` is required: fzf-tab is an fzf front-end and the `# fzf` block exports
`FZF_DEFAULT_OPTS`. The added line is byte-identical to upstream's, so the fork's
`brew`/`cask` lines remain a strict subset of upstream; the only fork-only
Brewfile line overall is the pre-existing Ring-10 `vscode
"davidanson.vscode-markdownlint"` deviation, which this ring does not touch.

### B. `.zshrc` — OMZ block (current lines 105–114)

Drop three lines so the block matches upstream `236cfef`:

- remove `COMPLETION_WAITING_DOTS="true"`
- remove `OMZL::completion.zsh` (now inlined in the `# zsh/completion` block)
- remove `OMZL::grep.zsh` (unused)

Resulting block (byte-identical to upstream):

```zsh
# ohmyzsh: community driven zsh framework
# https://github.com/ohmyzsh/ohmyzsh
zi for \
    OMZL::directories.zsh \
    OMZL::functions.zsh \
    OMZL::history.zsh \
    OMZL::key-bindings.zsh \
    OMZL::spectrum.zsh \
    OMZL::termsupport.zsh
```

### C. `.zshrc` — remove the top completion-zstyle block (current lines 127–151)

Delete the entire block from `# use approximate completion with error
correction` through `zstyle ':completion:*:git-checkout:*' sort false`
(including the surrounding blank lines so the `history configuration` block is
immediately followed by the `# brew:` block, matching upstream). An expanded,
re-commented version of these styles moves into the end-of-file
`# zsh/completion` block (§F). Note `zstyle ':completion:*:match:*' original
only` is dropped entirely (upstream does not re-add it — the new `matcher-list`
supersedes it).

### D. `.zshrc` — dircolors load body (current lines 286–288)

Replace the one-line body of `:dircolors-load()`:

```zsh
    zstyle ":completion:*:default" list-colors "${(s.:.)LS_COLORS}"
```

with upstream's broadened + commented version:

```zsh
    # colorize completion candidates (filenames, dirs, …) in every context, not
    # just the `default` tag — fzf-tab reads list-colors to color its menu. Set
    # here rather than in the completion block because LS_COLORS is populated by
    # :dircolors-eval, which runs when this plugin loads.
    zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
```

The rest of the dircolors block (`:dircolors-eval`, the `zi auto id-as"dircolors"
…` load line) is unchanged and already byte-identical to upstream.

### E. `.zshrc` — new `# fzf` block

Insert between the **eza** block (`… zi auto has"eza" wait for eza`) and the
**gcloud** block — upstream's relative position (`eza → fzf → gcloud`).
Byte-identical to upstream:

```zsh
# fzf
# https://github.com/catppuccin/fzf/blob/main/themes/catppuccin-fzf-mocha.sh
export FZF_DEFAULT_OPTS=" \
    --color=bg+:#313244,bg:#1E1E2E,spinner:#F5E0DC,hl:#F38BA8 \
    --color=fg:#CDD6F4,header:#F38BA8,info:#CBA6F7,pointer:#F5E0DC \
    --color=marker:#B4BEFE,fg+:#CDD6F4,prompt:#CBA6F7,hl+:#F38BA8 \
    --color=selected-bg:#45475A \
    --color=border:#6C7086,label:#CDD6F4"

zi auto has"fzf" wait for fzf
```

### F. `.zshrc` — end-block rework (current lines 485–503)

Replace the current tail (`f-sy-h → autosuggestions → autopair →
zsh-completions`, in that order) with upstream's reordered block. The fork takes
everything from `# zsh-completions:` through the **autopair** block and stops
there — upstream continues into `zsh-bench` and the `.envrc` hook, both omitted
(Deviation 2). Byte-identical to upstream:

```zsh
# zsh-completions: extra completion functions. Loads before compinit so they
# land in fpath, then its atload runs compinit once — replaying the compdefs
# queued by every completion plugin above — before fzf-tab and the widget
# wrappers below.
# https://github.com/zsh-users/zsh-completions
zi auto blockf atpull'zinit creinstall -q zsh-users/zsh-completions' \
    atload"zicompinit; zicdreplay" wait for zsh-users/zsh-completions

# fzf-tab: replace the completion menu with fzf. Must load after compinit (above)
# and before the widget-wrapping plugins (autosuggestions, F-Sy-H) below.
# https://github.com/Aloxaf/fzf-tab
zi auto has"fzf" wait for Aloxaf/fzf-tab

# preview directory content with eza when completing cd. =always forces color and
# icons even though the preview is piped (eza auto-disables both off a TTY); icons
# need a Nerd Font, which the terminal already uses.
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --all --long --group --color=always --icons=always $realpath'

# zsh/completion
zmodload -i zsh/complist            # list-colors support + native menu
unsetopt flowcontrol                # reclaim ^S/^Q from terminal flow control
setopt complete_in_word             # allow completing with the cursor mid-word
setopt always_to_end                # ...and jump the cursor to the word end afterwards

# fzf-tab's recommended `menu no`, and intentionally NO menu_complete: zsh inserts
# the longest common prefix on the first TAB (the auto-insert we want) and fzf-tab's
# menu opens once there's nothing more to insert. With case-sensitive matching
# (below) a prefix like `CL` resolves to one match and just completes, so the old
# `CL`→`CLaude` two-tab annoyance is gone. (`setopt menu_complete` would force the
# menu onto the first TAB everywhere but never auto-insert a common prefix.)
zstyle ':completion:*' menu no

# case-sensitive matching, keeping partial-word (r:) and substring (l:/r:) matchers.
# Dropping the leading `m:{...}={...}` case-fold makes e.g. `CL` match only
# CLAUDE.md (not claude_desktop_config.json), so it completes directly — the
# ambiguity behind the old `CL`→`CLaude` two-tab problem can't arise.
zstyle ':completion:*' matcher-list 'r:|=*' 'l:|=* r:|=*'

# completer chain: exact, then spelling correction, then fuzzy/approximate with an
# error budget that scales with word length. fzf filters the candidate list itself,
# but _correct/_approximate also repair typos in the typed prefix, which fzf can't.
# https://zsh.sourceforge.io/Doc/Release/Completion-System.html#Control-Functions
zstyle ':completion:*' completer _complete _correct _approximate
zstyle -e ':completion:*:approximate:*' max-errors 'reply=($((($#PREFIX+$#SUFFIX)/3>7?7:($#PREFIX+$#SUFFIX)/3))numeric)'

# candidates
zstyle ':completion:*' special-dirs true        # offer the `.` and `..` directories
zstyle ':completion:*' use-cache yes            # cache results for completers that support it
zstyle ':completion:*' cache-path "${ZSH_CACHE_DIR}"

# `cd`: real subdirs, then the dir stack, then $cdpath — and never guess named dirs
zstyle ':completion:*:cd:*' tag-order local-directories directory-stack path-directories

# process lists (kill, etc.) via macOS ps, with the PID/owner colorized
zstyle ':completion:*:*:*:*:processes' command 'ps -u $USERNAME -o pid,user,comm -w -w'
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'

# hide macOS service accounts (_spotlight, _mdnsresponder, …) from `users`
# completion, but still show one if it is the only match
zstyle ':completion:*:*:*:*:users' ignored-patterns '_*'
zstyle '*' single-ignored show

# don't complete zsh's own completion/widget functions as function names
zstyle ':completion:*:functions' ignored-patterns '_*'

# git: never offer ORIG_HEAD as a ref, and keep checkout's native branch order
# https://stackoverflow.com/questions/12508595/ignore-orig-head-in-zsh-git-autocomplete#comment99936479_14325591
zstyle ':completion:*:*:git*:*' ignored-patterns '*ORIG_HEAD'
zstyle ':completion:*:git-checkout:*' sort false

# make: invoke the makefile so macro-defined targets are completed too
# https://unix.stackexchange.com/questions/657256/autocompletion-of-makefile-with-makro-in-zsh-not-correct-works-in-bash
zstyle ':completion::complete:make:*:targets' call-command true

# group matches by type; fzf-tab reads this format for its group headers (no color
# escapes here — fzf-tab strips them). The rest style zsh's status lines.
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*:messages' format '%d'
zstyle ':completion:*:warnings' format 'No matches for: %d'
zstyle ':completion:*:corrections' format '%d (errors: %e)'

# bash-style `complete -C` programmable completion (consul, nomad, tofu use it)
autoload -U +X bashcompinit && bashcompinit

# zsh/f-sy-h: feature-rich syntax highlighting for ZSH (loads last, after fzf-tab)
# https://github.com/z-shell/F-Sy-H
zi auto wait for z-shell/F-Sy-H

# zsh/autosuggestions: fish-like autosuggestions for zsh
# https://github.com/zsh-users/zsh-autosuggestions
zi auto atload"_zsh_autosuggest_start" \
    wait for zsh-users/zsh-autosuggestions

# zsh/autopair: automatically close quotes, brackets and other delimiters
# https://github.com/hlissner/zsh-autopair
zi auto wait for hlissner/zsh-autopair
```

## Deviations (documented)

1. **No README change.** Consistent with every prior tool ring — the fork's
   README documents no per-tool sections.
2. **Omit upstream tools the fork has never carried.** Upstream's end block
   continues past `# zsh/autopair` into `zsh-bench` (`romkatv/zsh-bench`) and a
   trailing `.envrc` (direnv) hook; the same commit's surrounding file also has
   `atuin` and `copier`. None are ported — they are out of scope. The fork's
   end block therefore stops after the autopair block. This is an omission of
   whole tool blocks, not a line-level edit to any ported line.

There are **no line-level deviations** within the ported completion/fzf/fzf-tab
slice; every ported line is byte-identical to upstream `236cfef`.

## Dependency analysis

- **Load order (the crux of the rework).** compinit now runs from
  `zsh-completions`' `atload"zicompinit; zicdreplay"` instead of F-Sy-H's
  `atinit`. Because `zsh-completions` adds its functions to `fpath` before its
  own `atload` fires, compinit sees them; `zicdreplay` then replays every
  `compdef` queued by the completion plugins loaded above (git completion,
  gcloud, opentofu, argcomplete, OMZ plugins). fzf-tab loads next (after
  compinit, so it can wrap the completion widget) and before the widget-wrapping
  plugins (autosuggestions, F-Sy-H) — which is why F-Sy-H now loads last with a
  plain `zi auto wait`.
- **`fzf` (new brew).** `zi auto has"fzf" wait for fzf` and
  `zi auto has"fzf" wait for Aloxaf/fzf-tab` are both guarded by `has"fzf"`, so
  they no-op until `brew "fzf"` is installed — safe to land in one commit. fzf's
  own zsh integration is loaded by the `fzf` z-a-auto plugin; `FZF_DEFAULT_OPTS`
  supplies the Catppuccin Mocha theme.
- **`bashcompinit`.** `autoload -U +X bashcompinit && bashcompinit` now backs
  the fork's existing `complete -C`-style completion — `:opentofu-load()` already
  calls `complete -o nospace -C tofu tofu`, which needs bashcompinit's `complete`
  shim. Previously this rode on whatever `OMZL::completion.zsh` provided; the
  rework makes the dependency explicit and owned.
- **`fzf-tab` IFS interaction.** The Ring 11 `:argcomplete-fix-ifs` helper
  already resets `IFS` for argcomplete's `_describe` call specifically so fzf-tab
  can capture matches; fzf-tab arriving in this ring is what that fix was written
  against. No change needed here.
- **Referenced variables all predate this ring.** `${ZSH_CACHE_DIR}` (set early
  in `.zshrc`), `LS_COLORS` (populated by `:dircolors-eval`), and the
  Apple-Silicon-only `ps`/macOS assumptions are all consistent with the existing
  fork (Apple-Silicon-only target).
- **No new helpers.** `add`/`has`/`link`, the `z-a-auto`/`z-a-eval` annexes, and
  the `zicompinit`/`zicdreplay` zinit functions all predate this ring.

## File inventory

### Create
- `docs/superpowers/specs/2026-06-06-zsh-dotfiles-ring12-design.md` (this file).
- `docs/superpowers/plans/2026-06-06-zsh-dotfiles-ring12.md` (+ `.tasks.json`).

### Modify
- `Brewfile` — add `brew "fzf"` (sorted position).
- `zsh/.zshrc` — §B (OMZ block), §C (remove top zstyle block), §D (dircolors
  load body), §E (new `# fzf` block), §F (end-block rework).

## Path mapping

- The `.zshrc` edits live in `~/.config/zsh/.zshrc` (already linked).
- `brew "fzf"` → installed by `brew bundle`.

## Verification

- **`Brewfile`:** `brew "fzf"` present in sorted position and byte-identical to
  upstream's line; the fork's `brew`/`cask` lines remain a strict subset of
  upstream `236cfef` (`comm -13 <(git show 236cfef:Brewfile | sort) <(sort
  Brewfile)` lists only the pre-existing Ring-10 `vscode
  "davidanson.vscode-markdownlint"` and nothing new from this ring);
  `brew bundle list --file=./Brewfile --all` parses.
- **`zsh/.zshrc` byte-identity:** each ported region diffs clean against
  `git show 236cfef:zsh/.zshrc` —
  - the OMZ block (§B) equals upstream's,
  - the top completion-zstyle block (§C) is gone,
  - the `:dircolors-load` body (§D) equals upstream's,
  - the `# fzf` block (§E) equals upstream's and sits between eza and gcloud,
  - the end block from `# zsh-completions:` through `# zsh/autopair` (§F) equals
    upstream's, ending at the autopair block (no `zsh-bench`/`.envrc`).
  Concretely: `comm -13 <(git show 236cfef:zsh/.zshrc | sort -u) <(sort -u
  zsh/.zshrc)` lists only fork-only lines from *other* (pre-existing) tools — no
  fork-only line originates in the completion/fzf/fzf-tab slice.
- **Syntax:** `zsh -n zsh/.zshrc` passes.
- **No stray remnants:** `COMPLETION_WAITING_DOTS`, `OMZL::completion.zsh`,
  `OMZL::grep.zsh`, the old `:completion:*:default` list-colors line, and
  F-Sy-H's `atinit"zicompinit; zicdreplay"` are all absent; `compinit` is invoked
  exactly once, from the `zsh-completions` `atload`.
- **Fresh-shell smoke test (best-effort, after `brew bundle install`):** in a
  new interactive shell, `fzf --version` works; TAB-completing a `cd` argument
  opens the fzf-tab menu with an eza directory preview; `tofu <TAB>` completes
  (bashcompinit
  active). Note the live `~/.config` on this machine tracks `hollow@main`, not
  the fork branch, so a full interactive smoke test of the branch is not
  meaningful here — same caveat as recent rings; byte-identity to the already-
  shipped upstream commit is the primary guarantee.

## Acceptance criteria

- `Brewfile` contains `brew "fzf"` in sorted position (between `findutils` and
  `gawk`), byte-identical to upstream; `brew bundle list --all` parses; the only
  fork-only Brewfile line is still the pre-existing Ring-10 `vscode
  "davidanson.vscode-markdownlint"` (this ring adds no new deviation).
- `zsh/.zshrc`: the OMZ block drops `COMPLETION_WAITING_DOTS`,
  `OMZL::completion.zsh`, and `OMZL::grep.zsh`; the top completion-zstyle block
  is removed; `:dircolors-load` uses the broadened `:completion:*` list-colors;
  the `# fzf` block is present between eza and gcloud; the end block is reordered
  to `zsh-completions (with atload compinit) → fzf-tab → # zsh/completion config
  → f-sy-h (no atinit) → autosuggestions → autopair`.
- Every ported completion/fzf/fzf-tab line is byte-identical to upstream
  `236cfef`; the only deviations are the omission of `zsh-bench`, `.envrc`,
  `atuin`, and `copier` (Deviation 2) and no README change (Deviation 1).
- `zsh -n zsh/.zshrc` passes; `compinit` is invoked exactly once.
- `LICENSE` and all prior-ring files are unchanged except the `Brewfile` and
  `zsh/.zshrc` edits described here.
