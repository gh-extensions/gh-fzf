#!/usr/bin/env bats

# Unit tests for core utility functions in gh_core.sh
#
# Requires bats-core: https://github.com/bats-core/bats-core
# Run: bats tests/gh_core.bats

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_DIRNAME")" && pwd)"

setup() {
	# Mock external commands not under test
	gh() { echo ""; }
	gum() { :; }
	export -f gh gum

	# Source core functions into test scope using eval + declare pattern.
	# This prevents set -eo pipefail from gh_core.sh leaking into the test runner.
	# shellcheck disable=SC2155
	eval "$(
		# shellcheck source=../scripts/gh_core.sh
		source "$REPO_ROOT/scripts/gh_core.sh"
		declare -f _gh_resource _gh_parse_list_args _gh_fzf_options _gh_ai_enabled
	)"

	# Reset fzf environment to avoid test pollution
	unset GH_FZF_FLAGS
	unset GH_FZF_PR_OPTS
	unset GH_FZF_ISSUE_OPTS
	unset GH_FZF_RUN_OPTS
	unset GH_FZF_REPO_OPTS
	unset GH_FZF_SEARCH_REPO_OPTS
	unset GH_FZF_SEARCH_ISSUE_OPTS
	unset GH_FZF_SEARCH_PR_OPTS
}

# ---------------------------------------------------------------------------
# _gh_resource: resource type name mapping
# ---------------------------------------------------------------------------

@test 'maps "pr" to "Pull Request"' {
	[[ "$(_gh_resource pr)" == "Pull Request" ]]
}

@test 'maps "repo" to "Repository"' {
	[[ "$(_gh_resource repo)" == "Repository" ]]
}

@test 'maps "issue" to "Issue"' {
	[[ "$(_gh_resource issue)" == "Issue" ]]
}

@test 'maps "run" to "Run"' {
	[[ "$(_gh_resource run)" == "Run" ]]
}

@test 'maps "search" to "Search"' {
	[[ "$(_gh_resource search)" == "Search" ]]
}

@test 'maps any unknown type to "GitHub"' {
	[[ "$(_gh_resource unknown)" == "GitHub" ]]
}

@test 'maps empty input to "GitHub"' {
	[[ "$(_gh_resource "")" == "GitHub" ]]
}

# ---------------------------------------------------------------------------
# _gh_parse_list_args: controlled flag filtering
# ---------------------------------------------------------------------------

