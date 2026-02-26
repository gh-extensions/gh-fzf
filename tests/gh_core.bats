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

@test "_gh_resource: pr maps to Pull Request" {
	[[ "$(_gh_resource pr)" == "Pull Request" ]]
}

@test "_gh_resource: repo maps to Repository" {
	[[ "$(_gh_resource repo)" == "Repository" ]]
}

@test "_gh_resource: issue maps to Issue" {
	[[ "$(_gh_resource issue)" == "Issue" ]]
}

@test "_gh_resource: run maps to Run" {
	[[ "$(_gh_resource run)" == "Run" ]]
}

@test "_gh_resource: search maps to Search" {
	[[ "$(_gh_resource search)" == "Search" ]]
}

@test "_gh_resource: unknown type maps to GitHub" {
	[[ "$(_gh_resource unknown)" == "GitHub" ]]
}

@test "_gh_resource: empty string maps to GitHub" {
	[[ "$(_gh_resource "")" == "GitHub" ]]
}

# ---------------------------------------------------------------------------
# _gh_parse_list_args: controlled flag filtering
# ---------------------------------------------------------------------------

@test "_gh_parse_list_args: passes through non-controlled flags" {
	local -a result=()
	_gh_parse_list_args result --state open --author @me

	[[ ${#result[@]} -eq 4 ]]
	[[ "${result[0]}" == "--state" ]]
	[[ "${result[1]}" == "open" ]]
	[[ "${result[2]}" == "--author" ]]
	[[ "${result[3]}" == "@me" ]]
}

@test "_gh_parse_list_args: strips --json and its value" {
	local -a result=()
	_gh_parse_list_args result --state open --json fields

	[[ ${#result[@]} -eq 2 ]]
	[[ "${result[0]}" == "--state" ]]
	[[ "${result[1]}" == "open" ]]
}

@test "_gh_parse_list_args: strips --jq and its value" {
	local -a result=()
	_gh_parse_list_args result --jq '.[]' --label bug

	[[ ${#result[@]} -eq 2 ]]
	[[ "${result[0]}" == "--label" ]]
	[[ "${result[1]}" == "bug" ]]
}

@test "_gh_parse_list_args: strips --template and its value" {
	local -a result=()
	_gh_parse_list_args result --template '{{.}}' --limit 50

	[[ ${#result[@]} -eq 2 ]]
	[[ "${result[0]}" == "--limit" ]]
	[[ "${result[1]}" == "50" ]]
}

@test "_gh_parse_list_args: strips -q and its value" {
	local -a result=()
	_gh_parse_list_args result -q '.[]' --assignee @me

	[[ ${#result[@]} -eq 2 ]]
	[[ "${result[0]}" == "--assignee" ]]
	[[ "${result[1]}" == "@me" ]]
}

@test "_gh_parse_list_args: strips -t and its value" {
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

@test "_gh_parse_list_args: empty input produces empty output" {
	local -a result=()
	_gh_parse_list_args result

	[[ ${#result[@]} -eq 0 ]]
}

@test "_gh_parse_list_args: positional args pass through" {
	local -a result=()
	_gh_parse_list_args result octocat --limit 50

	[[ ${#result[@]} -eq 3 ]]
	[[ "${result[0]}" == "octocat" ]]
	[[ "${result[1]}" == "--limit" ]]
	[[ "${result[2]}" == "50" ]]
}

@test "_gh_parse_list_args: multiple controlled flags are all stripped" {
	local -a result=()
	_gh_parse_list_args result --json fields --jq '.[]' --template '{{.}}' --state open

	[[ ${#result[@]} -eq 2 ]]
	[[ "${result[0]}" == "--state" ]]
	[[ "${result[1]}" == "open" ]]
}

@test "_gh_parse_list_args: controlled flags at end are stripped leaving empty result" {
	local -a result=()
	_gh_parse_list_args result --json fields

	[[ ${#result[@]} -eq 0 ]]
}

# ---------------------------------------------------------------------------
# _gh_fzf_options: fzf option building
# ---------------------------------------------------------------------------

@test "_gh_fzf_options: default options include --ansi" {
	_gh_fzf_options
	[[ "${_fzf_options[*]}" == *"--ansi"* ]]
}

@test "_gh_fzf_options: default options include --header-lines" {
	_gh_fzf_options
	[[ "${_fzf_options[*]}" == *"--header-lines"* ]]
}

@test "_gh_fzf_options: default options array is non-empty" {
	_gh_fzf_options
	[[ ${#_fzf_options[@]} -gt 0 ]]
}

@test "_gh_fzf_options: GH_FZF_FLAGS are appended to options" {
	export GH_FZF_FLAGS="--multi"
	_gh_fzf_options
	[[ "${_fzf_options[*]}" == *"--multi"* ]]
}

@test "_gh_fzf_options: empty GH_FZF_FLAGS does not affect default options" {
	export GH_FZF_FLAGS=""
	_gh_fzf_options
	[[ "${_fzf_options[*]}" == *"--ansi"* ]]
}

@test "_gh_fzf_options: GH_FZF_PR_OPTS appended when command is PR" {
	export GH_FZF_PR_OPTS="--multi"
	_gh_fzf_options "PR"
	[[ "${_fzf_options[*]}" == *"--multi"* ]]
}

@test "_gh_fzf_options: GH_FZF_ISSUE_OPTS appended when command is ISSUE" {
	export GH_FZF_ISSUE_OPTS="--reverse"
	_gh_fzf_options "ISSUE"
	[[ "${_fzf_options[*]}" == *"--reverse"* ]]
}

@test "_gh_fzf_options: GH_FZF_RUN_OPTS appended when command is RUN" {
	export GH_FZF_RUN_OPTS="--border"
	_gh_fzf_options "RUN"
	[[ "${_fzf_options[*]}" == *"--border"* ]]
}

@test "_gh_fzf_options: GH_FZF_REPO_OPTS appended when command is REPO" {
	export GH_FZF_REPO_OPTS="--height=80%"
	_gh_fzf_options "REPO"
	[[ "${_fzf_options[*]}" == *"--height=80%"* ]]
}

@test "_gh_fzf_options: per-command opts not appended for different command" {
	export GH_FZF_PR_OPTS="--multi"
	_gh_fzf_options "ISSUE"
	[[ "${_fzf_options[*]}" != *"--multi"* ]]
}

@test "_gh_fzf_options: no command ID skips per-command opts" {
	export GH_FZF_PR_OPTS="--multi"
	_gh_fzf_options
	[[ "${_fzf_options[*]}" != *"--multi"* ]]
}

@test "_gh_fzf_options: GH_FZF_FLAGS and per-command opts both appended" {
	export GH_FZF_FLAGS="--multi"
	export GH_FZF_PR_OPTS="--reverse"
	_gh_fzf_options "PR"
	[[ "${_fzf_options[*]}" == *"--multi"* ]]
	[[ "${_fzf_options[*]}" == *"--reverse"* ]]
}

# ---------------------------------------------------------------------------
# _gh_ai_enabled: gh-ai integration check
# ---------------------------------------------------------------------------

@test "_gh_ai_enabled: returns 0 when gh-fzf.ai is enabled" {
	gh() { echo "enabled"; }
	export -f gh
	_gh_ai_enabled
}

@test "_gh_ai_enabled: returns 1 when gh-fzf.ai is disabled" {
	gh() { echo "disabled"; }
	export -f gh
	run _gh_ai_enabled
	[[ "$status" -eq 1 ]]
}

@test "_gh_ai_enabled: returns 1 when gh-fzf.ai is not set" {
	gh() { echo ""; }
	export -f gh
	run _gh_ai_enabled
	[[ "$status" -eq 1 ]]
}

@test "_gh_ai_enabled: returns 1 when gh config command fails" {
	gh() { return 1; }
	export -f gh
	run _gh_ai_enabled
	[[ "$status" -eq 1 ]]
}
