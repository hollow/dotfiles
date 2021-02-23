# https://www.terraform.io/
_brew_install terraform
alias tf=terraform

# make terraform adhere to XDG
export TF_CLI_CONFIG_FILE="${XDG_CONFIG_HOME}"/terraform/config
export TF_PLUGIN_CACHE_DIR="${XDG_CACHE_HOME}"/terraform/plugin-cache
mkdir -p "${TF_PLUGIN_CACHE_DIR}"

# https://terragrunt.gruntwork.io/
_brew_install terragrunt
alias tg=terragrunt
