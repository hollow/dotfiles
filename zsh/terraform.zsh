# https://www.terraform.io/
alias tf=terraform

# make terraform adhere to XDG
ln -nfs "${XDG_CONFIG_HOME}"/terraform/config "${HOME}"/.terraformrc
ln -nfs "${XDG_CONFIG_HOME}"/terraform "${HOME}"/.terraform.d
mkdir -p "${XDG_CACHE_HOME}"/terraform/plugin-cache
