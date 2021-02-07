# set these here from config.zsh instead of adding
# personal information to git/config
export GIT_AUTHOR_NAME="${DEFAULT_NAME}"
export GIT_AUTHOR_EMAIL="${DEFAULT_EMAIL}"
export GIT_COMMITTER_NAME="${DEFAULT_NAME}"
export GIT_COMMITTER_EMAIL="${DEFAULT_EMAIL}"

# use git from homebrew
_brew_install git

# https://github.com/ohmyzsh/ohmyzsh/blob/master/lib/git.zsh
# load git functions from ohmyzsh
zinit light-mode lucid for \
    atinit'zstyle ":completion:*:*:git:*" script "${HOMEBREW_ZSH_FUNCTIONS}"/git-completion.bash' \
    OMZL::git.zsh

# make sure completion can find bash helpers

# https://github.com/dandavison/delta
# A viewer for git and diff output
_brew_install git-delta

# https://github.com/tj/git-extras
# lots of git utilities
_brew_install git-extras

# https://github.com/wfxr/forgit
# interactive git tools
zinit light-mode lucid for \
    @wfxr/forgit

export FORGIT_FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS} --no-height --reverse"

# https://github.com/defunkt/gist
# command line gister
_brew_install gist

alias c="git changes"
alias ga="git add --all"
alias gap="git add --patch"
alias gcm="git co \$(git main-branch)"
alias gcu="git co upstream"
alias gd="git df"
alias gdc="git dc"
alias gdm="git df \$(git main-branch)"
alias gdu="git df upstream"
alias gl="git lg"
alias gp="git pull"
alias gpr="git pull --rebase --autostash"
alias grh="git reset HEAD"
alias s="git st"

# clone a repository into ~/src/<owner>/<name>
# and cd into it afterwards
clone() {
    dir="$(clone-into-src "$@")"
    if [[ -n "${dir}" ]]; then
        cd "${dir}" || return
    fi
}
