# User paths
export ZDOTDIR=${${(%):-%x}:A:h}
export XDG_CONFIG_HOME=${ZDOTDIR:h}
export XDG_CACHE_HOME="${HOME}/.cache"
export XDG_DATA_HOME="${HOME}/.local/share"

# System paths
typeset -TUx PATH path=("${XDG_CONFIG_HOME}/bin" /{usr/,}{local/,}{s,}bin)
typeset -TUx MANPATH manpath=(${(s[:])$(manpath)})
typeset -TUx FPATH fpath=(${ZDOTDIR} ${fpath[@]})

# Path helpers
.path-add() {
    test -d ${2:P} && \
    eval "${1}=(\"${2:P}\" \$${1})"
}

.path-add-bin() {
    .path-add path "${1}/bin"
    .path-add path "${1}/sbin"
    .path-add manpath "${1}/share/man"
}

.path-add-gnu() {
    .path-add path "${1}/libexec/gnubin"
    .path-add manpath "${1}/libexec/gnuman"
}

.path-add-libexec() {
    .path-add path "${1}/libexec/bin"
    .path-add manpath "${1}/libexec/man"
}

.path-add-lib() {
    .path-add-bin "${1}"
    .path-add-lex "${1}"
    .path-add cpath "${1}/include"
    .path-add library_path "${1}/lib"
    .path-add ld_library_path "${1}/lib"
    .path-add pkg_config_path "${1}/lib/pkgconfig"
}
