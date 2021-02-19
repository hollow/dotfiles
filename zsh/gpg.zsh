# https://gnupg.org/
# GNU Privacy Guard
_brew_install gnupg
export GNUPGHOME="${XDG_CONFIG_HOME}"/gnupg

# load ssh keys into agent
zinit light-mode lucid for \
    OMZP::gpg-agent

# https://github.com/chuwy/zsh-secrets
# store gpg encrypted environment variables
zinit light-mode lucid for \
    @chuwy/zsh-secrets

export RECEPIENT="$(gpg --with-colons --list-secret-keys | sed -nr 's/^uid:.*<(.*)>.*/\1/p')"
export SECRETS_STORAGE="${XDG_CONFIG_HOME}/secrets"
mkdir -p "${SECRETS_STORAGE}"

_has_secret() {
    if [[ -e "${SECRETS_STORAGE}/${1}.gpg" ]]; then
        secrets source "${1}" 2>/dev/null || return 1
        return 0
    else
        return 1
    fi
}
