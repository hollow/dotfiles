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
echo "# place_dotfiles scenarios"

# A throwaway git env so tests never touch the user's real git identity/config.
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
export HOME="$WORK/home"; mkdir -p "$HOME"
export GIT_CONFIG_GLOBAL="$WORK/gitconfig"; : > "$GIT_CONFIG_GLOBAL"
export GIT_CONFIG_NOSYSTEM=1
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t
export GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t

# Build a fake "remerge/dotfiles" repo (REPO) with two tracked files.
REPO="$WORK/remerge"
git init -q -b main "$REPO"
printf 'brew-upstream\n' > "$REPO/Brewfile"
mkdir -p "$REPO/zsh"; printf 'zsh-upstream\n' > "$REPO/zsh/.zshrc"
git -C "$REPO" add -A
git -C "$REPO" commit -qm upstream

# For flow tests, treat the local REPO path as "remerge". (The real
# is_remerge_remote — verified above — only matches github.com/remerge/dotfiles,
# which a local fake repo can't be.)
is_remerge_remote() { [ "${1%.git}" = "$REPO" ]; }
# confirm stub: never show the full diff; CONFIRM=yes/no drives action prompts.
confirm() {
    case "$1" in
        *"full diff"*) return 1 ;;
    esac
    [ "${CONFIRM:-no}" = yes ]
}

# Scenario 1: empty/absent dir -> clone (no prompt needed).
C="$WORK/c1"
CONFIRM=no; ( place_dotfiles "$C" "$REPO" ) > /dev/null 2>&1; rc=$?
if [ "$rc" -eq 0 ] && [ "$(cat "$C/Brewfile")" = brew-upstream ]; then
    ok "clone into empty dir"
else
    bad "clone into empty dir"
fi

# Scenario 2: non-empty, no .git -> adopt; conflict overwritten, keep preserved.
C="$WORK/c2"; mkdir -p "$C"
printf 'brew-PREEXISTING\n' > "$C/Brewfile"   # untracked, also in repo -> overwrite
printf 'KEEP\n' > "$C/age.txt"                # untracked, not in repo -> preserve
CONFIRM=yes; ( place_dotfiles "$C" "$REPO" ) > /dev/null 2>&1; rc=$?
if [ "$rc" -eq 0 ] && [ "$(cat "$C/Brewfile")" = brew-upstream ] \
    && [ "$(cat "$C/age.txt")" = KEEP ] \
    && [ "$(git -C "$C" rev-parse --abbrev-ref 'main@{u}' 2> /dev/null)" = origin/main ]; then
    ok "adopt non-git dir (overwrite conflict, keep extras, main tracks origin)"
else
    bad "adopt non-git dir (overwrite conflict, keep extras, main tracks origin)"
fi

# Scenario 3: foreign repo + confirm yes -> re-point origin and restore.
C="$WORK/c3"; OTHER="$WORK/other"
git init -q -b main "$OTHER"; printf 'brew-FORK\n' > "$OTHER/Brewfile"
git -C "$OTHER" add -A; git -C "$OTHER" commit -qm fork
git clone -q "$OTHER" "$C"
printf 'KEEP3\n' > "$C/age.txt"               # untracked, preserve
CONFIRM=yes; ( place_dotfiles "$C" "$REPO" ) > /dev/null 2>&1; rc=$?
if [ "$rc" -eq 0 ] && [ "$(git -C "$C" remote get-url origin)" = "$REPO" ] \
    && [ "$(cat "$C/Brewfile")" = brew-upstream ] \
    && [ "$(cat "$C/age.txt")" = KEEP3 ]; then
    ok "foreign repo, confirmed: re-point + restore + keep extras"
else
    bad "foreign repo, confirmed: re-point + restore + keep extras"
fi

# Scenario 4: foreign repo + confirm no -> abort, origin unchanged.
C="$WORK/c4"
git clone -q "$OTHER" "$C"
CONFIRM=no; ( place_dotfiles "$C" "$REPO" ) > /dev/null 2>&1; rc=$?
if [ "$rc" -ne 0 ] && [ "$(git -C "$C" remote get-url origin)" = "$OTHER" ]; then
    ok "foreign repo, declined: aborts, origin untouched"
