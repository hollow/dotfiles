# Dotfiles Update Check Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers-extended-cc:subagent-driven-development (recommended) or superpowers-extended-cc:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a daily, shell-only background check that notices when the dotfiles checkout is behind `origin/main` and tells the user to run `zup`.

**Architecture:** Put the check logic in one autoloaded zsh helper, then wire `.zshrc` to show cached notices, start the daily detached check, and clear stale state after `zup` updates the repo. The worker only fetches and compares refs; it never mutates the checkout.

**Tech Stack:** zsh autoload functions, git CLI, XDG state files, shell tests using temporary git repositories.

**User decisions (already made):**
- User chose “Notify only”: background checks must not mutate the repo; `zup` remains the update command.
- User chose “Shell prompt only”: no macOS Notification Center or LaunchAgent.
- User chose “Once daily”: shell startup should contact GitHub at most once every 24 hours.
- User approved `docs/superpowers/specs/2026-07-05-dotfiles-update-check-design.md` for implementation planning.

---

## File structure

- Create `zsh/dotfiles-update-check`: one autoloaded zsh helper with subcommands `notice`, `start`, `run`, and `mark-up-to-date`.
- Modify `zsh/.zshrc`: define `ZSH_STATE_DIR`, create it at startup, replace the unconditional dotfiles pull in `zup` with a pull that clears cached update state on success, and call the checker during shell startup.
- Create `tests/dotfiles_update_check_test.zsh`: deterministic zsh tests using temporary local git repositories.
- Modify `README.md`: document the daily notify-only background check in the `zup` sections.

---

### Task 1: Implement zsh update checker

**Goal:** Add the autoloaded checker, wire it into shell startup and `zup`, and cover the safe states with shell tests.

**Files:**
- Create: `zsh/dotfiles-update-check`
- Create: `tests/dotfiles_update_check_test.zsh`
- Modify: `zsh/.zshrc:42-72`
- Modify: `zsh/.zshrc:84-138`

**Acceptance Criteria:**
- [ ] A fresh shell can print `dotfiles update available; run zup` only when cached state is `behind`.
- [ ] Shell startup launches the checker only when the last-attempt timestamp is at least 24 hours old.
- [ ] The background worker writes `behind` only when local `HEAD` is an ancestor of `origin/main`.
- [ ] Equal, diverged, missing-remote, fetch-failure, detached-HEAD, and malformed-state cases do not print a misleading update notice.
- [ ] The worker updates state atomically and redirects async output away from the terminal.
- [ ] Successful `zup` dotfiles pull marks cached state `up-to-date` so stale notices disappear.

**Verify:** `zsh -n zsh/.zshrc && zsh -n zsh/dotfiles-update-check && zsh tests/dotfiles_update_check_test.zsh` → expected final line `FAIL: 0`

**Steps:**

- [ ] **Step 1: Write the failing tests**

Create `tests/dotfiles_update_check_test.zsh` with this complete content:

```zsh
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
assert_eq "behind checkout prints notice" "dotfiles update available; run zup" "$(capture_notice "${checkout}" "${state_dir}")"

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

state_dir="${WORK}/state-mark"
mkdir -p "${state_dir}"
print -r -- "behind" > "${state_dir}/dotfiles-update-check.state"
run_checker mark-up-to-date "${checkout}" "${state_dir}" >/dev/null
assert_eq "mark-up-to-date clears stale behind state" "up-to-date" "$(state_value "${state_dir}")"
assert_empty "mark-up-to-date removes notice" "$(capture_notice "${checkout}" "${state_dir}")"

print -r --
print -r -- "PASS: ${PASS}"
print -r -- "FAIL: ${FAIL}"

(( FAIL == 0 ))
```

- [ ] **Step 2: Run tests to verify they fail before implementation**

Run:

```sh
zsh tests/dotfiles_update_check_test.zsh
```

Expected: non-zero exit. The output should include an autoload failure such as `dotfiles-update-check: function definition file not found`, because `zsh/dotfiles-update-check` does not exist yet.

- [ ] **Step 3: Add the autoloaded checker**

Create `zsh/dotfiles-update-check` with this complete content:

