#!/usr/bin/env bash

# Icon used in tmux popup titles
_fzf_icon=" "
# Separator used in fzf display templates
_fzf_split="·"
# Default fzf options for gh-fzf
_fzf_options=(
	--ansi
	--border='none'
	--header-lines='1'
	--header-border='sharp'
	--footer-border='sharp'
	--input-border='sharp'
	--color='header:blue'
	--color='footer:blue'
	--layout='reverse-list'
)

# _gh_get_repo: Get the current repository in owner/repo format.
#
# Returns the repository name in owner/repo format (e.g., gh-extensions/gh-fzf)
# by querying the GitHub CLI. Returns an empty string if not in a repository
# or if the command fails.
#
# Returns:
#   The repository name in owner/repo format, or empty string on error.
#
# Example:
#   repo=$(_gh_get_repo)
#   # Returns: "gh-extensions/gh-fzf"
_gh_get_repo() {
	gh repo view --json nameWithOwner --template "{{.nameWithOwner}}" 2>/dev/null || echo ""
}

# _gh: A wrapper function for the `gh` CLI tool.
#
# This function conditionally calls the `gh` command-line tool, either directly
# or within a `tmux popup` window, depending on the `TMUX` environment variable.
#
# Arguments:
#   $@: All arguments are passed directly to the `gh` command.
#
# Behavior:
#   - If `TMUX` is set, it opens a `tmux popup` with the `gh` command output.
#     The popup title includes the GitHub resource type (e.g., "Pull Request").
#   - If `TMUX` is not set, it executes `gh` directly in the current shell.
_gh() {
	if [[ -z "$TMUX" ]]; then
		gh "$@"
	else
		local resource
		resource=$(_gh_resource "$1")
		tmux popup -T " $_fzf_icon GitHub $resource $3 " -S "fg=blue" -w 80% -h 80% -d "$PWD" gh "$@"
	fi
}

# _gh_resource: Maps a short resource type to its full descriptive name.
#
# This function takes an abbreviated GitHub resource type (e.g., 'pr', 'repo')
# and echoes its corresponding full name (e.g., 'Pull Request', 'Repository').
# It is used primarily for display purposes, such as in tmux popup titles.
#
# Arguments:
#   $1: The abbreviated resource type (e.g., "pr", "repo", "issue", "run").
#
# Returns:
#   The full descriptive name of the resource type.
_gh_resource() {
	local resource_type="$1"

	case "$resource_type" in
	pr)
		echo "Pull Request"
		;;
	repo)
		echo "Repository"
		;;
	issue)
		echo "Issue"
		;;
	run)
		echo "Run"
		;;
	esac

}

# _gh_filter_list_args()
#
# Filter arguments to remove flags that gh-fzf controls internally
#
# DESCRIPTION:
#   Filters out flags that conflict with gh-fzf's internal usage (--json,
#   --template) while passing through all other flags to the gh CLI command.
#   This allows users to pass additional filtering flags like --search,
#   --state, --author, --label, etc. while preventing conflicts.
#
# PARAMETERS:
#   $@ - Arguments to filter
#
# RETURNS:
#   0 - Always returns success
#
# OUTPUT:
#   Space-separated string of filtered arguments
#
# FILTERED FLAGS:
#   --json, --jq, -q    - gh-fzf controls JSON output format
#   --template, -t      - gh-fzf controls output template
#
# EXAMPLE:
#   filtered=$(_gh_filter_list_args --state closed --json custom)
#   # Returns: "--state closed" (--json filtered out)
#
_gh_filter_list_args() {
	local filtered=""
	local skip_next=false

	for arg in "$@"; do
		if [ "$skip_next" = true ]; then
			skip_next=false
			continue
		fi

		case "$arg" in
		--json | --jq | --template)
			skip_next=true
			;;
		-q | -t)
			skip_next=true
			;;
		--json=* | --jq=* | --template=*)
			# Skip flags with = syntax
			;;
		*)
			if [ -n "$filtered" ]; then
				filtered="$filtered $arg"
			else
				filtered="$arg"
			fi
			;;
		esac
	done

	echo "$filtered"
}

# ------------------------------------------------------------------------------
# Direct Execution Support
# ------------------------------------------------------------------------------
# When run directly (not sourced), pass all arguments to hsdk-env.
# This enables tmux integration and scripted usage.
# ------------------------------------------------------------------------------
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	_gh "$@"
fi
