_brew_install -x python

# https://github.com/danhper/asdf-python
# asdf-python can automatically install a default set of Python packages with
# pip right after installing a Python version.
export ASDF_PYTHON_DEFAULT_PACKAGES_FILE="${XDG_CONFIG_HOME}"/python/packages
