# https://www.terraform.io/
_brew_install terraform
alias tf=terraform

# https://terragrunt.gruntwork.io/
_brew_install terragrunt
alias tg=terragrunt

ti() {
    terragrunt init -reconfigure -upgrade
}

ta() {
    terragrunt apply -compact-warnings
}

# make terraform adhere to XDG
export TF_CLI_CONFIG_FILE="${XDG_CONFIG_HOME}"/terraform/config
export TF_PLUGIN_CACHE_DIR="${XDG_CACHE_HOME}"/terraform/plugin-cache
mkdir -p "${TF_PLUGIN_CACHE_DIR}"