@test "passes through all uncontrolled flags and their values" {
	local -a result=()
	_gh_parse_list_args result --state open --author @me

	[[ ${#result[@]} -eq 4 ]]
	[[ "${result[0]}" == "--state" ]]
	[[ "${result[1]}" == "open" ]]
	[[ "${result[2]}" == "--author" ]]
	[[ "${result[3]}" == "@me" ]]
}

@test "strips --json flag and its argument" {
	local -a result=()
	_gh_parse_list_args result --state open --json fields

	[[ ${#result[@]} -eq 2 ]]
	[[ "${result[0]}" == "--state" ]]
	[[ "${result[1]}" == "open" ]]
}

@test "strips --jq flag and its argument" {
	local -a result=()
	_gh_parse_list_args result --jq '.[]' --label bug

	[[ ${#result[@]} -eq 2 ]]
	[[ "${result[0]}" == "--label" ]]
	[[ "${result[1]}" == "bug" ]]
}

@test "strips --template flag and its argument" {
	local -a result=()
	_gh_parse_list_args result --template '{{.}}' --limit 50

	[[ ${#result[@]} -eq 2 ]]
	[[ "${result[0]}" == "--limit" ]]
	[[ "${result[1]}" == "50" ]]
}

@test "strips -q flag and its argument" {
	local -a result=()
	_gh_parse_list_args result -q '.[]' --assignee @me

	[[ ${#result[@]} -eq 2 ]]
	[[ "${result[0]}" == "--assignee" ]]
	[[ "${result[1]}" == "@me" ]]
}

@test "strips -t flag and its argument" {
	local -a result=()
	_gh_parse_list_args result -t '{{.}}' --search "bug"

	[[ ${#result[@]} -eq 2 ]]
	[[ "${result[0]}" == "--search" ]]
	[[ "${result[1]}" == "bug" ]]
}

@test "strips inline --json=value form" {
	local -a result=()
	_gh_parse_list_args result --json=fields --state closed

	[[ ${#result[@]} -eq 2 ]]
	[[ "${result[0]}" == "--state" ]]
	[[ "${result[1]}" == "closed" ]]
}

@test "strips inline --jq=value form" {
	local -a result=()
	_gh_parse_list_args result --jq='.[]' --limit 10

	[[ ${#result[@]} -eq 2 ]]
	[[ "${result[0]}" == "--limit" ]]
	[[ "${result[1]}" == "10" ]]
}

@test "strips inline --template=value form" {
	local -a result=()
	_gh_parse_list_args result --template='{{.}}' --limit 10

	[[ ${#result[@]} -eq 2 ]]
	[[ "${result[0]}" == "--limit" ]]
	[[ "${result[1]}" == "10" ]]
}

@test "produces an empty result when given no arguments" {
	local -a result=()
	_gh_parse_list_args result

	[[ ${#result[@]} -eq 0 ]]
}

@test "passes through positional arguments unchanged" {
	local -a result=()
	_gh_parse_list_args result octocat --limit 50

	[[ ${#result[@]} -eq 3 ]]
	[[ "${result[0]}" == "octocat" ]]
	[[ "${result[1]}" == "--limit" ]]
	[[ "${result[2]}" == "50" ]]
}

@test "strips all controlled flags when multiple are present" {
	local -a result=()
	_gh_parse_list_args result --json fields --jq '.[]' --template '{{.}}' --state open

	[[ ${#result[@]} -eq 2 ]]
	[[ "${result[0]}" == "--state" ]]
	[[ "${result[1]}" == "open" ]]
}

@test "produces an empty result when only controlled flags are given" {
	local -a result=()
	_gh_parse_list_args result --json fields

	[[ ${#result[@]} -eq 0 ]]
}

# ---------------------------------------------------------------------------
# _gh_fzf_options: fzf option building
# ---------------------------------------------------------------------------

@test "includes --ansi in the default option set" {
	_gh_fzf_options
	[[ "${_fzf_options[*]}" == *"--ansi"* ]]
}

@test "includes --header-lines in the default option set" {
	_gh_fzf_options
	[[ "${_fzf_options[*]}" == *"--header-lines"* ]]
}

@test "produces a non-empty options array by default" {
	_gh_fzf_options
	[[ ${#_fzf_options[@]} -gt 0 ]]
}

@test "appends GH_FZF_FLAGS to the options array when set" {
	export GH_FZF_FLAGS="--multi"
	_gh_fzf_options
	[[ "${_fzf_options[*]}" == *"--multi"* ]]
}

@test "leaves default options unchanged when GH_FZF_FLAGS is empty" {
	export GH_FZF_FLAGS=""
	_gh_fzf_options
	[[ "${_fzf_options[*]}" == *"--ansi"* ]]
}

@test "appends GH_FZF_PR_OPTS for the PR command" {
	export GH_FZF_PR_OPTS="--multi"
	_gh_fzf_options "PR"
	[[ "${_fzf_options[*]}" == *"--multi"* ]]
}

@test "appends GH_FZF_ISSUE_OPTS for the ISSUE command" {
	export GH_FZF_ISSUE_OPTS="--reverse"
	_gh_fzf_options "ISSUE"
	[[ "${_fzf_options[*]}" == *"--reverse"* ]]
}

@test "appends GH_FZF_RUN_OPTS for the RUN command" {
	export GH_FZF_RUN_OPTS="--border"
	_gh_fzf_options "RUN"
	[[ "${_fzf_options[*]}" == *"--border"* ]]
}

@test "appends GH_FZF_REPO_OPTS for the REPO command" {
	export GH_FZF_REPO_OPTS="--height=80%"
	_gh_fzf_options "REPO"
	[[ "${_fzf_options[*]}" == *"--height=80%"* ]]
}

@test "does not apply per-command opts to a different command" {
	export GH_FZF_PR_OPTS="--multi"
	_gh_fzf_options "ISSUE"
	[[ "${_fzf_options[*]}" != *"--multi"* ]]
}

@test "ignores per-command opts when no command ID is given" {
	export GH_FZF_PR_OPTS="--multi"
	_gh_fzf_options
	[[ "${_fzf_options[*]}" != *"--multi"* ]]
}

@test "merges both GH_FZF_FLAGS and per-command opts" {
	export GH_FZF_FLAGS="--multi"
	export GH_FZF_PR_OPTS="--reverse"
	_gh_fzf_options "PR"
	[[ "${_fzf_options[*]}" == *"--multi"* ]]
	[[ "${_fzf_options[*]}" == *"--reverse"* ]]
}

# ---------------------------------------------------------------------------
# _gh_ai_enabled: gh-ai integration check
# ---------------------------------------------------------------------------

@test 'returns true when gh-fzf.ai config is "enabled"' {
	gh() { echo "enabled"; }
	export -f gh
	_gh_ai_enabled
}

@test 'returns false when gh-fzf.ai config is not "enabled"' {
	gh() { echo "disabled"; }
	export -f gh
	run _gh_ai_enabled
	[[ "$status" -eq 1 ]]
}

@test "returns false when gh-fzf.ai config is unset" {
	gh() { echo ""; }
	export -f gh
	run _gh_ai_enabled
	[[ "$status" -eq 1 ]]
}

@test "returns false when the gh config command fails" {
	gh() { return 1; }
	export -f gh
	run _gh_ai_enabled
	[[ "$status" -eq 1 ]]
}
