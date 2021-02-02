source "${ZDOTDIR}"/config.zsh

# we have color support all the time
export EDITOR=${EDITOR:-vim}
export SHELL=${SHELL:-$ZSH_ARGZERO}
export TERM=${TERM:-xterm-256color}
export USER=${USER:-$(whoami)}

# fallback to sane locale
export LANG="${LANG:-en_US.UTF-8}"
export LC_CTYPE="${LC_CTYPE:-$LANG}"

# make sure xdg directories work
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"

mkdir -p "${XDG_CACHE_HOME}"
mkdir -p "${XDG_CONFIG_HOME}"
mkdir -p "${XDG_DATA_HOME}"

# path helpers
_path_add() {
    test -d "${2:P}" && \
    eval "${1}=(\"${2:P}\" \$${1})"
}

_path_add_bin() {
    _path_add path "$1"/bin
    _path_add path "$1"/sbin
    _path_add manpath "$1"/share/man
}

_path_add_lex() {
    _path_add path "$1"/libexec/bin
    _path_add path "$1"/libexec/gnubin
    _path_add manpath "$1"/libexec/man
    _path_add manpath "$1"/libexec/gnuman
}

_path_add_lib() {
    _path_add_bin "$1" # for good measure
    _path_add_lex "$1" # for good measure
    _path_add cpath "$1"/include
    _path_add library_path "$1"/lib
    _path_add ld_library_path "$1"/lib
    _path_add pkg_config_path "$1"/lib/pkgconfig
}

# sane default paths
typeset -TUx PATH path
typeset -TUx CPATH cpath
typeset -TUx MANPATH manpath
typeset -TUx LIBRARY_PATH library_path
typeset -TUx LD_LIBRARY_PATH ld_library_path
typeset -TUx PKG_CONFIG_PATH pkg_config_path

path=(
    "/usr/sbin"
    "/usr/bin"
    "/sbin"
    "/bin"
)

manpath=(
    "/usr/share/man"
)

library_path=(
    "/usr/lib"
)

ld_library_path=(
    "/usr/lib"
)

pkg_config_path=(
    "/usr/lib/pkgconfig"
)
