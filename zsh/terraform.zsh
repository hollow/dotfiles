# https://www.terraform.io/
_brew_install terraform
alias tf=terraform

# make terraform adhere to XDG
export TF_CLI_CONFIG_FILE="${XDG_CONFIG_HOME}"/terraform/config
mkdir -p "${XDG_CACHE_HOME}"/terraform/plugin-cache

# https://terraspace.cloud
if ! (( $+commands[terraspace] )); then
    gem install terraspace
fi
alias ts=terraspace
