#!/usr/bin/env bash

set -euo pipefail

gpg --import-options restore --import secret.gpg
gpg --import-ownertrust ownertrust.txt
