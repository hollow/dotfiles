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
        local session="${ITERM_PROFILE:+iterm}"
        command tmux ${ITERM_PROFILE+-CC} \
            new-session -A -s ${session:-default}
        exit
    fi
}

# Autostart if not already in tmux and enabled.
if [[ -z "$TMUX" && -z "$VIM" && "$ZSH_TMUX_AUTOSTARTED" != "true" ]]; then
    export ZSH_TMUX_AUTOSTARTED=true
    _zsh_tmux_plugin_run
fi
