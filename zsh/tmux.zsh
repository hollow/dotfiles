# https://github.com/tmux/tmux
# terminal multiplexer
_brew_install tmux

# https://github.com/tmuxinator/tmuxinator
# manage complex tmux sessions easily
_brew_install tmuxinator

# wrapper function for tmux
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
