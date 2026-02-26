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

@test "clones into the current directory when clone_base is not configured" {
	_mock_clone_base=""
	export _mock_clone_base

	_gh_repo_clone "owner/repo"

	grep -q "repo clone owner/repo" "$BATS_TEST_TMPDIR/gh.log"
}

@test "passes no destination argument to gh repo clone when clone_base is unset" {
	_mock_clone_base=""
	export _mock_clone_base

	_gh_repo_clone "owner/repo"

	local logged
	logged=$(cat "$BATS_TEST_TMPDIR/gh.log")
	[[ "$logged" == "repo clone owner/repo" ]]
}

# ---------------------------------------------------------------------------
# _gh_repo_clone: with clone_base configured
# ---------------------------------------------------------------------------

@test "clones to <clone_base>/github.com/owner/repo when clone_base is configured" {
	_mock_clone_base="/tmp/projects"
	export _mock_clone_base

	_gh_repo_clone "owner/repo"

	grep -q "repo clone owner/repo /tmp/projects/github.com/owner/repo" "$BATS_TEST_TMPDIR/gh.log"
}

@test "creates the parent directory before cloning" {
	_mock_clone_base="/tmp/projects"
	export _mock_clone_base

	_gh_repo_clone "owner/repo"

	grep -q "mkdir -p /tmp/projects/github.com/owner" "$BATS_TEST_TMPDIR/mkdir.log"
}

@test "constructs the clone path as <clone_base>/github.com/<owner>/<repo>" {
	_mock_clone_base="/opt/code"
	export _mock_clone_base

	_gh_repo_clone "myorg/myrepo"

	grep -q "/opt/code/github.com/myorg/myrepo" "$BATS_TEST_TMPDIR/gh.log"
}

# ---------------------------------------------------------------------------
# _gh_repo_fork: error handling
# ---------------------------------------------------------------------------

@test "fails when the authenticated GitHub user cannot be detected" {
	_mock_gh_user=""
	export _mock_gh_user

	run _gh_repo_fork "owner/repo"
	[[ "$status" -eq 1 ]]
}

# ---------------------------------------------------------------------------
# _gh_repo_fork: without clone_base configured
# ---------------------------------------------------------------------------

@test "forks and clones in a single step when clone_base is not configured" {
	_mock_clone_base=""
	export _mock_clone_base

	_gh_repo_fork "owner/repo"

	grep -q "repo fork owner/repo --clone" "$BATS_TEST_TMPDIR/gh.log"
}

# ---------------------------------------------------------------------------
# _gh_repo_fork: with clone_base configured
# ---------------------------------------------------------------------------

@test "forks first then clones separately to <clone_base>/github.com/<user>/<repo>" {
	_mock_clone_base="/tmp/projects"
	export _mock_clone_base

	_gh_repo_fork "owner/repo"

	grep -q "repo fork owner/repo --clone=false" "$BATS_TEST_TMPDIR/gh.log"
	grep -q "repo clone testuser/repo /tmp/projects/github.com/testuser/repo" "$BATS_TEST_TMPDIR/gh.log"
}