else
    bad "foreign repo, declined: aborts, origin untouched"
fi

# Scenario 5: already-remerge with a local tracked edit -> restore on confirm.
C="$WORK/c5"
git clone -q "$REPO" "$C"
printf 'brew-LOCAL-EDIT\n' > "$C/Brewfile"
CONFIRM=yes; ( place_dotfiles "$C" "$REPO" ) > /dev/null 2>&1; rc=$?
if [ "$rc" -eq 0 ] && [ "$(cat "$C/Brewfile")" = brew-upstream ]; then
    ok "already-remerge, dirty: edit discarded"
else
    bad "already-remerge, dirty: edit discarded"
fi

# Scenario 6: already-remerge and clean -> short-circuit (no file changes) but
# still re-establishes main's upstream tracking.
C="$WORK/c6"
git clone -q "$REPO" "$C"
git -C "$C" branch --unset-upstream            # short-circuit must re-set this
CONFIRM=no; ( place_dotfiles "$C" "$REPO" ) > /dev/null 2>&1; rc=$?
if [ "$rc" -eq 0 ] && [ "$(cat "$C/Brewfile")" = brew-upstream ] \
    && [ "$(git -C "$C" rev-parse --abbrev-ref 'main@{u}' 2> /dev/null)" = origin/main ]; then
    ok "already-remerge, clean: short-circuit + main tracks origin"
else
    bad "already-remerge, clean: short-circuit + main tracks origin"
fi

echo
echo "# provision_macos"

# Fakes: a brew that logs its args + bundle env, and a curl that must NOT be
# called when brew is already present. Prepend a shim dir to PATH.
PBIN="$WORK/pbin"; mkdir -p "$PBIN"
export PLOG="$WORK/plog"; : > "$PLOG"
cat > "$PBIN/brew" <<'SH'
#!/bin/sh
printf 'brew %s\n' "$*" >> "$PLOG"
if [ "$1" = bundle ]; then
    printf 'BUNDLE_FILE=%s NO_LOCK=%s\n' "${HOMEBREW_BUNDLE_FILE:-}" "${HOMEBREW_BUNDLE_NO_LOCK:-}" >> "$PLOG"
    exit "${BREW_BUNDLE_RC:-0}"
fi
exit 0
SH
cat > "$PBIN/curl" <<'SH'
#!/bin/sh
printf 'curl %s\n' "$*" >> "$PLOG"
exit 0
SH
chmod +x "$PBIN/brew" "$PBIN/curl"

# Case A: brew already present -> no Homebrew install (no curl), bundle install
# runs with the right env.
PC="$WORK/pc"; mkdir -p "$PC"; printf 'brew-upstream\n' > "$PC/Brewfile"
: > "$PLOG"; BREW_BUNDLE_RC=0 PATH="$PBIN:$PATH" provision_macos "$PC" > /dev/null 2>&1; rc=$?
if [ "$rc" -eq 0 ] \
    && ! grep -q '^curl ' "$PLOG" \
    && grep -q "BUNDLE_FILE=$PC/Brewfile NO_LOCK=1" "$PLOG"; then
    ok "brew present: skips Homebrew install, bundle install has BUNDLE_FILE+NO_LOCK"
else
    bad "brew present: skips Homebrew install, bundle install has BUNDLE_FILE+NO_LOCK"
fi

# Case B: bundle install fails -> provision_macos is non-fatal (returns 0).
: > "$PLOG"; BREW_BUNDLE_RC=1 PATH="$PBIN:$PATH" provision_macos "$PC" > /dev/null 2>&1; rc=$?
if [ "$rc" -eq 0 ]; then
    ok "bundle failure is non-fatal (returns 0)"
else
    bad "bundle failure is non-fatal (returns 0)"
fi

echo
echo "Result: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && echo "ALL PASS"
[ "$FAIL" -eq 0 ]
