# https://github.com/tmux/tmux
# terminal multiplexer
function tmux() {
    if [[ $# -gt 0 ]]; then
        command tmux "$@"
        return $?
    fi

    local session="default"

    if [[ "${TERM_PROGRAM}" == "iTerm.app" ]]; then
        session="iterm"
    elif [[ "${TERM_PROGRAM}" == "vscode" ]]; then
        session="${PWD#${HOME}/}"
        session="${session#.}"
        session="${session/./-}"
    fi

    export ZSH_TMUX_SESSION_NAME="${session}"
    command tmux new-session -A -s "${ZSH_TMUX_SESSION_NAME}"
}
