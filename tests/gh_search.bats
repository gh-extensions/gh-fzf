#!/usr/bin/env bats

# Unit tests for search functionality in gh_search.sh and gh_search_cmd.sh
#
# Requires bats-core: https://github.com/bats-core/bats-core
# Run: bats tests/gh_search.bats

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_DIRNAME")" && pwd)"

setup() {
	# Mock external commands not under test
	gh() { echo ""; }
	gum() { :; }
	fzf() { :; }
	export -f gh gum fzf

	# Source _gh_search_list and _gh_search_*_cmd into test scope.
	# shellcheck disable=SC2155
	eval "$(
		# shellcheck source=../scripts/gh_search.sh
		source "$REPO_ROOT/scripts/gh_search.sh"
		declare -f _gh_search_list
	)"

	# shellcheck disable=SC2155
	eval "$(
		# shellcheck source=../scripts/gh_search_cmd.sh
		source "$REPO_ROOT/scripts/gh_search_cmd.sh"
		declare -p _gh_search_cmd_source_dir
		declare -f _gh_search_repos_cmd _gh_search_issues_cmd _gh_search_prs_cmd
	)"

	# Replace fzf-calling sub-functions with test mocks that record dispatch.
	# These override the real implementations imported above.
	_gh_search_repos_list() { echo "repos_called:$*"; }
	_gh_search_issues_list() { echo "issues_called:$*"; }
	_gh_search_prs_list() { echo "prs_called:$*"; }
	export -f _gh_search_list _gh_search_repos_list _gh_search_issues_list _gh_search_prs_list
}

# ---------------------------------------------------------------------------
# _gh_search_list: help
# ---------------------------------------------------------------------------

@test "prints usage and exits cleanly for --help" {
	run _gh_search_list --help
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"gh-fzf search"* ]]
}

@test "prints usage and exits cleanly for -h" {
	run _gh_search_list -h
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"gh-fzf search"* ]]
}

@test "usage output lists all available search types" {
	run _gh_search_list --help
	[[ "$output" == *"repos"* ]]
	[[ "$output" == *"issues"* ]]
	[[ "$output" == *"prs"* ]]
}

# ---------------------------------------------------------------------------
# _gh_search_list: dispatch to sub-commands
# ---------------------------------------------------------------------------

@test 'routes "repos" to the repository search handler' {
	run _gh_search_list repos
	[[ "$status" -eq 0 ]]
	[[ "$output" == "repos_called:"* ]]
}

@test 'routes "repositories" to the repository search handler' {
	run _gh_search_list repositories
	[[ "$status" -eq 0 ]]
	[[ "$output" == "repos_called:"* ]]
}

@test 'routes "issues" to the issue search handler' {
	run _gh_search_list issues
	[[ "$status" -eq 0 ]]
	[[ "$output" == "issues_called:"* ]]
}

@test 'routes "prs" to the pull request search handler' {
	run _gh_search_list prs
	[[ "$status" -eq 0 ]]
	[[ "$output" == "prs_called:"* ]]
}

@test 'routes "pull-requests" to the pull request search handler' {
	run _gh_search_list pull-requests
	[[ "$status" -eq 0 ]]
	[[ "$output" == "prs_called:"* ]]
}

@test "forwards the initial query to the repository search handler" {
	run _gh_search_list repos "my query"
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"my query"* ]]
}

@test "forwards the initial query to the issue search handler" {
	run _gh_search_list issues "bug fix"
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"bug fix"* ]]
}

@test "forwards the initial query to the pull request search handler" {
	run _gh_search_list prs "feature"
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"feature"* ]]
}

# ---------------------------------------------------------------------------
# _gh_search_list: error cases
# ---------------------------------------------------------------------------

@test "fails with an error when no search type is provided" {
	run _gh_search_list
	[[ "$status" -eq 1 ]]
}

@test "fails with an error for an unrecognised search type" {
	run _gh_search_list unknown-type
	[[ "$status" -eq 1 ]]
}

# ---------------------------------------------------------------------------
# _gh_search_repos_cmd: empty query handling
# ---------------------------------------------------------------------------

@test "repos: returns a typing prompt instead of searching when query is empty" {
	run _gh_search_repos_cmd ""
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"Type to search"* ]]
}

@test "repos: prompt message refers to repositories" {
	run _gh_search_repos_cmd ""
	[[ "$output" == *"repositor"* ]]
}

# ---------------------------------------------------------------------------
# _gh_search_issues_cmd: empty query handling
# ---------------------------------------------------------------------------

@test "issues: returns a typing prompt instead of searching when query is empty" {
	run _gh_search_issues_cmd ""
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"Type to search"* ]]
}

@test "issues: prompt message refers to issues" {
	run _gh_search_issues_cmd ""
	[[ "$output" == *"issues"* ]]
}

# ---------------------------------------------------------------------------
# _gh_search_prs_cmd: empty query handling
# ---------------------------------------------------------------------------

@test "prs: returns a typing prompt instead of searching when query is empty" {
	run _gh_search_prs_cmd ""
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"Type to search"* ]]
}

@test "prs: prompt message refers to pull requests" {
	run _gh_search_prs_cmd ""
	[[ "$output" == *"pull request"* ]]
}
