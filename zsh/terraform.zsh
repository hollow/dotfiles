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
ln -nfs "${XDG_CONFIG_HOME}"/terraform/config "${HOME}"/.terraformrc
ln -nfs "${XDG_CONFIG_HOME}"/terraform "${HOME}"/.terraform.d
mkdir -p "${XDG_CACHE_HOME}"/terraform/plugin-cache
