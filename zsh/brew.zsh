if [[ -d /Applications ]]; then
    # setup homebrew
    export HOMEBREW_BUNDLE_FILE="${XDG_CONFIG_HOME}/brew/packages"
    export HOMEBREW_BUNDLE_NO_LOCK=1
    export HOMEBREW_AUTO_UPDATE_SECS=86400
    export HOMEBREW_CLEANUP_MAX_AGE_DAYS=7
    export HOMEBREW_CLEANUP_PERIODIC_FULL_DAYS=1
    export HOMEBREW_NO_ANALYTICS=1

    # https://stackoverflow.com/a/18077919
    prefix_add /usr/local/opt/coreutils
    prefix_add /usr/local/opt/gnu-sed
    prefix_add /usr/local/opt/gnu-tar
    prefix_add /usr/local/opt/gnu-time
    prefix_add /usr/local/opt/openssl
fi
