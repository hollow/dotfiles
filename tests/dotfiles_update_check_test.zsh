#!/usr/bin/env zsh
set -u

ROOT=${0:A:h:h}
fpath=("${ROOT}/zsh" ${fpath[@]})
autoload -Uz dotfiles-update-check

PASS=0
FAIL=0
WORK=$(mktemp -d)
trap 'rm -rf "${WORK}"' EXIT

export GIT_CONFIG_GLOBAL="${WORK}/gitconfig"
export GIT_CONFIG_NOSYSTEM=1
export GIT_AUTHOR_NAME=t
export GIT_AUTHOR_EMAIL=t@example.test
export GIT_COMMITTER_NAME=t
export GIT_COMMITTER_EMAIL=t@example.test
: > "${GIT_CONFIG_GLOBAL}"

ok() {
	PASS=$((PASS + 1))
	print -r -- "  ok   - $1"
}

bad() {
	FAIL=$((FAIL + 1))
	print -r -- "  FAIL - $1"
}

assert_eq() {
	local name=$1 expected=$2 actual=$3
	if [[ "${actual}" == "${expected}" ]]; then
		ok "${name}"
	else
		bad "${name}: expected <${expected}> got <${actual}>"
	fi
}

assert_ne() {
	local name=$1 unexpected=$2 actual=$3
	if [[ "${actual}" != "${unexpected}" ]]; then
		ok "${name}"
	else
		bad "${name}: expected value other than <${unexpected}>"
	fi
}

assert_empty() {
	local name=$1 actual=$2
	if [[ -z "${actual}" ]]; then
		ok "${name}"
	else
		bad "${name}: expected empty output got <${actual}>"
	fi
}

state_value() {
	local state_dir=$1
	cat "${state_dir}/dotfiles-update-check.state" 2>/dev/null || true
}

run_checker() {
	local command=$1 repo=$2 state_dir=$3
	(
		export DOTFILES_UPDATE_CHECK_REPO="${repo}"
		export DOTFILES_UPDATE_CHECK_STATE_DIR="${state_dir}"
		export DOTFILES_UPDATE_CHECK_INTERVAL=86400
		export DOTFILES_UPDATE_CHECK_SYNC=1
		dotfiles-update-check "${command}"
	)
}

capture_notice() {
	local repo=$1 state_dir=$2
	(
		export DOTFILES_UPDATE_CHECK_REPO="${repo}"
		export DOTFILES_UPDATE_CHECK_STATE_DIR="${state_dir}"
		dotfiles-update-check notice
	)
}

capture_notice_output() {
	local repo=$1 state_dir=$2
	(
		export DOTFILES_UPDATE_CHECK_REPO="${repo}"
		export DOTFILES_UPDATE_CHECK_STATE_DIR="${state_dir}"
		dotfiles-update-check notice
	) 2>&1
}

capture_default_output() {
	local repo=$1 state_dir=$2
	(
		export DOTFILES_UPDATE_CHECK_REPO="${repo}"
		export DOTFILES_UPDATE_CHECK_STATE_DIR="${state_dir}"
		dotfiles-update-check
	) 2>&1
}

capture_mark_with_fake_date() {
	local repo=$1 state_dir=$2 fakebin="${WORK}/fakebin"
	mkdir -p "${fakebin}"
	print -r -- '#!/bin/sh' > "${fakebin}/date"
	print -r -- 'printf "%s\n" 123456789' >> "${fakebin}/date"
	chmod +x "${fakebin}/date"
	(
		export DOTFILES_UPDATE_CHECK_REPO="${repo}"
		export DOTFILES_UPDATE_CHECK_STATE_DIR="${state_dir}"
		PATH="${fakebin}:${PATH}"
		dotfiles-update-check mark-up-to-date
	) 2>&1
}

make_pair() {
	local name=$1
	local origin="${WORK}/${name}-origin"
	local checkout="${WORK}/${name}-checkout"
	git init -q -b main "${origin}"
	print -r -- "base" > "${origin}/tracked.txt"
	git -C "${origin}" add tracked.txt
	git -C "${origin}" commit -qm base
	git clone -q "${origin}" "${checkout}"
	print -r -- "${origin} ${checkout}"
}

add_origin_commit() {
	local origin=$1 text=$2
	print -r -- "${text}" >> "${origin}/tracked.txt"
	git -C "${origin}" add tracked.txt
	git -C "${origin}" commit -qm "${text}"
}

add_checkout_commit() {
	local checkout=$1 text=$2
	print -r -- "${text}" >> "${checkout}/tracked.txt"
	git -C "${checkout}" add tracked.txt
	git -C "${checkout}" commit -qm "${text}"
}

