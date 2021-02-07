# https://gnupg.org/
# GNU Privacy Guard
_brew_install gnupg
export GNUPGHOME="${XDG_CONFIG_HOME}"/gnupg

# load ssh keys into agent
zinit light-mode lucid for \
    OMZP::gpg-agent
