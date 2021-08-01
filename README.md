# dotfiles

This repository uses
[zinit](https://github.com/zdharma/zinit)
as a plugin and load manager for zsh.

Zinit will initialize
[Homebrew](https://github.com/Homebrew/brew)
for package management.

Additionally
[direnv](https://github.com/direnv/direnv)
is installed for project related environment management.

## Installation

```sh
git clone https://github.com/hollow/dotfiles ~/.config
ln -nfs ~/.config/zsh/.zshrc ~/.zshrc
exec zsh
```
