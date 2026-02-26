#!/usr/bin/env bats

# Unit tests for repository command functions in gh_repo_cmd.sh
#
# Requires bats-core: https://github.com/bats-core/bats-core
# Run: bats tests/gh_repo_cmd.bats

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_DIRNAME")" && pwd)"

setup() {
	# Default mock state (overridden per test as needed)
	export _mock_clone_base=""
	export _mock_gh_user="testuser"

	# Mock gh: returns config values or logs clone/fork commands to a file
	gh() {
		case "$1 $2" in
		"config get") printf '%s' "$_mock_clone_base" ;;
		"api user") printf '%s' "$_mock_gh_user" ;;
		*) echo "$@" >>"$BATS_TEST_TMPDIR/gh.log" ;;
		esac
	}
	export -f gh

	# Mock gum: for 'gum spin ... -- cmd args', execute the command after --
	# For 'gum log ...', do nothing
	gum() {
		while [[ $# -gt 0 && "$1" != "--" ]]; do shift; done
		[[ "$1" == "--" ]] && { shift; "$@"; }
		return 0
	}
	export -f gum

	# Mock mkdir to log calls without touching the filesystem
	mkdir() { echo "mkdir $*" >>"$BATS_TEST_TMPDIR/mkdir.log"; }
	export -f mkdir

	# Source repo command functions into test scope
	# shellcheck disable=SC2155
	eval "$(
		# shellcheck source=../scripts/gh_repo_cmd.sh
		source "$REPO_ROOT/scripts/gh_repo_cmd.sh"
		declare -f _gh_repo_clone _gh_repo_fork
	)"
}

# ---------------------------------------------------------------------------
# _gh_repo_clone: without clone_base configured
# ---------------------------------------------------------------------------

@test "_gh_repo_clone: without clone_base calls gh repo clone without target dir" {
	_mock_clone_base=""
	export _mock_clone_base

	_gh_repo_clone "owner/repo"

	grep -q "repo clone owner/repo" "$BATS_TEST_TMPDIR/gh.log"
}

@test "_gh_repo_clone: without clone_base does not pass a destination path" {
	_mock_clone_base=""
	export _mock_clone_base

	_gh_repo_clone "owner/repo"

	# The log line should be exactly "repo clone owner/repo" with no extra path arg
	local logged
	logged=$(cat "$BATS_TEST_TMPDIR/gh.log")
	[[ "$logged" == "repo clone owner/repo" ]]
}

# ---------------------------------------------------------------------------
# _gh_repo_clone: with clone_base configured
# ---------------------------------------------------------------------------

@test "_gh_repo_clone: with clone_base calls gh repo clone with constructed path" {
	_mock_clone_base="/tmp/projects"
	export _mock_clone_base

	_gh_repo_clone "owner/repo"

	grep -q "repo clone owner/repo /tmp/projects/github.com/owner/repo" "$BATS_TEST_TMPDIR/gh.log"
}

@test "_gh_repo_clone: with clone_base creates parent directory" {
	_mock_clone_base="/tmp/projects"
	export _mock_clone_base

	_gh_repo_clone "owner/repo"

	grep -q "mkdir -p /tmp/projects/github.com/owner" "$BATS_TEST_TMPDIR/mkdir.log"
}

@test "_gh_repo_clone: clone_base path includes github.com owner and repo name" {
	_mock_clone_base="/opt/code"
	export _mock_clone_base

	_gh_repo_clone "myorg/myrepo"

	grep -q "/opt/code/github.com/myorg/myrepo" "$BATS_TEST_TMPDIR/gh.log"
}

# ---------------------------------------------------------------------------
# _gh_repo_fork: error handling
# ---------------------------------------------------------------------------

@test "_gh_repo_fork: returns 1 when gh api user returns empty owner" {
	_mock_gh_user=""
	export _mock_gh_user

	run _gh_repo_fork "owner/repo"
	[[ "$status" -eq 1 ]]
}

# ---------------------------------------------------------------------------
# _gh_repo_fork: without clone_base configured
# ---------------------------------------------------------------------------

@test "_gh_repo_fork: without clone_base uses gh repo fork --clone" {
	_mock_clone_base=""
	export _mock_clone_base

	_gh_repo_fork "owner/repo"

	grep -q "repo fork owner/repo --clone" "$BATS_TEST_TMPDIR/gh.log"
}

# ---------------------------------------------------------------------------
# _gh_repo_fork: with clone_base configured
# ---------------------------------------------------------------------------

@test "_gh_repo_fork: with clone_base forks without cloning then clones to path" {
	_mock_clone_base="/tmp/projects"
	export _mock_clone_base

	_gh_repo_fork "owner/repo"

	# Should fork without clone first
	grep -q "repo fork owner/repo --clone=false" "$BATS_TEST_TMPDIR/gh.log"
	# Then clone to the constructed path
	grep -q "repo clone testuser/repo /tmp/projects/github.com/testuser/repo" "$BATS_TEST_TMPDIR/gh.log"
}
