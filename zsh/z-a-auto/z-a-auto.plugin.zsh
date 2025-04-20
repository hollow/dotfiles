# Standardized $0 Handling
# https://wiki.zshell.dev/community/zsh_plugin_standard#zero-handling
0="${ZERO:-${${0:#$ZSH_ARGZERO}:-${(%):-%N}}}"
0="${${(M)0:#/*}:-$PWD/$0}"

:za-auto-null-handler() { :; }

:za-auto-init() {
    (( ${+ICE[with]} )) || return 0

    local ___ehid="${ICE[id-as]}" ___with="${ICE[with]}"
    local ___handlers="${ICE[atinit]/.za-auto-init\;(#c0,1)/}"
    debug "{func}[${___ehid}]{msg} with {msg2}${___with}{msg} handlers {msg2}${___handlers}"

    if (( ${+functions[:${___ehid}-init]} )) {
        :${___ehid}-init "$@"
    }

    return 0
}

:za-auto-load() {
    (( ${+ICE[with]} )) || return 0

    local ___ehid="${ICE[id-as]}" ___with="${ICE[with]}"
    local ___handlers="${ICE[atload]/.za-auto-load\;(#c0,1)/}"
    debug "{func}[${___ehid}]{msg} with {msg2}${___with}{msg} handlers {msg2}${___handlers}"

    if (( ${+functions[:${___ehid}-load]} )) {
        :${___ehid}-load "$@"
    }

    return 0
}

:za-auto-update() {
    (( ${+ICE[with]} )) || return 0

    local ___ehid="${ICE[id-as]}" ___with="${ICE[with]}"
    local ___handlers="${ICE[atclone]/.za-auto-update\;(#c0,1)/}"
    debug "{func}[${___ehid}]{msg} with {msg2}${___with}{msg} handlers {msg2}${___handlers}"

    case ${___with} in
        (pipx)
            pipx install ${___ehid}
            ;;
    esac

    if (( ${+functions[:${___ehid}-update]} )) {
        :${___ehid}-update "$@"
    }

    return 0
}

:za-auto-command() {
    builtin emulate -L zsh ${=${options[xtrace]:#off}:+-o xtrace}
    builtin setopt extended_glob warn_create_global typeset_silent no_short_loops rc_quotes no_auto_pushd

    [[ $1 == auto ]] && shift

    local -A ZI_ICES
    local ___argv="$@" __iceret=0
    .zi-ice "$@"; __iceret=$?

    local -a ___ices=(${@[0,${__iceret}]})
    shift ${__iceret}

    if [[ $# -gt 0 ]] { shift }
    if [[ $# -gt 1 ]] {
        +zi-message "{annex}${funcstack[1]}{ehi}:{rst}{msg} Too many arguments after ice parsing{ehi}: {nb}{error}${(qkv)@}{msg}{rst}"
        return 1
    }

    # infer handle (id) and remote (teleid) from other ice values
    .zi-any-to-user-plugin "${${1#@}%%(///|//|/)}"
    local ___user="${reply[-2]}" ___plugin="${reply[-1]}"

    if [[ ${___plugin} == "_unknown" ]] {
        +zi-message "{annex}${funcstack[1]}{ehi}:{rst}{msg} Invalid plugin specification:{ehi}: {nb}{error}${1}{msg}{rst}"
        return 1
    }

    local -a ___parts=(${(s/:/)___plugin})
    local ___ehid="${ZI_ICES[id-as]:-${${___parts[-1]}:t}}"

    if [[ -z ${___user} && ${___plugin} != *'::'* ]] {
        ___user="z-shell"
        ___plugin="null"
    }

    local ___etid="${ZI_ICES[teleid]:-${___user}${${___user:#(%|/)*}:+/}${___plugin}}"

    # automatically add `as"null"` when using the null repo
    if [[ "${___etid}" == "z-shell/null" ]] {
        ___ices+=(as"null")
    }

    # add eval hook function if they exist
    if (( ${+functions[:${___ehid}-eval]} )) {
        ___ices+=(eval=:${___ehid}-eval)
    }

    if ! (( ${+ZI_ICES[id-as]} )) {
        ___ices+=(id-as"${___ehid}")
    }

    if ! (( ${+ZI_ICES[with]} )) {
        ___ices+=(with"custom")
    }

    debug "{func}[${___ehid}]{rst}" "{msg}${___argv[*]}{rst}"
    zi "${___ices[@]}" for "${___etid}"
}

@zi-register-annex "z-a-auto" \
    subcommand:auto \
    :za-auto-command \
    :za-auto-null-handler \
    "with''"

@zi-register-annex "z-a-auto" \
    hook:atclone-50 \
    :za-auto-update \
    :za-auto-null-handler

@zi-register-annex "z-a-auto" \
    hook:atpull-50 \
    :za-auto-update \
    :za-auto-null-handler

@zi-register-annex "z-a-auto" \
    hook:atload-50 \
    :za-auto-load \
    :za-auto-null-handler

@zi-register-annex "z-a-auto" \
    hook:atinit-50 \
    :za-auto-init \
    :za-auto-null-handler
