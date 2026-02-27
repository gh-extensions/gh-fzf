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
		declare -f _gh_resource _gh_parse_list_args _gh_fzf_options
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
# _gh_resource
# ---------------------------------------------------------------------------

@test "_gh_resource: maps pr to Pull Request" {
	[[ "$(_gh_resource pr)" == "Pull Request" ]]
}

@test "_gh_resource: maps repo to Repository" {
	[[ "$(_gh_resource repo)" == "Repository" ]]
}

@test "_gh_resource: maps issue to Issue" {
	[[ "$(_gh_resource issue)" == "Issue" ]]
}

@test "_gh_resource: maps run to Run" {
	[[ "$(_gh_resource run)" == "Run" ]]
}

@test "_gh_resource: maps search to Search" {
	[[ "$(_gh_resource search)" == "Search" ]]
}

@test "_gh_resource: maps unknown type to GitHub" {
	[[ "$(_gh_resource unknown)" == "GitHub" ]]
}

@test "_gh_resource: maps empty input to GitHub" {
	[[ "$(_gh_resource "")" == "GitHub" ]]
}

# ---------------------------------------------------------------------------
# _gh_parse_list_args
# ---------------------------------------------------------------------------

@test "_gh_parse_list_args: passes through non-controlled flags and values" {
	local -a result=()
	_gh_parse_list_args result --state open --author @me

	[[ ${#result[@]} -eq 4 ]]
	[[ "${result[0]}" == "--state" ]]
	[[ "${result[1]}" == "open" ]]
	[[ "${result[2]}" == "--author" ]]
	[[ "${result[3]}" == "@me" ]]
}

@test "_gh_parse_list_args: strips --json and its argument" {
	local -a result=()
	_gh_parse_list_args result --state open --json fields

	[[ ${#result[@]} -eq 2 ]]
	[[ "${result[0]}" == "--state" ]]
	[[ "${result[1]}" == "open" ]]
}

@test "_gh_parse_list_args: strips --jq and its argument" {
	local -a result=()
	_gh_parse_list_args result --jq '.[]' --label bug

	[[ ${#result[@]} -eq 2 ]]
	[[ "${result[0]}" == "--label" ]]
	[[ "${result[1]}" == "bug" ]]
}

@test "_gh_parse_list_args: strips --template and its argument" {
	local -a result=()
	_gh_parse_list_args result --template '{{.}}' --limit 50

	[[ ${#result[@]} -eq 2 ]]
	[[ "${result[0]}" == "--limit" ]]
	[[ "${result[1]}" == "50" ]]
}

@test "_gh_parse_list_args: strips -q and its argument" {
	local -a result=()
	_gh_parse_list_args result -q '.[]' --assignee @me

	[[ ${#result[@]} -eq 2 ]]
	[[ "${result[0]}" == "--assignee" ]]
	[[ "${result[1]}" == "@me" ]]
}

@test "_gh_parse_list_args: strips -t and its argument" {
	local -a result=()
	_gh_parse_list_args result -t '{{.}}' --search "bug"

	[[ ${#result[@]} -eq 2 ]]
	[[ "${result[0]}" == "--search" ]]
	[[ "${result[1]}" == "bug" ]]
}

@test "_gh_parse_list_args: strips --json=value form" {
	local -a result=()
	_gh_parse_list_args result --json=fields --state closed

	[[ ${#result[@]} -eq 2 ]]
	[[ "${result[0]}" == "--state" ]]
	[[ "${result[1]}" == "closed" ]]
}

@test "_gh_parse_list_args: strips --jq=value form" {
	local -a result=()
	_gh_parse_list_args result --jq='.[]' --limit 10

	[[ ${#result[@]} -eq 2 ]]
	[[ "${result[0]}" == "--limit" ]]
	[[ "${result[1]}" == "10" ]]
}

@test "_gh_parse_list_args: strips --template=value form" {
	local -a result=()
	_gh_parse_list_args result --template='{{.}}' --limit 10

	[[ ${#result[@]} -eq 2 ]]
	[[ "${result[0]}" == "--limit" ]]
	[[ "${result[1]}" == "10" ]]
}

@test "_gh_parse_list_args: returns empty result when given no arguments" {
	local -a result=()
	_gh_parse_list_args result

	[[ ${#result[@]} -eq 0 ]]
}

@test "_gh_parse_list_args: passes through positional arguments" {
	local -a result=()
	_gh_parse_list_args result octocat --limit 50

	[[ ${#result[@]} -eq 3 ]]
	[[ "${result[0]}" == "octocat" ]]
	[[ "${result[1]}" == "--limit" ]]
	[[ "${result[2]}" == "50" ]]
}

@test "_gh_parse_list_args: strips all controlled flags when multiple present" {
	local -a result=()
	_gh_parse_list_args result --json fields --jq '.[]' --template '{{.}}' --state open

	[[ ${#result[@]} -eq 2 ]]
	[[ "${result[0]}" == "--state" ]]
	[[ "${result[1]}" == "open" ]]
}

@test "_gh_parse_list_args: returns empty result when only controlled flags given" {
	local -a result=()
	_gh_parse_list_args result --json fields

	[[ ${#result[@]} -eq 0 ]]
}

# ---------------------------------------------------------------------------
# _gh_fzf_options
# ---------------------------------------------------------------------------

@test "_gh_fzf_options: includes --ansi in default options" {
	_gh_fzf_options
	[[ "${_fzf_options[*]}" == *"--ansi"* ]]
}

@test "_gh_fzf_options: includes --header-lines in default options" {
	_gh_fzf_options
	[[ "${_fzf_options[*]}" == *"--header-lines"* ]]
}

@test "_gh_fzf_options: returns non-empty options array by default" {
	_gh_fzf_options
	[[ ${#_fzf_options[@]} -gt 0 ]]
}

@test "_gh_fzf_options: appends GH_FZF_FLAGS when set" {
	export GH_FZF_FLAGS="--multi"
	_gh_fzf_options
	[[ "${_fzf_options[*]}" == *"--multi"* ]]
}

@test "_gh_fzf_options: leaves default options unchanged when GH_FZF_FLAGS is empty" {
	export GH_FZF_FLAGS=""
	_gh_fzf_options
	[[ "${_fzf_options[*]}" == *"--ansi"* ]]
}

@test "_gh_fzf_options: appends GH_FZF_PR_OPTS for PR command" {
	export GH_FZF_PR_OPTS="--multi"
	_gh_fzf_options "PR"
	[[ "${_fzf_options[*]}" == *"--multi"* ]]
}

@test "_gh_fzf_options: appends GH_FZF_ISSUE_OPTS for ISSUE command" {
	export GH_FZF_ISSUE_OPTS="--reverse"
	_gh_fzf_options "ISSUE"
	[[ "${_fzf_options[*]}" == *"--reverse"* ]]
}

@test "_gh_fzf_options: appends GH_FZF_RUN_OPTS for RUN command" {
	export GH_FZF_RUN_OPTS="--border"
	_gh_fzf_options "RUN"
	[[ "${_fzf_options[*]}" == *"--border"* ]]
}

@test "_gh_fzf_options: appends GH_FZF_REPO_OPTS for REPO command" {
	export GH_FZF_REPO_OPTS="--height=80%"
	_gh_fzf_options "REPO"
	[[ "${_fzf_options[*]}" == *"--height=80%"* ]]
}

@test "_gh_fzf_options: does not apply per-command opts to a different command" {
	export GH_FZF_PR_OPTS="--multi"
	_gh_fzf_options "ISSUE"
	[[ "${_fzf_options[*]}" != *"--multi"* ]]
}

@test "_gh_fzf_options: skips per-command opts when no command ID given" {
	export GH_FZF_PR_OPTS="--multi"
	_gh_fzf_options
	[[ "${_fzf_options[*]}" != *"--multi"* ]]
}

@test "_gh_fzf_options: appends both GH_FZF_FLAGS and per-command opts" {
	export GH_FZF_FLAGS="--multi"
	export GH_FZF_PR_OPTS="--reverse"
	_gh_fzf_options "PR"
	[[ "${_fzf_options[*]}" == *"--multi"* ]]
	[[ "${_fzf_options[*]}" == *"--reverse"* ]]
}

@test "_gh_fzf_options: preserves quoted bind value with spaces as a single token" {
	export GH_FZF_ISSUE_OPTS="--bind 'alt-I:execute(gh ai issue plan {1} | claude)'"
	_gh_fzf_options "ISSUE"
	local found=0
	for opt in "${_fzf_options[@]}"; do
		[[ "$opt" == "alt-I:execute(gh ai issue plan {1} | claude)" ]] && found=1
	done
	[[ "$found" -eq 1 ]]
}

