# use git from homebrew
_brew_install git

# https://github.com/ohmyzsh/ohmyzsh/blob/master/lib/git.zsh
# load git functions from ohmyzsh
zinit light-mode lucid for \
    atinit'zstyle ":completion:*:*:git:*" script "${HOMEBREW_ZSH_FUNCTIONS}"/git-completion.bash' \
    OMZL::git.zsh

# Git & GitHub Secrets
# https://docs.github.com/en/github/authenticating-to-github/creating-a-personal-access-token
#
# > secrets decrypt git
# export GIT_AUTHOR_NAME="John Developer"
# export GIT_AUTHOR_EMAIL="john@developer.com"
# export GIT_COMMITTER_NAME="${GIT_AUTHOR_NAME}"
# export GIT_COMMITTER_EMAIL="${GIT_AUTHOR_EMAIL}"
# export GITHUB_TOKEN="123456789abcdef"
# echo ${GITHUB_TOKEN} > "${HOME}"/.gist
_has_secret git

# https://github.com/tj/git-extras
# lots of git utilities
_brew_install git-extras

# https://github.com/github/hub
# a command-line tool that makes git easier to use with GitHub
_brew_install hub
alias git=hub

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
alias s="git st ."

# clone a repository into ~/src/<owner>/<name>
# and cd into it afterwards
clone() {
    dir="$(clone-into-src "$@")"
    if [[ -n "${dir}" ]]; then
        cd "${dir}" || return
    fi
}
