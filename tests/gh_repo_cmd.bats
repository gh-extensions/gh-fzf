#!/usr/bin/env bats

# Unit tests for repository command functions in gh_repo_cmd.sh
#
# Requires bats-core: https://github.com/bats-core/bats-core
# Run: bats tests/gh_repo_cmd.bats

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_DIRNAME")" && pwd)"

setup() {
	# Default mock state (overridden per test as needed)
	export _mock_repoPath=""
	export _mock_gh_user="testuser"
	unset GH_FZF_REPO_PATH

	# Mock gh: routes config get by key; logs clone/fork commands to a file
	gh() {
		case "$1 $2 ${3:-}" in
		"config get fzf.repoPath") printf '%s' "$_mock_repoPath" ;;
		"api user "*) printf '%s' "$_mock_gh_user" ;;
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
		declare -f _gh_config_repo_path _gh_repo_clone _gh_repo_fork
	)"
}

# ---------------------------------------------------------------------------
# _gh_repo_clone: without repoPath configured
# ---------------------------------------------------------------------------

@test "_gh_repo_clone: clones into current directory when repoPath is not configured" {
	_gh_repo_clone "owner/repo"

	grep -q "repo clone owner/repo" "$BATS_TEST_TMPDIR/gh.log"
}

@test "_gh_repo_clone: passes no destination argument when repoPath is unset" {
	_gh_repo_clone "owner/repo"

	local logged
	logged=$(cat "$BATS_TEST_TMPDIR/gh.log")
	[[ "$logged" == "repo clone owner/repo" ]]
}

# ---------------------------------------------------------------------------
# _gh_repo_clone: with repoPath configured via gh config
# ---------------------------------------------------------------------------

@test "_gh_repo_clone: clones to <repoPath>/github.com/owner/repo when repoPath is configured" {
	_mock_repoPath="/tmp/projects"
	export _mock_repoPath

	_gh_repo_clone "owner/repo"

	grep -q "repo clone owner/repo /tmp/projects/github.com/owner/repo" "$BATS_TEST_TMPDIR/gh.log"
}

@test "_gh_repo_clone: creates parent directory before cloning" {
	_mock_repoPath="/tmp/projects"
	export _mock_repoPath

	_gh_repo_clone "owner/repo"

	grep -q "mkdir -p /tmp/projects/github.com/owner" "$BATS_TEST_TMPDIR/mkdir.log"
}

@test "_gh_repo_clone: constructs clone path as <repoPath>/github.com/<owner>/<repo>" {
	_mock_repoPath="/opt/code"
	export _mock_repoPath

	_gh_repo_clone "myorg/myrepo"

	grep -q "/opt/code/github.com/myorg/myrepo" "$BATS_TEST_TMPDIR/gh.log"
}

# ---------------------------------------------------------------------------
# _gh_repo_clone: with GH_FZF_REPO_PATH env var
# ---------------------------------------------------------------------------

@test "_gh_repo_clone: GH_FZF_REPO_PATH env var takes precedence over gh config" {
	_mock_repoPath="/tmp/from-config"
	export _mock_repoPath
	export GH_FZF_REPO_PATH="/tmp/from-env"

	_gh_repo_clone "owner/repo"

	grep -q "repo clone owner/repo /tmp/from-env/github.com/owner/repo" "$BATS_TEST_TMPDIR/gh.log"
}

@test "_gh_repo_clone: GH_FZF_REPO_PATH env var alone configures clone destination" {
	export GH_FZF_REPO_PATH="/tmp/envpath"

	_gh_repo_clone "owner/repo"

	grep -q "repo clone owner/repo /tmp/envpath/github.com/owner/repo" "$BATS_TEST_TMPDIR/gh.log"
}

# ---------------------------------------------------------------------------
# _gh_repo_fork: error handling
# ---------------------------------------------------------------------------

@test "_gh_repo_fork: fails when the authenticated GitHub user cannot be detected" {
	_mock_gh_user=""
	export _mock_gh_user

	run _gh_repo_fork "owner/repo"
	[[ "$status" -eq 1 ]]
}

# ---------------------------------------------------------------------------
# _gh_repo_fork: without repoPath configured
# ---------------------------------------------------------------------------

@test "_gh_repo_fork: forks and clones in a single step when repoPath is not configured" {
	_gh_repo_fork "owner/repo"

	grep -q "repo fork owner/repo --clone" "$BATS_TEST_TMPDIR/gh.log"
}

# ---------------------------------------------------------------------------
# _gh_repo_fork: with repoPath configured via gh config
# ---------------------------------------------------------------------------

@test "_gh_repo_fork: forks then clones separately to <repoPath>/github.com/<user>/<repo>" {
	_mock_repoPath="/tmp/projects"
	export _mock_repoPath

	_gh_repo_fork "owner/repo"

	grep -q "repo fork owner/repo --clone=false" "$BATS_TEST_TMPDIR/gh.log"
	grep -q "repo clone testuser/repo /tmp/projects/github.com/testuser/repo" "$BATS_TEST_TMPDIR/gh.log"
}

# ---------------------------------------------------------------------------
# _gh_repo_fork: with GH_FZF_REPO_PATH env var
# ---------------------------------------------------------------------------

@test "_gh_repo_fork: GH_FZF_REPO_PATH env var takes precedence over gh config" {
	_mock_repoPath="/tmp/from-config"
	export _mock_repoPath
	export GH_FZF_REPO_PATH="/tmp/from-env"

	_gh_repo_fork "owner/repo"

	grep -q "repo fork owner/repo --clone=false" "$BATS_TEST_TMPDIR/gh.log"
	grep -q "repo clone testuser/repo /tmp/from-env/github.com/testuser/repo" "$BATS_TEST_TMPDIR/gh.log"
}

@test "_gh_repo_fork: GH_FZF_REPO_PATH env var alone configures fork destination" {
	export GH_FZF_REPO_PATH="/tmp/envpath"

	_gh_repo_fork "owner/repo"

	grep -q "repo fork owner/repo --clone=false" "$BATS_TEST_TMPDIR/gh.log"
	grep -q "repo clone testuser/repo /tmp/envpath/github.com/testuser/repo" "$BATS_TEST_TMPDIR/gh.log"
}
