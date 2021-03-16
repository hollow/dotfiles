#!/usr/bin/env bash

set -euo pipefail

echo -e "\n>>> creating new gpg secret key backup\n"

read -erp "private key id: " -i "${RECEPIENT}" RECEPIENT
read -erp "bitwarden server url: " -i "${BW_URL:-$(bw config server)}" BW_URL
bw --quiet config server "${BW_URL}"

item="{
    type: 2,
    name: \"GPG Secret Key (${RECEPIENT}) ($(date +%Y%m%dT%H%M%SZ))\",
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

echo -e "\n\n>>> backup complete - creating archive"
cp -a "$(dirname "$0")"/restore.sh "${tmp}"/restore.sh
tar cjvpf "${RECEPIENT}".tar.xz -C "${tmp}" .

echo -e "\n>>> uploading archive to bitwarden"
item="$(bw get template item | jq ". + ${item}" | bw encode | bw create item | jq -r .id)"
bw create attachment --file "${RECEPIENT}".tar.xz --itemid "${item}" | jq

exit 0
