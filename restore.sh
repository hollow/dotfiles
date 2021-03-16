#!/usr/bin/env bash

set -euo pipefail
cd "$(realpath -m "$0"/..)"

set -x

gpg --import-options restore --import secret.gpg
gpg --import-ownertrust ownertrust.txt

mkdir -p "${XDG_CONFIG_HOME}"/secrets
cp secrets/* "${XDG_CONFIG_HOME}"/secrets
