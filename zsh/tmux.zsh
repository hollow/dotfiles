# https://github.com/tmux/tmux
# terminal multiplexer
_brew_install tmux

# https://github.com/tmuxinator/tmuxinator
# manage complex tmux sessions easily
_brew_install tmuxinator

# wrapper function for tmux
function _zsh_tmux_plugin_run() {
    if [[ -n "$@" ]]; then
        command tmux "$@"
        return $?
    else
        command tmux new-session -A -s "${ZSH_TMUX_SESSION_NAME}"
        exit
    fi
}

_zsh_tmux_session_name="default"

if [[ "${TERM_PROGRAM}" == "iTerm.app" ]]; then
    _zsh_tmux_session_name="iterm"
elif [[ "${TERM_PROGRAM}" == "vscode" ]]; then
    _zsh_tmux_session_name="${PWD#${HOME}/}"
    _zsh_tmux_session_name="${_zsh_tmux_session_name#.}"
    _zsh_tmux_session_name="${_zsh_tmux_session_name/./-}"
fi

if [[ -z "${TMUX}" && "${ZSH_TMUX_SESSION_NAME}" != "${_zsh_tmux_session_name}" ]]; then
    export ZSH_TMUX_SESSION_NAME="${_zsh_tmux_session_name}"
    _zsh_tmux_plugin_run
fi

unset _zsh_tmux_session_name
