# https://cloud.google.com/sdk/gcloud
paths=("${ASDF_DATA_DIR}"/installs/gcloud/*/(NOn))

if [[ ! -r "${paths[1]}"/path.zsh.inc ]]; then
    asdf plugin add gcloud
    asdf install gcloud latest
fi

paths=("${ASDF_DATA_DIR}"/installs/gcloud/*/(NOn))
source ${paths[1]}/completion.zsh.inc
source ${paths[1]}/path.zsh.inc
unset paths

# make sure gsutil adheres to XDG
# https://github.com/GoogleCloudPlatform/gsutil/issues/991
export BOTO_CONFIG="${XDG_CONFIG_HOME}/boto/config"
export BOTO_PATH="${XDG_CONFIG_HOME}/boto"
echo "[GSUtil]\nstate_dir = ${XDG_CACHE_HOME}/gsutil" > "${BOTO_PATH}/state_dir"
alias gs=gsutil
