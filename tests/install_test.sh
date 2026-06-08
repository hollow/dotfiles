#!/bin/sh
# Unit tests for install.sh. Sources the script in library mode
# (DOTFILES_INSTALL_LIB=1) and exercises its functions in isolation.
#
# Run: sh tests/install_test.sh
set -u

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)

# Source install.sh as a library: defines the functions, does not run main.
DOTFILES_INSTALL_LIB=1 . "$ROOT/install.sh"
# install.sh runs `set -eu`; relax it so assertions can see non-zero status.
set +e

PASS=0
FAIL=0
ok()  { PASS=$((PASS + 1)); printf '  ok   - %s\n' "$1"; }
bad() { FAIL=$((FAIL + 1)); printf '  FAIL - %s\n' "$1"; }

echo "# is_remerge_remote"
for _u in \
    "https://github.com/remerge/dotfiles" \
    "https://github.com/remerge/dotfiles.git" \
    "git@github.com:remerge/dotfiles.git" \
    "ssh://git@github.com/remerge/dotfiles"; do
    if is_remerge_remote "$_u"; then ok "accept $_u"; else bad "accept $_u"; fi
done
for _u in \
    "https://github.com/marwa/dotfiles" \
    "https://github.com/remerge/other"; do
    if is_remerge_remote "$_u"; then bad "reject $_u"; else ok "reject $_u"; fi
done

echo
echo "Result: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && echo "ALL PASS"
[ "$FAIL" -eq 0 ]
