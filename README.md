# dotfiles

## Installation

```sh
git clone https://github.com/hollow/dotfiles ~/.config
ln -nfs ~/.config/zsh/config.zsh ~/.zshenv
exec zsh
```

## ZSH

This repository uses
[zinit](https://github.com/zdharma/zinit)
as a plugin and load manager for zsh.

Zinit will initialize
[Homebrew](https://github.com/Homebrew/brew) and
[asdf](https://github.com/asdf-vm/asdf)
as package and version managers.

Additionally
[direnv](https://github.com/direnv/direnv)
is installed for project related environment management.

The following zsh plugins are available by default:

- [chuwy/zsh-secrets](https://github.com/chuwy/zsh-secrets)
- [hlissner/zsh-autopair](https://github.com/hlissner/zsh-autopair)
- [ohmyzsh/clipboard](https://github.com/ohmyzsh/ohmyzsh/blob/master/lib/clipboard.zsh)
- [ohmyzsh/completion](https://github.com/ohmyzsh/ohmyzsh/blob/master/lib/completion.zsh)
- [romkatv/powerlevel10k](https://github.com/romkatv/powerlevel10k)
- [trapd00r/LS_COLORS](https://github.com/trapd00r/LS_COLORS)
- [zdharma/fast-syntax-highlighting](https://github.com/zdharma/fast-syntax-highlighting)
- [zsh-users/zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
- [zsh-users/zsh-completions](https://github.com/zsh-users/zsh-completions)

## TMUX

This repository uses the
[tmux plugin manager(tpm)](https://github.com/tmux-plugins/tpm)
as a plugin and load manager for tmux.

The following tmux plugins are available by default:

- [NHDaly/tmux-better-mouse-mode](https://github.com/NHDaly/tmux-better-mouse-mode)
- [seebi/tmux-colors-solarized](https://github.com/seebi/tmux-colors-solarized)
- [tmux-plugins/tmux-continuum](https://github.com/tmux-plugins/tmux-continuum)
- [tmux-plugins/tmux-pain-control](https://github.com/tmux-plugins/tmux-pain-control)
- [tmux-plugins/tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect)
- [tmux-plugins/tmux-sensible](https://github.com/tmux-plugins/tmux-sensible)
- [tmux-plugins/tmux-sessionist](https://github.com/tmux-plugins/tmux-sessionist)

## GPG and SSH

For security and compatibility reasons zinit will install
[OpenSSH](https://github.com/openssh/openssh-portable) and
[GnuPG](https://gnupg.org/)
from Homebrew.

Zinit will also start a `gpg-agent` which is enabled for SSH authentication as
well.

Refer to [this article](https://opensource.com/article/19/4/gpg-subkeys-ssh)
for instructions to setup a dedicated authentication key in your keyring.

## Awesome Tools

These awesome tools are installed from Homebrew by zinit:

- [brona/iproute2mac](https://github.com/brona/iproute2mac)
- [BurntSushi/ripgrep](https://github.com/BurntSushi/ripgrep)
- [Canop/broot](https://github.com/Canop/broot)
- [chmln/sd](https://github.com/chmln/sd)
- [dbrgn/tealdeer](https://github.com/dbrgn/tealdeer)
- [defunkt/gist](https://github.com/defunkt/gist)
- [denilsonsa/prettyping](https://github.com/denilsonsa/prettyping)
- [htop-dev/htop](https://github.com/htop-dev/htop)
- [imapsync/imapsync](https://github.com/imapsync/imapsync)
- [jiahaog/nativefier](https://github.com/jiahaog/nativefier)
- [jpoliv/wakeonlan](https://github.com/jpoliv/wakeonlan)
- [junegunn/fzf](https://github.com/junegunn/fzf)
- [mas-cli/mas](https://github.com/mas-cli/mas)
- [measurement-factory/dnstop](https://github.com/measurement-factory/dnstop)
- [mptre/yank](https://github.com/mptre/yank)
- [muesli/duf](https://github.com/muesli/duf)
- [neovim/neovim](https://github.com/neovim/neovim)
- [nmap/nmap](https://github.com/nmap/nmap)
- [ntop/ntopng](https://github.com/ntop/ntopng)
- [ogham/dog](https://github.com/ogham/dog)
- [ogham/exa](https://github.com/ogham/exa)
- [sharkdp/bat](https://github.com/sharkdp/bat)
- [sharkdp/diskus](https://github.com/sharkdp/diskus)
- [sharkdp/fd](https://github.com/sharkdp/fd)
- [sivel/speedtest-cli](https://github.com/sivel/speedtest-cli)
- [sqshq/sampler](https://github.com/sqshq/sampler)
- [tj/git-extras](https://github.com/tj/git-extras)
- [traviscross/mtr](https://github.com/traviscross/mtr)
- [wfxr/forgit](https://github.com/wfxr/forgit)
- [xxxserxxx/gotop](https://github.com/xxxserxxx/gotop)
