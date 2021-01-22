# make sure xdg directories work
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"

mkdir -p "${XDG_CONFIG_HOME}" \
         "${XDG_CACHE_HOME}" \
         "${XDG_DATA_HOME}"

# sane env variables types
typeset -TUx PATH path
typeset -TUx CPATH cpath
typeset -TUx MANPATH manpath
typeset -TUx LIBRARY_PATH library_path
typeset -TUx LD_LIBRARY_PATH ld_library_path
typeset -TUx PKG_CONFIG_PATH pkg_config_path

# sane default paths
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
MANPATH="${MANPATH:-$(man -w)}"

prefix_add() {
    set -- "$(realpath "$1")"

    if [[ -d "$1/bin" ]]; then
        path=("$1/bin" ${path})
    fi

    if [[ -d "${1}/libexec/gnubin" ]]; then
        path=("${1}/libexec/gnubin" ${path})
    fi

    if [[ -d "$1/include" ]]; then
        cpath=("$1/include" ${cpath})
    fi

    if [[ -d "$1/share/man" ]]; then
        manpath=("$1/share/man" ${manpath})
    fi

    if [[ -d "$1/libexec/gnuman" ]]; then
        manpath=("$1/libexec/gnuman" ${manpath})
    fi

    if [[ -d "$1/lib" ]]; then
        library_path=("$1/lib" ${library_path})
        ld_library_path=("$1/lib" ${ld_library_path})
        pkg_config_path=("$1/lib/pkgconfig" ${pkg_config_path})
    fi
}
