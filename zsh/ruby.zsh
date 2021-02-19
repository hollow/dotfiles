# https://www.ruby-lang.org
_brew_install ruby

# make ruby adhere to XDG
export BUNDLE_USER_CONFIG="${XDG_CONFIG_HOME}"/bundle
export BUNDLE_USER_CACHE="${XDG_CACHE_HOME}"/bundle
export BUNDLE_USER_PLUGIN="${XDG_DATA_HOME}"/bundle
