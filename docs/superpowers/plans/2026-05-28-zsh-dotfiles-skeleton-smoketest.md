# Fresh-Mac smoke test (manual)

Run on a clean macOS account (or a VM) after the repo is pushed to `main`.

1. Open Terminal and run:
   `curl -fsSL https://raw.githubusercontent.com/remerge/dotfiles/main/install.sh | sh`
2. Approve the Xcode Command Line Tools dialog when it appears; wait for install.
3. Expect: the installer clones into `~/.config`, links `~/.zshrc`, and drops
   you into a new zsh. The first prompt takes ~1 minute (Homebrew + bundle +
   zi + plugins).
4. Verify, in the new shell:
   - [ ] The starship prompt renders with icons (no "tofu" boxes) — confirms the
         Nerd Font installed.
   - [ ] Typing a known command (e.g. `gi`) shows a greyed autosuggestion.
   - [ ] Valid commands turn green / invalid turn red as you type (F-Sy-H).
   - [ ] Typing `(` auto-inserts `)` (autopair).
   - [ ] `<Tab>` after `git ` offers completions.
   - [ ] `command -v starship` resolves; `echo $ZDOTDIR` is `~/.config/zsh`.
5. Run `zup` and confirm it updates brew + zi without errors.