```zsh
#!zsh
emulate -L zsh
[[ ${TRACE:-0} -eq 1 ]] && set -x

local command_name="${1:-notice}"
shift || true

local repo="${DOTFILES_UPDATE_CHECK_REPO:-${XDG_CONFIG_HOME:-${HOME}/.config}}"
local state_dir="${DOTFILES_UPDATE_CHECK_STATE_DIR:-${ZSH_STATE_DIR:-${XDG_STATE_HOME:-${HOME}/.local/state}/zsh}}"
local state_file="${state_dir}/dotfiles-update-check.state"
local last_file="${state_dir}/dotfiles-update-check.last"
local interval="${DOTFILES_UPDATE_CHECK_INTERVAL:-86400}"

_dotfiles_update_check_now() {
	if zmodload -F zsh/datetime b:EPOCHSECONDS 2>/dev/null; then
		print -r -- "${EPOCHSECONDS}"
	else
		date +%s
	fi
}

_dotfiles_update_check_write_file() {
	local file=$1 value=$2 tmp
	mkdir -p "${file:h}" 2>/dev/null || return 1
	tmp="${file}.$$"
	print -r -- "${value}" >| "${tmp}" 2>/dev/null && mv -f "${tmp}" "${file}" 2>/dev/null
}

_dotfiles_update_check_write_state() {
	_dotfiles_update_check_write_file "${state_file}" "$1"
}

case "${command_name}" in
	notice)
		local state
		IFS= read -r state < "${state_file}" 2>/dev/null || return 0
		[[ "${state}" == behind ]] && print -r -- "dotfiles update available; run zup"
		return 0
		;;
	start)
		local now last=0
		now="$(_dotfiles_update_check_now)" || return 0
		[[ "${interval}" == <-> ]] || interval=86400
		if [[ -r "${last_file}" ]]; then
			IFS= read -r last < "${last_file}" 2>/dev/null || last=0
		fi
		[[ "${last}" == <-> ]] || last=0
		(( now - last < interval )) && return 0
		if [[ -n "${DOTFILES_UPDATE_CHECK_SYNC:-}" ]]; then
			dotfiles-update-check run
		else
			( dotfiles-update-check run ) >/dev/null 2>&1 &|
		fi
		return 0
		;;
	run)
		local now branch head upstream
		now="$(_dotfiles_update_check_now)" || now=0
		_dotfiles_update_check_write_file "${last_file}" "${now}" || :
		if ! git -C "${repo}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
			_dotfiles_update_check_write_state error
			return 0
		fi
		branch="$(git -C "${repo}" symbolic-ref --quiet --short HEAD 2>/dev/null)" || {
			_dotfiles_update_check_write_state error
			return 0
		}
		if [[ "${branch}" != main ]]; then
			_dotfiles_update_check_write_state error
			return 0
		fi
		if ! git -C "${repo}" fetch --quiet origin main >/dev/null 2>&1; then
			_dotfiles_update_check_write_state error
			return 0
		fi
		head="$(git -C "${repo}" rev-parse HEAD 2>/dev/null)" || {
			_dotfiles_update_check_write_state error
			return 0
		}
		upstream="$(git -C "${repo}" rev-parse origin/main 2>/dev/null)" || {
			_dotfiles_update_check_write_state error
			return 0
		}
		if [[ "${head}" == "${upstream}" ]]; then
			_dotfiles_update_check_write_state up-to-date
		elif git -C "${repo}" merge-base --is-ancestor "${head}" "${upstream}" >/dev/null 2>&1; then
			_dotfiles_update_check_write_state behind
		else
			_dotfiles_update_check_write_state error
		fi
		return 0
		;;
	mark-up-to-date)
		local now
		now="$(_dotfiles_update_check_now)" || now=0
		_dotfiles_update_check_write_state up-to-date
		_dotfiles_update_check_write_file "${last_file}" "${now}" || :
		return 0
		;;
	*)
		print -u2 -- "usage: dotfiles-update-check [notice|start|run|mark-up-to-date]"
		return 2
		;;
esac
```

- [ ] **Step 4: Wire the state directory into `.zshrc`**

In `zsh/.zshrc`, add `ZSH_STATE_DIR` beside the existing zsh directory variables:

```zsh
ZDOTDIR="${XDG_CONFIG_HOME}/zsh"
ZSH_DATA_DIR="${XDG_DATA_HOME}/zsh"
ZSH_CACHE_DIR="${XDG_CACHE_HOME}/zsh"
ZSH_STATE_DIR="${XDG_STATE_HOME}/zsh"
```

