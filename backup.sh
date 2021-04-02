#!/usr/bin/env bash

set -euo pipefail
cd "$(realpath -m "$0"/..)"

if ! type -P bw; then
    echo -e "\n>>> installing bitwarden-cli\n"
    brew install bitwarden-cli
fi

echo -e "\n>>> creating new dotfile backup\n"

read -erp "private key id: " -i "${RECEPIENT}" RECEPIENT
read -erp "bitwarden server url: " -i "${BW_URL:-$(bw config server)}" BW_URL
bw --quiet config server "${BW_URL}"

item="{
    type: 2,
    name: \"dotfiles backup ($(date +%Y%m%dT%H%M%SZ))\",
    notes: \"To restore from backup download attachment, unpack and run restore.sh\",
    secureNote: { type: 0 }
}"

tmp="$(mktemp -d)"
trap '{ rm -rf -- "${tmp}"; }' EXIT

if bw --quiet login --check; then
    echo -e "\n>>> unlocking existing vault"
    BW_SESSION="$(bw unlock --raw)"
else
    echo -e "\n>>> login to bitwarden at ${BW_URL}"
    BW_SESSION="$(bw login --raw)"
fi

export BW_SESSION

echo -e "\n>>> exporting private key"
gpg --export-options backup --export-secret-keys "${RECEPIENT}" >"${tmp}"/secret.gpg

echo ">>> exporting ownertrust"
gpg --export-ownertrust >"${tmp}"/ownertrust.txt

echo ">>> generating revocation certificate"
printf "Y\n0\n\nY\n" | gpg --command-fd 0 --gen-revoke "${RECEPIENT}" >"${tmp}"/revoke.crt

echo ">>> collectiong zsh secrets"
mkdir -p "${tmp}"/secrets
cp -a "${XDG_CONFIG_HOME}"/secrets/* "${tmp}"/secrets

echo -e "\n\n>>> backup complete - creating archive"
cp -a "${XDG_CONFIG_HOME}"/restore.sh "${tmp}"/restore.sh
tar cjvpf "${RECEPIENT}".tar.xz -C "${tmp}" .
trap '{ rm -f -- "${RECEPIENT}".tar.xz; }' EXIT

echo -e "\n>>> uploading archive to bitwarden"
item="$(bw get template item | jq ". + ${item}" | bw encode | bw create item | jq -r .id)"
bw create attachment --file "${RECEPIENT}".tar.xz --itemid "${item}" | jq

exit 0
