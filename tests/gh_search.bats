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

@test "_gh_search_list: prints usage for --help" {
	run _gh_search_list --help
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"gh-fzf search"* ]]
}

@test "_gh_search_list: prints usage for -h" {
	run _gh_search_list -h
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"gh-fzf search"* ]]
}

@test "_gh_search_list: lists all available search types in usage" {
	run _gh_search_list --help
	[[ "$output" == *"repos"* ]]
	[[ "$output" == *"issues"* ]]
	[[ "$output" == *"prs"* ]]
}

# ---------------------------------------------------------------------------
# _gh_search_list: dispatch to sub-commands
# ---------------------------------------------------------------------------

@test "_gh_search_list: dispatches repos to the repository search handler" {
	run _gh_search_list repos
	[[ "$status" -eq 0 ]]
	[[ "$output" == "repos_called:"* ]]
}

@test "_gh_search_list: dispatches repositories to the repository search handler" {
	run _gh_search_list repositories
	[[ "$status" -eq 0 ]]
	[[ "$output" == "repos_called:"* ]]
}

@test "_gh_search_list: dispatches issues to the issue search handler" {
	run _gh_search_list issues
	[[ "$status" -eq 0 ]]
	[[ "$output" == "issues_called:"* ]]
}

@test "_gh_search_list: dispatches prs to the pull request search handler" {
	run _gh_search_list prs
	[[ "$status" -eq 0 ]]
	[[ "$output" == "prs_called:"* ]]
}

@test "_gh_search_list: dispatches pull-requests to the pull request search handler" {
	run _gh_search_list pull-requests
	[[ "$status" -eq 0 ]]
	[[ "$output" == "prs_called:"* ]]
}

@test "_gh_search_list: forwards initial query to the repository search handler" {
	run _gh_search_list repos "my query"
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"my query"* ]]
}

@test "_gh_search_list: forwards initial query to the issue search handler" {
	run _gh_search_list issues "bug fix"
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"bug fix"* ]]
}

@test "_gh_search_list: forwards initial query to the pull request search handler" {
	run _gh_search_list prs "feature"
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"feature"* ]]
}

# ---------------------------------------------------------------------------
# _gh_search_list: error cases
# ---------------------------------------------------------------------------

@test "_gh_search_list: fails when no search type is provided" {
	run _gh_search_list
	[[ "$status" -eq 1 ]]
}

@test "_gh_search_list: fails for an unrecognised search type" {
	run _gh_search_list unknown-type
	[[ "$status" -eq 1 ]]
}

# ---------------------------------------------------------------------------
# _gh_search_repos_cmd: empty query handling
# ---------------------------------------------------------------------------

@test "_gh_search_repos_cmd: returns prompt message when query is empty" {
	run _gh_search_repos_cmd ""
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"Type to search"* ]]
}

@test "_gh_search_repos_cmd: prompt message refers to repositories" {
	run _gh_search_repos_cmd ""
	[[ "$output" == *"repositor"* ]]
}

# ---------------------------------------------------------------------------
# _gh_search_issues_cmd: empty query handling
# ---------------------------------------------------------------------------

@test "_gh_search_issues_cmd: returns prompt message when query is empty" {
	run _gh_search_issues_cmd ""
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"Type to search"* ]]
}

@test "_gh_search_issues_cmd: prompt message refers to issues" {
	run _gh_search_issues_cmd ""
	[[ "$output" == *"issues"* ]]
}

# ---------------------------------------------------------------------------
# _gh_search_prs_cmd: empty query handling
# ---------------------------------------------------------------------------

@test "_gh_search_prs_cmd: returns prompt message when query is empty" {
	run _gh_search_prs_cmd ""
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"Type to search"* ]]
}

@test "_gh_search_prs_cmd: prompt message refers to pull requests" {
	run _gh_search_prs_cmd ""
	[[ "$output" == *"pull request"* ]]
}
