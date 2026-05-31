# Ring 2 smoke test (manual)

On a Mac after merging and opening a fresh shell:

- [ ] `l` lists files via eza, colorized (LS_COLORS active).
- [ ] `bat README.md` paginates with the Catppuccin theme; `man ls` is colorized.
- [ ] `df` invokes duf (table output).
- [ ] `glow README.md` renders markdown with the Catppuccin Mocha theme.
- [ ] Typing a command that has an alias triggers a `you-should-use` reminder.
- [ ] `gd`, `gdc`, `gl`, `s` work; `gcm`/`gcl`/`gdm` resolve the main branch
      (via the `git-main-branch` subcommand).
- [ ] `git config user.email` is empty until you edit `~/.config/git/local`;
      after editing, it reflects your address and commits use it.
- [ ] `rg`, `fd` run (installed via Brewfile; no shell config needed).
