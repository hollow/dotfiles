# https://cloud.google.com/sdk/gcloud
_cask_install google-cloud-sdk
_path_add_bin "$(_cask_path google-cloud-sdk)"/latest/google-cloud-sdk

# make sure gsutil adheres to XDG
# https://github.com/GoogleCloudPlatform/gsutil/issues/991
export BOTO_CONFIG="${XDG_CONFIG_HOME}/boto/config"
export BOTO_PATH="${XDG_CONFIG_HOME}/boto"
echo "[GSUtil]\nstate_dir = ${XDG_CACHE_HOME}/gsutil" > "${BOTO_PATH}/state_dir"
