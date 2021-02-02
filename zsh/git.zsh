# set these here from config.zsh instead of adding
# personal information to git/config
export GIT_AUTHOR_NAME="${DEFAULT_NAME}"
export GIT_AUTHOR_EMAIL="${DEFAULT_EMAIL}"
export GIT_COMMITTER_NAME="${DEFAULT_NAME}"
export GIT_COMMITTER_EMAIL="${DEFAULT_EMAIL}"

# https://github.com/ohmyzsh/ohmyzsh/blob/master/lib/git.zsh
# load git functions from ohmyzsh
zinit for OMZL::git.zsh

# make sure completion can find bash helpers
zstyle ':completion:*:*:git:*' script \
    "${HOMEBREW_PREFIX}"/share/zsh/site-functions/git-completion.bash

# https://github.com/dandavison/delta
# A viewer for git and diff output
_brew_install git-delta

# https://github.com/tj/git-extras
# lots of git utilities
_brew_install git-extras

# https://github.com/wfxr/forgit
# interactive git tools
zinit for @wfxr/forgit
export FORGIT_FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS} --no-height --reverse"

alias ga="git add --all"
alias gap="git add --patch"
alias gca="git commit --all"
alias gcaa="git commit --all --amend"
alias gcm="git checkout master"
alias gcu="git checkout upstream"
alias gd="git diff -b"
alias gdc="gd --cached"
alias gdm="gd master"
alias gl="git lg"
alias gp="git pull"
alias gpr="git pull --rebase --autostash"
alias grh="git reset HEAD"
alias s="git status -sb ."

clone() {
    dir="$(clone-into-src "$@")"
    if [[ -n "${dir}" ]]; then
        cd "${dir}" || return
    fi
}