Then add the state directory creation beside the existing base directory creation:

```zsh
mkdirp "${XDG_STATE_HOME}"
mkdirp "${XDG_RUNTIME_DIR}" 0700
mkdirp "${ZSH_DATA_DIR}"
mkdirp "${ZSH_CACHE_DIR}"
mkdirp "${ZSH_CACHE_DIR}/completions"
mkdirp "${ZSH_STATE_DIR}"
```

- [ ] **Step 5: Wire startup notice and background check into `.zshrc`**

After the `zre` and `zx` aliases in `zsh/.zshrc`, insert:

```zsh
dotfiles-update-check notice
dotfiles-update-check start
```

Keep these calls before `zup()` so normal shells show the cached notice immediately and start the detached check before the first prompt.

- [ ] **Step 6: Update `zup` to clear stale notices after a successful dotfiles pull**

Replace the current unconditional pull line in `zup()`:

```zsh
git -C "${XDG_CONFIG_HOME}" pull --ff-only --quiet || :
```

with:

```zsh
if git -C "${XDG_CONFIG_HOME}" pull --ff-only --quiet; then
	dotfiles-update-check mark-up-to-date >/dev/null 2>&1 || :
fi
```

Also update the immediately preceding comment to say:

```zsh
	# Pull the dotfiles first so the rest of zup (Brewfile, plugin list, …)
	# and the final `exec zsh` run against the latest config. Non-fatal:
	# offline or diverged checkouts print git's error and zup carries on.
	# On success, clear any cached background-check notice.
```

- [ ] **Step 7: Run syntax and behavior tests**

Run:

```sh
zsh -n zsh/.zshrc && zsh -n zsh/dotfiles-update-check && zsh tests/dotfiles_update_check_test.zsh
```

Expected: zero exit. The test output must end with:

```text
FAIL: 0
```

- [ ] **Step 8: Commit Task 1**

Run:

```sh
git add zsh/.zshrc zsh/dotfiles-update-check tests/dotfiles_update_check_test.zsh
git commit -m "Add dotfiles update check"
```

---

### Task 2: Document notify-only `zup` update checks

**Goal:** Update README text so users know shells check once daily for dotfiles updates and `zup` performs the actual update.

**Files:**
- Modify: `README.md:61-68`
- Modify: `README.md:126-128`

**Acceptance Criteria:**
- [ ] The first `zup` section says shells check once daily in the background for dotfiles updates.
- [ ] The first `zup` section says the background check is notify-only and tells users to run `zup`.
- [ ] The shell foundation section still describes `zup` as the command that updates Homebrew packages, ZI, and plugins.
- [ ] README does not claim the background checker mutates the checkout or runs package updates.

**Verify:** `grep -n "daily.*dotfiles\|notify-only\|run \\`zup\\`" README.md` → expected matches in the update section

**Steps:**

- [ ] **Step 1: Update the first `zup` README section**

Replace the paragraph after the `zup` command block near `README.md:67` with:

```markdown
This updates your dotfiles checkout, Homebrew packages, the ZI plugin manager,
and all installed plugins in one go. New shells also run a daily background
check for dotfiles updates; that check is notify-only, and prints a shell notice
when an update is available so you can run `zup` yourself.
```

- [ ] **Step 2: Update the shell foundation README section**

Replace the sentence near `README.md:126-128` with:

```markdown
[history](https://zsh.sourceforge.io/Doc/Release/Options.html#History) is kept
large. New shells check daily for dotfiles updates in the background and tell
you to run `zup` when one is available. Run `zup` at any time to update the
dotfiles checkout, Homebrew packages, ZI, and all plugins in one go.
```

- [ ] **Step 3: Verify README wording**

Run:

```sh
grep -n "daily.*dotfiles\|notify-only\|run \`zup\`" README.md
```

Expected: output includes the updated `zup` section and shell foundation section. No output should say the background checker pulls, upgrades, or mutates anything automatically.

- [ ] **Step 4: Re-run behavior tests after docs**

Run:

```sh
zsh -n zsh/.zshrc && zsh -n zsh/dotfiles-update-check && zsh tests/dotfiles_update_check_test.zsh
```

Expected: zero exit and final line `FAIL: 0`.

- [ ] **Step 5: Commit Task 2**

Run:

```sh
git add README.md
git commit -m "Document dotfiles update notices"
```
