# https://github.com/junegunn/fzf
# A command-line fuzzy finder
typeset -TUx FZF_DEFAULT_OPTS fzf_default_opts ' '
fzf_default_opts=(
    "--ansi"
    "--cycle"
    "--preview-window='right:60%'"
    "--bind='?:toggle-preview'"
    "--prompt='❯ '"
    "--color='bg+:#073642,bg:#002b36,spinner:#719e07,hl:#586e75'"
    "--color='fg:#839496,header:#586e75,info:#cb4b16,pointer:#719e07'"
    "--color='marker:#719e07,fg+:#839496,prompt:#719e07,hl+:#719e07'"
)

export FZF_DEFAULT_COMMAND="fd --type f --hidden"
export FZF_CTRL_T_COMMAND="fd --type f --hidden"
export FZF_ALT_C_COMMAND="fd --type d --hidden"

export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers,changes --wrap never --color always {} || cat {} || exa -T {}'"
export FZF_CTRL_R_OPTS="--preview 'echo {}' --preview-window down:3:wrap:hidden"
export FZF_ALT_C_OPTS="--preview 'exa -T {}'"

if [[ "${OSTYPE}" == darwin* ]]; then
    source "${HOMEBREW_PREFIX}"/opt/fzf/shell/key-bindings.zsh
else
    source "/usr/share/doc/fzf/examples/key-bindings.zsh"
fi

# Find matches in files and edit them
# mnemonic: [F]ind in [F]ile
ff() {
    FZF_DEFAULT_COMMAND="rg --files" fzf \
        --multi --disabled \
        --bind "enter:execute($EDITOR {1})" \
        --bind "change:reload:rg --files-with-matches {q} || true" \
        --preview "env -u RIPGREP_CONFIG_PATH batgrep --color --smart-case --context 3 {q} {}" \
}