print -r -- "# dotfiles update check states"

read -r origin checkout <<< "$(make_pair equal)"
state_dir="${WORK}/state-equal"
run_checker run "${checkout}" "${state_dir}" >/dev/null
assert_eq "equal checkout records up-to-date" "up-to-date" "$(state_value "${state_dir}")"
assert_empty "equal checkout prints no notice" "$(capture_notice "${checkout}" "${state_dir}")"

read -r origin checkout <<< "$(make_pair behind)"
add_origin_commit "${origin}" upstream
state_dir="${WORK}/state-behind"
run_checker run "${checkout}" "${state_dir}" >/dev/null
assert_eq "behind checkout records behind" "behind" "$(state_value "${state_dir}")"
notice="$(capture_notice "${checkout}" "${state_dir}")"
if [[ "${notice}" == *"󰚰"* && "${notice}" == *"dotfiles update available — run"* && "${notice}" == *"zup"* ]]; then
	ok "behind checkout prints styled notice"
else
	bad "behind checkout prints styled notice: got <${notice}>"
fi

read -r origin checkout <<< "$(make_pair diverged)"
add_origin_commit "${origin}" upstream
add_checkout_commit "${checkout}" local
state_dir="${WORK}/state-diverged"
run_checker run "${checkout}" "${state_dir}" >/dev/null
assert_eq "diverged checkout records error" "error" "$(state_value "${state_dir}")"
assert_empty "diverged checkout prints no notice" "$(capture_notice "${checkout}" "${state_dir}")"

read -r origin checkout <<< "$(make_pair detached)"
git -C "${checkout}" checkout -q --detach HEAD
state_dir="${WORK}/state-detached"
run_checker run "${checkout}" "${state_dir}" >/dev/null
assert_eq "detached checkout records error" "error" "$(state_value "${state_dir}")"
assert_empty "detached checkout prints no notice" "$(capture_notice "${checkout}" "${state_dir}")"

repo="${WORK}/missing-remote"
git init -q -b main "${repo}"
print -r -- "base" > "${repo}/tracked.txt"
git -C "${repo}" add tracked.txt
git -C "${repo}" commit -qm base
state_dir="${WORK}/state-missing-remote"
run_checker run "${repo}" "${state_dir}" >/dev/null
assert_eq "missing remote records error" "error" "$(state_value "${state_dir}")"
assert_empty "missing remote prints no notice" "$(capture_notice "${repo}" "${state_dir}")"

read -r origin checkout <<< "$(make_pair gate)"
add_origin_commit "${origin}" upstream
state_dir="${WORK}/state-gate"
mkdir -p "${state_dir}"
print -r -- "up-to-date" > "${state_dir}/dotfiles-update-check.state"
print -r -- "$(date +%s)" > "${state_dir}/dotfiles-update-check.last"
run_checker start "${checkout}" "${state_dir}" >/dev/null
assert_eq "fresh timestamp skips check" "up-to-date" "$(state_value "${state_dir}")"
print -r -- "0" > "${state_dir}/dotfiles-update-check.last"
run_checker start "${checkout}" "${state_dir}" >/dev/null
assert_eq "stale timestamp runs check" "behind" "$(state_value "${state_dir}")"

state_dir="${WORK}/state-malformed"
mkdir -p "${state_dir}"
print -r -- "not-a-state" > "${state_dir}/dotfiles-update-check.state"
assert_empty "malformed state prints no notice" "$(capture_notice "${checkout}" "${state_dir}")"

state_dir="${WORK}/state-missing"
assert_empty "missing state prints no notice or error" "$(capture_notice_output "${checkout}" "${state_dir}")"
assert_empty "default invocation without state prints no notice or error" "$(capture_default_output "${checkout}" "${state_dir}")"

state_dir="${WORK}/state-mark"
mkdir -p "${state_dir}"
print -r -- "behind" > "${state_dir}/dotfiles-update-check.state"
run_checker mark-up-to-date "${checkout}" "${state_dir}" >/dev/null
assert_eq "mark-up-to-date clears stale behind state" "up-to-date" "$(state_value "${state_dir}")"
assert_empty "mark-up-to-date removes notice" "$(capture_notice "${checkout}" "${state_dir}")"

state_dir="${WORK}/state-epochseconds"
assert_empty "mark-up-to-date with fake date prints no output" "$(capture_mark_with_fake_date "${checkout}" "${state_dir}")"
assert_ne "timestamp uses EPOCHSECONDS instead of date fallback" "123456789" "$(cat "${state_dir}/dotfiles-update-check.last")"

print -r --
print -r -- "PASS: ${PASS}"
print -r -- "FAIL: ${FAIL}"

(( FAIL == 0 ))
