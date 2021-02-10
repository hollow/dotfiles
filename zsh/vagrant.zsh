# https://www.vagrantup.com
# build and distribute development environments
if [[ "${OSTYPE}" == darwin* ]]; then
    _cask_install vagrant
fi

export VAGRANT_HOME="${XDG_DATA_HOME}"/vagrant
export VAGRANT_ALIAS_FILE="${XDG_DATA_HOME}"/vagrant/aliases
