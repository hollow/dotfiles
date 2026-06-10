# Demo of the terminal features for the README (demo.gif).
#
# Re-record from the repo root with: vhs demo.tape
# Requires: brew install vhs (and the dotfiles installed, since the
# recording sources your ~/.zshrc).
Output demo.gif

Set Shell zsh
Set FontFamily "MesloLGS Nerd Font"
Set FontSize 14
Set Width 1200
Set Height 660
Set Padding 16
Set Theme "Catppuccin Mocha"
Set TypingSpeed 70ms

# VHS starts a bare zsh, so load the dotfiles config off-screen, then swap in
# an empty history so autosuggestions can't leak setup commands or anything
# from the real shell history.
Hide
Sleep 2s
Type "source ~/.zshrc"
Enter
# give ZI's turbo mode time to load all plugins
Sleep 10s
Type "fc -p /tmp/vhs-demo-history 64 64"
Enter
Sleep 500ms
Type "clear"
Enter
Sleep 2s
Show

Sleep 1s

# 1. Starship prompt + syntax highlighting + git awareness
Type "git status"
Sleep 800ms
Enter
Sleep 2.5s

# 2. eza: ls with icons and git status
Type "l"
Sleep 600ms
Enter
Sleep 3s

# 3. fzf-tab: fuzzy completion menu with previews
Type "cd "
Sleep 500ms
Tab
Sleep 2s
Type "zsh"
Sleep 1.5s
Enter
Sleep 800ms
Enter
Sleep 1.5s
Type "l"
Enter
Sleep 2.5s
Type "cd .."
Enter
Sleep 1s

# 4. autosuggestions: grey suggestion from history, accept with right arrow
Type "git"
Sleep 2s
Right
Sleep 1.5s
Enter
Sleep 2s

# 5. bat: cat with syntax highlighting
Type "bat install.sh"
Sleep 800ms
Enter
Sleep 4s
Type "q"
Sleep 1.5s
