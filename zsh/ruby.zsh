# https://www.ruby-lang.org
_brew_install -l ruby

# add gem paths
_gem_install_dir=$(ls -1d "${HOMEBREW_PREFIX}"/lib/ruby/gems/* | sort -V | tail -n1)
_ruby_version=${_gem_install_dir:t}
_path_add_bin "${HOMEBREW_PREFIX}"/lib/ruby/gems/${_ruby_version}
_path_add_bin "${XDG_DATA_HOME}"/gem/ruby/${_ruby_version}

# make ruby adhere to XDG
export BUNDLE_USER_CONFIG="${XDG_CONFIG_HOME}"/bundle
export BUNDLE_USER_CACHE="${XDG_CACHE_HOME}"/bundle
export BUNDLE_USER_PLUGIN="${XDG_DATA_HOME}"/bundle
